-- Las publicaciones identifican la oferta concreta que vio Talento.
alter table public.solicitudes_servicio
  add column tipo_asignacion text check (tipo_asignacion in ('abierta','directa','sin_asignar')),
  add column publicacion_id uuid,
  add column revision_asignacion text,
  add column perfil_enviado_en timestamptz,
  add column proveedor_cancelacion text,
  add column cancelacion_proveedor_en timestamptz,
  add column perfil_pendiente boolean not null default false;

alter table hulp_ofertas.publicaciones
  add column tipo text not null default 'abierta' check (tipo in ('abierta','directa')),
  add column destinatario_id uuid,
  add column excluido_id uuid,
  add column motivo text not null default 'alta',
  add column vence_en timestamptz,
  add column cerrada_en timestamptz;

alter table public.solicitud_estado_eventos
  add column publicacion_id uuid,
  add column detalles jsonb not null default '{}'::jsonb,
  add constraint solicitud_eventos_sprint4 check (accion <> 'vencer_oferta' or publicacion_id is not null);
do $$
declare v_anterior text;
begin
  select pg_get_expr(conbin, conrelid) into strict v_anterior from pg_constraint
  where conrelid='public.solicitud_estado_eventos'::regclass
    and conname='solicitud_estado_eventos_transicion_valida';
  alter table public.solicitud_estado_eventos drop constraint solicitud_estado_eventos_transicion_valida;
  execute 'alter table public.solicitud_estado_eventos add constraint solicitud_estado_eventos_transicion_valida check (('
    || v_anterior || ') or (accion in (''publicar_oferta'',''rechazar_oferta'',''vencer_oferta'',''reabrir_medianoche'')
      and estado_anterior = ''entrantes'' and estado_nuevo = ''entrantes'')
    or (accion in (''cancelar_proveedor'',''reemplazar_proveedor'')
      and estado_anterior in (''entrantes'',''aceptadas'',''iniciadas'',''en camino'',''en proceso'') and estado_nuevo = ''entrantes'')
    or (accion = ''perfil_enviado'' and estado_anterior = estado_nuevo
      and estado_anterior in (''aceptadas'',''iniciadas'',''en camino'',''en proceso'')))';
end $$;
create unique index eventos_un_vencimiento_por_oferta
  on public.solicitud_estado_eventos(publicacion_id) where accion='vencer_oferta';
create unique index eventos_una_aceptacion_por_oferta
  on public.solicitud_estado_eventos(publicacion_id) where accion='aceptar' and publicacion_id is not null;
create index ofertas_vigentes_por_corte on hulp_ofertas.publicaciones(vence_en, solicitud_id)
  where cerrada_en is null;

create function hulp_ofertas.hora_servicio(p_fecha date,p_hora time) returns timestamptz
language sql immutable strict set search_path='' as $$
  select (p_fecha + p_hora) at time zone 'America/Bogota'
$$;

-- Conservar mensajes y separar el acceso de cada asignación.
alter table public.solicitudes_servicio add column asignacion_chat_id uuid not null default gen_random_uuid();
alter table public.mensajes_chat add column asignacion_chat_id uuid;
update public.mensajes_chat m set asignacion_chat_id=s.asignacion_chat_id
from public.chats_solicitud c join public.solicitudes_servicio s on s.id=c.solicitud_id
where m.chat_id=c.id;
create or replace function public.crear_chat_al_asignar_proveedor() returns trigger
language plpgsql set search_path='' as $$
begin
  if new.profesional_id is not null then
    insert into public.chats_solicitud(solicitud_id) values(new.id) on conflict(solicitud_id) do nothing;
  end if;
  return new;
end $$;

create function public.acceso_chat_sprint4(p_id uuid,p_es_chat boolean,p_asignacion uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from public.chats_solicitud c
    join public.solicitudes_servicio s on s.id=c.solicitud_id
    join public.usuarios u on u.id=(select auth.uid())
    where c.id=p_id and (
      u.rol='administrador'
      or (u.id=s.usuario_id and s.tipo_asignacion is distinct from 'sin_asignar')
      or (u.rol='proveedor' and u.id=s.profesional_id
        and s.estado not in ('cancelada','canceladas')
        and (s.estado<>'entrantes' or hulp_ofertas.hora_servicio(s.fecha,s.hora)>statement_timestamp())
        and (p_es_chat or p_asignacion=s.asignacion_chat_id))
    )
  )
$$;
revoke all on function public.acceso_chat_sprint4(uuid,boolean,uuid) from public,anon;
grant execute on function public.acceso_chat_sprint4(uuid,boolean,uuid) to authenticated;
create function hulp_ofertas.etiquetar_mensaje() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if tg_op='INSERT' then
    select s.asignacion_chat_id into new.asignacion_chat_id
    from public.chats_solicitud c join public.solicitudes_servicio s on s.id=c.solicitud_id
    where c.id=new.chat_id;
  else
    new.asignacion_chat_id:=old.asignacion_chat_id;
    if current_setting('role',true)='authenticated'
      and (to_jsonb(new)-'leido') is distinct from (to_jsonb(old)-'leido') then
      raise exception using errcode='42501',message='Solo se puede actualizar el estado de lectura.';
    end if;
  end if;
  return new;
end $$;
create trigger sprint4_etiquetar_chat before insert or update on public.mensajes_chat
for each row execute function hulp_ofertas.etiquetar_mensaje();
drop policy "all" on public.chats_solicitud;
drop policy "all" on public.mensajes_chat;
create policy sprint4_chat_leer on public.chats_solicitud for select to authenticated
  using (public.acceso_chat_sprint4(id,true,null));
create policy sprint4_chat_insertar on public.chats_solicitud for insert to authenticated
  with check (false);
create policy sprint4_mensajes_leer on public.mensajes_chat for select to authenticated
  using (public.acceso_chat_sprint4(chat_id,false,asignacion_chat_id));
create policy sprint4_mensajes_insertar on public.mensajes_chat for insert to authenticated
  with check (remitente_id=(select auth.uid()) and public.acceso_chat_sprint4(chat_id,false,asignacion_chat_id));
create policy sprint4_mensajes_leido on public.mensajes_chat for update to authenticated
  using (public.acceso_chat_sprint4(chat_id,false,asignacion_chat_id))
  with check (public.acceso_chat_sprint4(chat_id,false,asignacion_chat_id));

-- Solo las operaciones de servidor pueden retirar una aceptación vigente.
do $$
declare v text := pg_get_functiondef('public.proteger_estado_solicitud_sprint3()'::regprocedure);
begin
  if strpos(v,'  if new.fecha_aceptacion is distinct from old.fecha_aceptacion then')=0 then
    raise exception 'No se encontró la protección de aceptación esperada';
  end if;
  execute replace(v, '  if new.fecha_aceptacion is distinct from old.fecha_aceptacion then',
    $sql$  if v_backend and current_setting('hulp_sprint4.cambio',true)=old.id::text
      and old.estado in ('entrantes','aceptadas','iniciadas','en camino','en proceso')
      and new.estado='entrantes' and new.fecha_aceptacion is null
      and new.usuario_id=old.usuario_id then
    return new;
  end if;
  if new.fecha_aceptacion is distinct from old.fecha_aceptacion then$sql$);
end $$;

create function hulp_ofertas.nueva_publicacion(
  p_s public.solicitudes_servicio,p_tipo text,p_motivo text,p_excluido uuid default null,
  p_avisar boolean default true,p_creada_en timestamptz default clock_timestamp()
) returns uuid language plpgsql set search_path='' as $$
declare
  v_id uuid:=gen_random_uuid();
  v_corte timestamptz:=hulp_ofertas.hora_servicio(p_s.fecha,p_s.hora);
begin
  if v_corte is null or v_corte<=clock_timestamp() then
    raise exception using errcode='PT409',message='Reprograma el servicio antes de publicar.';
  end if;
  if p_tipo='directa' and p_avisar and not exists (
    select 1 from hulp_ofertas.proveedores_elegibles(p_s.ciudad_id,p_s.servicio_id,p_s.profesional_id)
  ) then
    raise exception using errcode='22023',message='El proveedor no cumple los criterios de asignación.';
  end if;
  insert into hulp_ofertas.publicaciones(id,solicitud_id,tipo,destinatario_id,excluido_id,motivo,vence_en,creada_en)
  values(v_id,p_s.id,p_tipo,p_s.profesional_id,p_excluido,p_motivo,v_corte,p_creada_en);
  if p_avisar then
    insert into hulp_ofertas.avisos(publicacion_id,proveedor_id)
    select v_id,e.proveedor_id
    from hulp_ofertas.proveedores_elegibles(p_s.ciudad_id,p_s.servicio_id,
      case when p_tipo='directa' then p_s.profesional_id end) e
    where e.proveedor_id is distinct from p_excluido;
  end if;
  return v_id;
end $$;

-- Datos anteriores. Vencer sin crear avisos retroactivos.
-- El histórico puede contener importes anteriores al contrato de Finanzas.
-- Este relleno solo cambia columnas nuevas de asignación.
alter table public.solicitudes_servicio disable trigger sprint2_finanzas_proteger;
alter table public.solicitudes_servicio disable trigger sprint2_finanzas_consistencia;
update hulp_ofertas.publicaciones p set vence_en=hulp_ofertas.hora_servicio(s.fecha,s.hora),
  cerrada_en=case when s.estado<>'entrantes' or hulp_ofertas.hora_servicio(s.fecha,s.hora)<=clock_timestamp()
    then clock_timestamp() end
from public.solicitudes_servicio s where s.id=p.solicitud_id;
update public.solicitudes_servicio s
set tipo_asignacion=case when s.profesional_id is null then 'abierta' else 'directa' end,
    publicacion_id=(select p.id from hulp_ofertas.publicaciones p where p.solicitud_id=s.id
      order by p.creada_en desc,p.id desc limit 1),
    revision_asignacion=case when s.estado='entrantes' and
      hulp_ofertas.hora_servicio(s.fecha,s.hora)<=clock_timestamp() then 'Venció sin aceptación' end;
update public.solicitudes_servicio s
set publicacion_id=hulp_ofertas.nueva_publicacion(s,s.tipo_asignacion,'migracion',null,false,
  coalesce(s.creado_en::timestamp at time zone 'UTC',clock_timestamp()))
where s.estado='entrantes' and s.publicacion_id is null
  and hulp_ofertas.hora_servicio(s.fecha,s.hora)>clock_timestamp();
alter table public.solicitudes_servicio enable trigger sprint2_finanzas_proteger;
alter table public.solicitudes_servicio enable trigger sprint2_finanzas_consistencia;

drop trigger sprint4_publicar_solicitud_abierta on public.solicitudes_servicio;
create function hulp_ofertas.preparar_solicitud() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_tipo text;
begin
  if tg_op='INSERT' then
    v_tipo:=nullif(current_setting('hulp_sprint4.tipo_alta',true),'');
    new.tipo_asignacion:=coalesce(v_tipo,case when new.profesional_id is null then 'abierta' else 'directa' end);
  elsif new.profesional_id is distinct from old.profesional_id then
    new.asignacion_chat_id:=gen_random_uuid();
  end if;
  if new.estado='entrantes' and (tg_op='INSERT' or
    current_setting('hulp_sprint4.cambio',true) is distinct from new.id::text and
    (new.profesional_id,new.fecha,new.hora,new.servicio_id,new.ciudad_id)
      is distinct from (old.profesional_id,old.fecha,old.hora,old.servicio_id,old.ciudad_id)) then
    if tg_op='UPDATE' then
      if new.profesional_id is distinct from old.profesional_id then
        raise exception using errcode='PT409',message='Cambia el proveedor desde la operación de asignación.';
      end if;
      update hulp_ofertas.publicaciones set cerrada_en=clock_timestamp() where id=old.publicacion_id and cerrada_en is null;
    end if;
    if (new.tipo_asignacion='directa') is distinct from (new.profesional_id is not null) then
      raise exception using errcode='22023',message='El tipo de asignación no coincide con el proveedor.';
    end if;
    new.revision_asignacion:=case when new.fecha=(clock_timestamp() at time zone 'America/Bogota')::date
      then 'Servicio del día pendiente' end;
    if tg_op='UPDATE' and new.tipo_asignacion<>'sin_asignar' then
      new.publicacion_id:=hulp_ofertas.nueva_publicacion(new,new.tipo_asignacion,
        case when tg_op='INSERT' then 'alta' else 'edicion' end);
    end if;
  end if;
  return new;
end $$;
-- La publicación referencia la solicitud por FK. En el alta se crea después del INSERT.
create function hulp_ofertas.publicar_alta_sprint4() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if new.tipo_asignacion<>'sin_asignar' then
    update public.solicitudes_servicio set
      publicacion_id=hulp_ofertas.nueva_publicacion(new,new.tipo_asignacion,'alta')
    where id=new.id;
  end if;
  return new;
end $$;
-- La inicialización previa al alta solo fija el tipo y el motivo de revisión.
create trigger zz_sprint4_preparar before insert or update on public.solicitudes_servicio
for each row execute function hulp_ofertas.preparar_solicitud();
create trigger sprint4_publicar_alta after insert on public.solicitudes_servicio
for each row when (new.estado='entrantes') execute function hulp_ofertas.publicar_alta_sprint4();

create function public.solicitud_crear_sprint4(
  p_actor uuid,p_datos jsonb,p_finanzas jsonb,p_items jsonb,p_tipo text
) returns jsonb language plpgsql set search_path='' as $$
declare v_previo text:=coalesce(current_setting('hulp_sprint4.tipo_alta',true),''); v_resultado jsonb;
begin
  if p_tipo is not null and (
    p_tipo not in ('abierta','directa','sin_asignar')
    or not exists(select 1 from public.usuarios where id=p_actor and rol='administrador')
  ) then raise exception using errcode='42501',message='Tipo de asignación no permitido.'; end if;
  perform set_config('hulp_sprint4.tipo_alta',coalesce(p_tipo,''),true);
  v_resultado:=public.solicitud_crear_v1(p_actor,p_datos,p_finanzas,p_items);
  perform set_config('hulp_sprint4.tipo_alta',v_previo,true);
  return v_resultado;
end $$;

create function hulp_ofertas.esta_disponible(p_publicacion uuid,p_actor uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from hulp_ofertas.publicaciones p
    join public.solicitudes_servicio s on s.id=p.solicitud_id and s.publicacion_id=p.id
    where p.id=p_publicacion and p_actor is not null and p.cerrada_en is null and p.vence_en>statement_timestamp()
      and s.estado='entrantes' and p.excluido_id is distinct from p_actor
      and (p.tipo='abierta' or p.destinatario_id=p_actor)
      and exists(select 1 from hulp_ofertas.proveedores_elegibles(s.ciudad_id,s.servicio_id,p_actor))
  )
$$;

create function public.puede_leer_solicitud_sprint4(p_solicitud uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.solicitudes_servicio s
    join public.usuarios u on u.id=(select auth.uid())
    where s.id=p_solicitud and (
      u.rol='administrador' or (s.tipo_asignacion is distinct from 'sin_asignar' and (
        u.id=s.usuario_id or (u.rol='proveedor' and (
          (s.estado<>'entrantes' and s.profesional_id=u.id)
          or hulp_ofertas.esta_disponible(s.publicacion_id,u.id)
        ))
      ))
    )
  )
$$;
revoke all on function public.puede_leer_solicitud_sprint4(uuid) from public,anon;
grant execute on function public.puede_leer_solicitud_sprint4(uuid) to authenticated;

create or replace view public.solicitudes_talento_v1 as
select s.* from public.solicitudes_servicio s
where (s.estado<>'entrantes' and s.profesional_id=(select hulp_ofertas.actor_del_proxy()))
  or hulp_ofertas.esta_disponible(s.publicacion_id,(select hulp_ofertas.actor_del_proxy()));
do $$
declare v text:=rtrim(pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass,true),E';\n\r ');
begin
  -- La vista anterior contiene un filtro que dejaría fuera las nuevas ofertas
  -- abiertas autorizadas. Sustituir solamente ese filtro exterior.
  if position('WHERE v.estado_solicitud IS DISTINCT FROM' in v)=0 then
    raise exception 'No se encontró el filtro anterior de solicitudes';
  end if;
  v:=left(v,position('WHERE v.estado_solicitud IS DISTINCT FROM' in v)-1);
  v:=regexp_replace(v,$rx$\s+FROM \($rx$,
    ', meta.tipo_asignacion, meta.publicacion_id, meta.revision_asignacion,
        meta.perfil_enviado_en, meta.perfil_pendiente, meta.proveedor_cancelacion, meta.cancelacion_proveedor_en,
        meta.ciudad_id FROM (');
  execute 'create or replace view public.vw_solicitudes_servicios_completa with (security_barrier=true) as '
    || v || ' JOIN public.solicitudes_servicio meta ON meta.id=v.solicitud_id
              WHERE current_user in (''postgres'',''service_role'') or public.puede_leer_solicitud_sprint4(v.solicitud_id)';
end $$;
create or replace view public.solicitudes_talento_completa_v1 as
select v.*
from public.vw_solicitudes_servicios_completa v join public.solicitudes_talento_v1 s on s.id=v.solicitud_id;

create function hulp_ofertas.registrar(
  p_s public.solicitudes_servicio,p_accion text,p_estado text,p_actor uuid,
  p_idempotencia uuid,p_detalles jsonb default '{}'::jsonb
) returns void language sql set search_path='' as $$
  insert into public.solicitud_estado_eventos
    (solicitud_id,accion,estado_anterior,estado_nuevo,actor_id,ocurrido_en,idempotencia_id,publicacion_id,detalles)
  values(p_s.id,p_accion,p_s.estado,p_estado,p_actor,clock_timestamp(),p_idempotencia,p_s.publicacion_id,p_detalles)
$$;

create function hulp_ofertas.cambiar(
  p_s public.solicitudes_servicio,p_tipo text,p_profesional uuid,p_motivo text,
  p_excluido uuid default null,p_cancelacion text default null
) returns uuid language plpgsql set search_path='' as $$
declare v_id uuid; v_previo text:=coalesce(current_setting('hulp_sprint4.cambio',true),'');
begin
  update hulp_ofertas.publicaciones set cerrada_en=clock_timestamp()
  where id=p_s.publicacion_id and cerrada_en is null;
  p_s.profesional_id:=p_profesional;
  if p_tipo<>'sin_asignar' and p_motivo<>'cancelacion_vencida' then
    v_id:=hulp_ofertas.nueva_publicacion(p_s,p_tipo,p_motivo,p_excluido);
  end if;
  perform set_config('hulp_sprint4.cambio',p_s.id::text,true);
  update public.solicitudes_servicio set tipo_asignacion=p_tipo,publicacion_id=v_id,
    profesional_id=p_profesional,estado='entrantes',fecha_aceptacion=null,perfil_enviado_en=null,
    asignacion_chat_id=gen_random_uuid(),
    perfil_pendiente=perfil_pendiente or p_motivo in ('reemplazo','cancelacion','cancelacion_vencida'),
    revision_asignacion=case
      when p_motivo='medianoche' then 'Servicio del día pendiente'
      when p_cancelacion is not null then 'Canceló el proveedor'
      when fecha=(clock_timestamp() at time zone 'America/Bogota')::date then 'Servicio del día pendiente' end,
    proveedor_cancelacion=coalesce(p_cancelacion,proveedor_cancelacion),
    cancelacion_proveedor_en=case when p_cancelacion is not null then clock_timestamp() else cancelacion_proveedor_en end
  where id=p_s.id;
  perform set_config('hulp_sprint4.cambio',v_previo,true);
  return v_id;
end $$;

create function public.solicitud_asignar_sprint4(
  p_actor uuid,p_id uuid,p_tipo text,p_profesional uuid,p_publicacion uuid
) returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; v_id uuid; v_motivo text;
begin
  if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
    raise exception using errcode='42501',message='Solo Admin puede cambiar la asignación.';
  end if;
  select * into s from public.solicitudes_servicio where id=p_id for update;
  if not found or s.estado not in ('entrantes','aceptadas','iniciadas','en camino','en proceso')
    or s.publicacion_id is distinct from p_publicacion then
    raise exception using errcode='PT409',message='Actualiza la solicitud antes de guardar.';
  end if;
  if p_tipo is null or p_tipo not in ('abierta','directa','sin_asignar')
    or (p_tipo='directa') is distinct from (p_profesional is not null)
    or (s.estado<>'entrantes' and (p_tipo<>'directa' or p_profesional=s.profesional_id)) then
    raise exception using errcode='22023',message='Selecciona un tipo de asignación y un proveedor válidos.';
  end if;
  v_motivo:=case when s.estado<>'entrantes' then 'reemplazo' else 'asignacion_admin' end;
  v_id:=hulp_ofertas.cambiar(s,p_tipo,p_profesional,v_motivo);
  perform hulp_ofertas.registrar(s,case when v_motivo='reemplazo' then 'reemplazar_proveedor' else 'publicar_oferta' end,
    'entrantes',p_actor,gen_random_uuid(),jsonb_build_object('proveedor_anterior',s.profesional_id,
      'proveedor_nuevo',p_profesional,'publicacion_nueva',v_id,'tipo',p_tipo));
  return jsonb_build_object('publicacion_id',v_id,'profesional_anterior',s.profesional_id);
end $$;

create function public.solicitud_perfil_enviado_sprint4(p_actor uuid,p_id uuid,p_publicacion uuid,p_profesional uuid)
returns void language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio;
begin
  if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
    raise exception using errcode='42501',message='Solo Admin puede marcar el perfil.';
  end if;
  select * into s from public.solicitudes_servicio where id=p_id for update;
  if not found or s.estado not in ('aceptadas','iniciadas','en camino','en proceso')
    or s.publicacion_id is distinct from p_publicacion or s.profesional_id is distinct from p_profesional
    or p_profesional is null then
    raise exception using errcode='PT409',message='La asignación cambió. Actualiza la solicitud.';
  end if;
  if s.perfil_enviado_en is null then
    perform hulp_ofertas.registrar(s,'perfil_enviado',s.estado,p_actor,gen_random_uuid());
    update public.solicitudes_servicio set perfil_enviado_en=clock_timestamp(),perfil_pendiente=false where id=s.id;
  end if;
end $$;

-- La versión anterior de la RPC debe pasar por la validación de publicación.
do $$
declare v text:=pg_get_functiondef('public.solicitud_transicion_v1(uuid,uuid,text,uuid)'::regprocedure);
begin
  if strpos(v,'    if p_accion = ''aceptar'' then')=0 then
    raise exception 'No se encontró la operación de aceptación esperada';
  end if;
  v:=replace(v,'    if p_accion = ''aceptar'' then',$sql$
    if p_accion = 'aceptar' then
      if current_setting('hulp_sprint4.aceptar',true) is distinct from p_id::text then
        raise exception using errcode='PT409',message='Actualiza Talento para aceptar esta oferta.';
      end if;$sql$);
  v:=replace(v,'    v_instante := clock_timestamp();',$sql$    v_instante := clock_timestamp();
    if p_accion='aceptar' and hulp_ofertas.hora_servicio(v_solicitud.fecha,v_solicitud.hora)<=v_instante then
      raise exception using errcode='PT409',message='La oferta venció';
    end if;$sql$);
  v:=replace(v,'actor_id, ocurrido_en, idempotencia_id','actor_id, ocurrido_en, idempotencia_id, publicacion_id');
  execute replace(v,'p_actor, v_instante, p_idempotencia_id',
    'p_actor, v_instante, p_idempotencia_id, v_solicitud.publicacion_id');
end $$;

create function public.solicitud_transicion_sprint4(
  p_actor uuid,p_id uuid,p_accion text,p_idempotencia uuid,p_publicacion uuid
) returns jsonb language plpgsql set search_path='' as $$
declare
  s public.solicitudes_servicio;
  p hulp_ofertas.publicaciones;
  e public.solicitud_estado_eventos;
  v_resultado jsonb;
  v_nombre text;
  v_previo text:=coalesce(current_setting('hulp_sprint4.aceptar',true),'');
begin
  if p_accion not in ('aceptar','rechazar','cancelar_proveedor') then
    return public.solicitud_transicion_v1(p_actor,p_id,p_accion,p_idempotencia);
  end if;
  select nullif(trim(concat_ws(' ',nombres,apellidos)),'') into v_nombre
  from public.usuarios where id=p_actor and rol='proveedor';
  if not found or p_idempotencia is null then
    raise exception using errcode='42501',message='La acción requiere un perfil de proveedor.';
  end if;
  select * into s from public.solicitudes_servicio where id=p_id for update;
  if not found then raise exception using errcode='PT404',message='La solicitud no existe.'; end if;
  select * into e from public.solicitud_estado_eventos
  where solicitud_id=p_id and actor_id=p_actor and idempotencia_id=p_idempotencia;
  if found then
    if e.accion<>(case when p_accion='rechazar' then 'rechazar_oferta' else p_accion end)
      or e.publicacion_id is distinct from p_publicacion then
      raise exception using errcode='PT409',message='El identificador corresponde a otra oferta.';
    end if;
    return jsonb_build_object('repetido',true,'estado_actual',s.estado);
  end if;
  if s.publicacion_id is distinct from p_publicacion then
    raise exception using errcode='PT409',message='La oferta cambió. Actualiza Entrantes.';
  end if;
  if p_accion='cancelar_proveedor' then
    if s.profesional_id is distinct from p_actor
      or s.estado not in ('aceptadas','iniciadas','en camino','en proceso') then
      raise exception using errcode='PT409',message='La asignación ya no se puede cancelar.';
    end if;
    v_nombre:=coalesce(v_nombre,'Proveedor');
    perform hulp_ofertas.registrar(s,'cancelar_proveedor','entrantes',p_actor,p_idempotencia,
      jsonb_build_object('nombre',v_nombre));
    perform hulp_ofertas.cambiar(s,'abierta',null,
      case when hulp_ofertas.hora_servicio(s.fecha,s.hora)>clock_timestamp()
        then 'cancelacion' else 'cancelacion_vencida' end,p_actor,v_nombre);
    return jsonb_build_object('repetido',false,'estado_actual','entrantes');
  end if;
  if s.estado<>'entrantes' then
    if p_accion='aceptar' and s.fecha_aceptacion is not null and s.profesional_id<>p_actor then
      raise exception using errcode='PT409',message='Este servicio ya fue tomado';
    end if;
    raise exception using errcode='PT409',message='La solicitud ya no está pendiente.';
  end if;
  if hulp_ofertas.hora_servicio(s.fecha,s.hora)<=clock_timestamp() then
    raise exception using errcode='PT409',message='La oferta venció';
  end if;
  select * into p from hulp_ofertas.publicaciones where id=p_publicacion and solicitud_id=p_id;
  if not found or p.cerrada_en is not null or p.vence_en<=clock_timestamp() then
    raise exception using errcode='PT409',message='La oferta ya no está disponible.';
  end if;
  if p_accion='rechazar' then
    if p.tipo<>'directa' or p.destinatario_id is distinct from p_actor then
      raise exception using errcode='42501',message='Solo el destinatario puede rechazar la oferta directa.';
    end if;
    perform hulp_ofertas.registrar(s,'rechazar_oferta','entrantes',p_actor,p_idempotencia);
    perform hulp_ofertas.cambiar(s,'abierta',null,'rechazo',p_actor);
    return jsonb_build_object('repetido',false,'estado_actual','entrantes');
  end if;
  if not hulp_ofertas.esta_disponible(p_publicacion,p_actor) then
    raise exception using errcode='42501',message='La oferta ya no está disponible para este proveedor.';
  end if;
  perform set_config('hulp_sprint4.aceptar',p_id::text,true);
  v_resultado:=public.solicitud_transicion_v1(p_actor,p_id,'aceptar',p_idempotencia);
  perform set_config('hulp_sprint4.aceptar',v_previo,true);
  update hulp_ofertas.publicaciones set cerrada_en=clock_timestamp() where id=p_publicacion;
  update public.solicitudes_servicio set revision_asignacion=null where id=p_id;
  return v_resultado;
end $$;

create function hulp_ofertas.procesar_vencimientos() returns void
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; p hulp_ofertas.publicaciones; v_hoy date;
begin
  v_hoy:=(clock_timestamp() at time zone 'America/Bogota')::date;
  for s in select ss.* from public.solicitudes_servicio ss
    join hulp_ofertas.publicaciones pp on pp.id=ss.publicacion_id and pp.cerrada_en is null
    where ss.estado='entrantes' and ss.fecha<=v_hoy
      and (pp.vence_en<=clock_timestamp() or
        (ss.revision_asignacion is null or
          (pp.tipo='directa' and pp.creada_en<(ss.fecha::timestamp at time zone 'America/Bogota'))))
    order by pp.vence_en for update of ss skip locked
  loop
    select * into p from hulp_ofertas.publicaciones where id=s.publicacion_id;
    if p.cerrada_en is not null then continue; end if;
    if p.vence_en<=clock_timestamp() then
      perform hulp_ofertas.registrar(s,'vencer_oferta','entrantes',null,gen_random_uuid());
      update hulp_ofertas.publicaciones set cerrada_en=clock_timestamp() where id=p.id;
      update public.solicitudes_servicio set revision_asignacion='Venció sin aceptación' where id=s.id;
    elsif p.tipo='directa' and p.creada_en<(s.fecha::timestamp at time zone 'America/Bogota') then
      perform hulp_ofertas.registrar(s,'reabrir_medianoche','entrantes',null,gen_random_uuid());
      perform hulp_ofertas.cambiar(s,'abierta',null,'medianoche');
    elsif s.revision_asignacion is null then
      update public.solicitudes_servicio set revision_asignacion='Servicio del día pendiente' where id=s.id;
    end if;
  end loop;
end $$;

-- Reusar el envío y su llave de idempotencia para ambas modalidades.
do $$
declare v text:=pg_get_functiondef('hulp_ofertas.procesar_avisos()'::regprocedure);
begin
  v:=regexp_replace(v,$rx$s\.estado is distinct from 'entrantes' or s\.profesional_id is not null$rx$,
    'not hulp_ofertas.esta_disponible(p.id,a.proveedor_id)');
  v:=replace(v,'and s.estado = ''entrantes'' and s.profesional_id is null',
    'and hulp_ofertas.esta_disponible(p.id,a.proveedor_id)');
  execute v;
end $$;

create function public.solicitud_asignacion_detalle_sprint4(p_actor uuid,p_id uuid)
returns jsonb language sql stable set search_path='' as $$
  select jsonb_build_object('tipo_asignacion',s.tipo_asignacion,'publicacion_id',s.publicacion_id,
    'revision_asignacion',s.revision_asignacion,'perfil_enviado_en',s.perfil_enviado_en,
    'perfil_pendiente',s.perfil_pendiente,'proveedor_cancelacion',s.proveedor_cancelacion,
    'cancelacion_proveedor_en',s.cancelacion_proveedor_en)
  from public.solicitudes_servicio s join public.usuarios u on u.id=p_actor and u.rol='administrador'
  where s.id=p_id
$$;

create function public.proveedores_asignacion_sprint4(p_actor uuid,p_ciudad uuid,p_servicio uuid)
returns table(id uuid,nombre text) language sql stable set search_path='' as $$
  select u.id,trim(concat_ws(' ',u.nombres,u.apellidos))
  from hulp_ofertas.proveedores_elegibles(p_ciudad,p_servicio) e
  join public.usuarios u on u.id=e.proveedor_id
  where exists(select 1 from public.usuarios a where a.id=p_actor and a.rol='administrador')
  order by 2
$$;

create function public.solicitud_editar_sprint4(
  p_actor uuid,p_id uuid,p_revision bigint,p_datos jsonb,p_finanzas jsonb,p_items jsonb,
  p_tipo text,p_profesional uuid,p_publicacion uuid
) returns jsonb language plpgsql set search_path='' as $$
declare
  v_res jsonb;
  v_previo text:=coalesce(current_setting('hulp_sprint4.cambio',true),'');
  s public.solicitudes_servicio;
  n public.solicitudes_servicio;
begin
  if p_tipo is null then
    return public.solicitud_editar_v1(p_actor,p_id,p_revision,p_datos,p_finanzas,p_items);
  end if;
  perform set_config('hulp_sprint4.cambio',p_id::text,true);
  if p_revision is null then
    if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
      raise exception using errcode='42501',message='Solo Admin puede editar.';
    end if;
    select * into strict s from public.solicitudes_servicio where id=p_id for update;
    if s.finanzas_version=1 then
      raise exception using errcode='22023',message='Falta la revisión financiera.';
    end if;
    n:=jsonb_populate_record(s,p_datos);
    update public.solicitudes_servicio set fecha=n.fecha,hora=n.hora,servicio_id=n.servicio_id,
      servicio_nombre=n.servicio_nombre,ciudad_id=n.ciudad_id,descripcion=n.descripcion,
      ubicacion=n.ubicacion,direccion_usuario_id=n.direccion_usuario_id,latitud=n.latitud,
      longitud=n.longitud,informacion_adicional=n.informacion_adicional
    where id=p_id;
    v_res:='{}'::jsonb;
  else
    v_res:=public.solicitud_editar_v1(p_actor,p_id,p_revision,p_datos-'profesional_id',p_finanzas,p_items);
  end if;
  perform set_config('hulp_sprint4.cambio',v_previo,true);
  return v_res || public.solicitud_asignar_sprint4(p_actor,p_id,p_tipo,p_profesional,p_publicacion);
end $$;
revoke all on function public.solicitud_editar_sprint4(uuid,uuid,bigint,jsonb,jsonb,jsonb,text,uuid,uuid)
  from public,anon,authenticated;
grant execute on function public.solicitud_editar_sprint4(uuid,uuid,bigint,jsonb,jsonb,jsonb,text,uuid,uuid)
  to service_role;

-- Una sesión de cliente no puede modificar las columnas de control.
create function hulp_ofertas.proteger_columnas() returns trigger
language plpgsql set search_path='' as $$
begin
  if current_user not in ('postgres','service_role') and (
    (new.tipo_asignacion,new.publicacion_id,new.revision_asignacion,new.perfil_enviado_en,
      new.proveedor_cancelacion,new.cancelacion_proveedor_en,new.perfil_pendiente,new.asignacion_chat_id)
    is distinct from
    (old.tipo_asignacion,old.publicacion_id,old.revision_asignacion,old.perfil_enviado_en,
      old.proveedor_cancelacion,old.cancelacion_proveedor_en,old.perfil_pendiente,old.asignacion_chat_id)
    or ((select auth.uid())=old.profesional_id and new.estado<>old.estado
      and new.estado in ('cancelada','canceladas'))
  ) then raise exception using errcode='42501',message='Usa la operación de asignación de Talento.'; end if;
  return new;
end $$;
create trigger sprint4_proteger_columnas before update on public.solicitudes_servicio
for each row execute function hulp_ofertas.proteger_columnas();

revoke all on all functions in schema hulp_ofertas from public,anon,authenticated;
grant execute on function
  hulp_ofertas.hora_servicio(date,time),
  hulp_ofertas.esta_disponible(uuid,uuid),
  hulp_ofertas.nueva_publicacion(public.solicitudes_servicio,text,text,uuid,boolean,timestamptz),
  hulp_ofertas.cambiar(public.solicitudes_servicio,text,uuid,text,uuid,text),
  hulp_ofertas.registrar(public.solicitudes_servicio,text,text,uuid,uuid,jsonb)
to service_role;
grant select, update(cerrada_en),
  insert on hulp_ofertas.publicaciones to service_role;
grant insert on hulp_ofertas.avisos to service_role;

revoke all on function
  public.solicitud_crear_sprint4(uuid,jsonb,jsonb,jsonb,text),
  public.solicitud_asignar_sprint4(uuid,uuid,text,uuid,uuid),
  public.solicitud_perfil_enviado_sprint4(uuid,uuid,uuid,uuid),
  public.solicitud_transicion_sprint4(uuid,uuid,text,uuid,uuid),
  public.solicitud_asignacion_detalle_sprint4(uuid,uuid),
  public.proveedores_asignacion_sprint4(uuid,uuid,uuid)
from public,anon,authenticated;
grant execute on function
  public.solicitud_crear_sprint4(uuid,jsonb,jsonb,jsonb,text),
  public.solicitud_asignar_sprint4(uuid,uuid,text,uuid,uuid),
  public.solicitud_perfil_enviado_sprint4(uuid,uuid,uuid,uuid),
  public.solicitud_transicion_sprint4(uuid,uuid,text,uuid,uuid),
  public.solicitud_asignacion_detalle_sprint4(uuid,uuid),
  public.proveedores_asignacion_sprint4(uuid,uuid,uuid)
to service_role;

select cron.schedule('hulp_sprint4_vencimientos','* * * * *','select hulp_ofertas.procesar_vencimientos()');
notify pgrst,'reload schema';
