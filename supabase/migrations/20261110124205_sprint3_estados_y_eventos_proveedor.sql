-- Sprint 3, puntos 1 al 8. Destino: Hulp/test (ptafsiwlhxomgqmdmidf).
-- Primera fase: instalar tabla, RPC y trigger. El trigger queda desactivado
-- para que las apps actuales sigan funcionando mientras se integra el RPC.
--
-- En el corte, las solicitudes 'aceptadas' sin hora quedan en revisión.
-- La segunda migración habilita el trigger con el backend actualizado.
--
-- La Edge Function debe obtener p_actor de la sesión verificada, usar los RPC
-- para las acciones nuevas y restringir sus PATCH genéricos de avance y horas.
-- La aprobación y la ciudad del proveedor se leen del perfil existente.

begin;
set local lock_timeout = '5s';

create table public.solicitud_estado_eventos (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references public.solicitudes_servicio(id) on delete cascade,
  accion text not null,
  estado_anterior text not null,
  estado_nuevo text not null,
  actor_id uuid references public.usuarios(id) on delete set null,
  ocurrido_en timestamptz not null,
  idempotencia_id uuid not null,
  constraint solicitud_estado_eventos_operacion_unica
    unique (solicitud_id, actor_id, idempotencia_id),
  constraint solicitud_estado_eventos_transicion_valida check (
    (accion = 'aceptar' and estado_anterior = 'entrantes' and estado_nuevo = 'aceptadas')
    or (accion = 'en_camino' and estado_anterior in ('aceptadas', 'iniciadas') and estado_nuevo = 'en camino')
    or (accion = 'empece' and estado_anterior = 'en camino' and estado_nuevo = 'en proceso')
    or (accion = 'termine' and estado_anterior = 'en proceso' and estado_nuevo = 'finalizadas')
  )
);

create index solicitud_estado_eventos_historial_idx
  on public.solicitud_estado_eventos (solicitud_id, ocurrido_en, id);
create index solicitud_estado_eventos_actor_idx
  on public.solicitud_estado_eventos (actor_id);

alter table public.solicitud_estado_eventos enable row level security;
revoke all on table public.solicitud_estado_eventos from public, anon, authenticated, service_role;
grant select, insert on table public.solicitud_estado_eventos to service_role;

-- Solo el backend invoca el RPC. Las comprobaciones y el evento se realizan
-- dentro del bloqueo de la solicitud para serializar intentos de aceptación.
create function public.solicitud_transicion_v1(
  p_actor uuid,
  p_id uuid,
  p_accion text,
  p_idempotencia_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes_servicio%rowtype;
  v_evento public.solicitud_estado_eventos%rowtype;
  v_verificado text;
  v_ciudad_proveedor text;
  v_ciudades_coincidentes bigint;
  v_ciudad_del_servicio boolean;
  v_estado_nuevo text;
  v_instante timestamptz;
  v_repetido boolean;
  v_evento_previo text := coalesce(current_setting('hulp_sprint3.evento_id', true), '');
begin
  if p_actor is null or p_id is null or p_idempotencia_id is null
    or p_accion is null or p_accion not in ('aceptar', 'en_camino', 'empece', 'termine')
  then
    raise exception using errcode = '22023', message = 'Datos de transición inválidos.';
  end if;

  select u.verificado, u.ciudad
    into v_verificado, v_ciudad_proveedor
  from public.usuarios u
  where u.id = p_actor and u.rol = 'proveedor';
  if not found then
    raise exception using errcode = '42501', message = 'La acción requiere un perfil de proveedor.';
  end if;

  select s.* into v_solicitud
  from public.solicitudes_servicio s
  where s.id = p_id
  for update;
  if not found then
    raise exception using errcode = 'PT404', message = 'La solicitud no existe.';
  end if;

  select e.* into v_evento
  from public.solicitud_estado_eventos e
  where e.solicitud_id = p_id and e.actor_id = p_actor
    and e.idempotencia_id = p_idempotencia_id;
  v_repetido := found;

  if v_repetido then
    if v_evento.accion <> p_accion then
      raise exception using errcode = 'PT409',
        message = 'El identificador ya corresponde a otra acción.';
    end if;
  else
    if p_accion = 'aceptar' then
      if v_solicitud.estado <> 'entrantes' then
        raise exception using errcode = 'PT409', message = 'La solicitud ya no está pendiente.';
      end if;
      if v_verificado is distinct from 'verificado'
        or (v_solicitud.profesional_id is not null and v_solicitud.profesional_id <> p_actor)
      then
        raise exception using errcode = '42501', message = 'El proveedor no puede aceptar esta solicitud.';
      end if;
      if v_solicitud.profesional_id is null then
        if not exists (
          select 1 from public.profesional_servicios ps
          where ps.usuario_id = p_actor and ps.servicio_id = v_solicitud.servicio_id
        ) then
          raise exception using errcode = '42501',
            message = 'El proveedor no ofrece el servicio de esta solicitud.';
        end if;
        -- Un perfil sin ciudad inequívoca requiere revisión. La asignación
        -- directa se valida contra el proveedor ya elegido en la solicitud.
        select count(*), bool_or(c.id = v_solicitud.ciudad_id)
          into v_ciudades_coincidentes, v_ciudad_del_servicio
        from public.ciudades c
        where c.activo is true and btrim(v_ciudad_proveedor) <> ''
          and lower(btrim(c.nombre)) = lower(btrim(v_ciudad_proveedor));
        if v_ciudades_coincidentes <> 1 or v_ciudad_del_servicio is distinct from true then
          raise exception using errcode = '42501',
            message = 'La ciudad del proveedor no coincide con una ciudad activa del servicio.';
        end if;
      end if;
      v_estado_nuevo := 'aceptadas';
    else
      if v_solicitud.profesional_id is distinct from p_actor then
        raise exception using errcode = '42501', message = 'La solicitud no está asignada a este proveedor.';
      end if;
      v_estado_nuevo := case
        when p_accion = 'en_camino' and v_solicitud.estado in ('aceptadas', 'iniciadas') then 'en camino'
        when p_accion = 'empece' and v_solicitud.estado = 'en camino' then 'en proceso'
        when p_accion = 'termine' and v_solicitud.estado = 'en proceso' then 'finalizadas'
      end;
      if v_estado_nuevo is null then
        raise exception using errcode = 'PT409', message = 'La acción no corresponde al estado actual.';
      end if;
      if p_accion = 'en_camino' and v_solicitud.estado = 'aceptadas'
        and v_solicitud.fecha_aceptacion is null
      then
        raise exception using errcode = 'PT409',
          message = 'La aceptación anterior requiere revisión del equipo.';
      end if;
    end if;

    v_instante := clock_timestamp();
    if p_accion = 'en_camino'
      and v_solicitud.fecha is distinct from (v_instante at time zone 'America/Bogota')::date
    then
      raise exception using errcode = 'PT409',
        message = 'En camino se puede registrar el día del servicio.';
    end if;

    insert into public.solicitud_estado_eventos (
      solicitud_id, accion, estado_anterior, estado_nuevo,
      actor_id, ocurrido_en, idempotencia_id
    ) values (
      p_id, p_accion, v_solicitud.estado, v_estado_nuevo,
      p_actor, v_instante, p_idempotencia_id
    ) returning * into v_evento;

    perform set_config('hulp_sprint3.evento_id', v_evento.id::text, true);
    update public.solicitudes_servicio s
    set estado = v_estado_nuevo,
        profesional_id = case when p_accion = 'aceptar' then p_actor else s.profesional_id end,
        fecha_aceptacion = case when p_accion = 'aceptar' then v_instante else s.fecha_aceptacion end
    where s.id = p_id
    returning s.* into strict v_solicitud;
    perform set_config('hulp_sprint3.evento_id', v_evento_previo, true);
  end if;

  return jsonb_build_object(
    'solicitud_id', p_id,
    'estado_actual', v_solicitud.estado,
    'profesional_id', v_solicitud.profesional_id,
    'fecha_aceptacion', v_solicitud.fecha_aceptacion,
    'evento', to_jsonb(v_evento),
    'repetido', v_repetido
  );
end;
$$;

-- Cierre manual que Admin ya ofrece. Conserva la distinción entre una acción
-- administrativa y el botón «Terminé» de la proveedora.
create function public.solicitud_finalizar_admin_v1(
  p_actor uuid, p_id uuid, p_profesional_id uuid default null
)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes_servicio%rowtype;
  v_cierre_previo text := coalesce(current_setting('hulp_sprint3.cierre_admin_id', true), '');
begin
  if not exists (
    select 1 from public.usuarios u where u.id = p_actor and u.rol = 'administrador'
  ) then
    raise exception using errcode = '42501', message = 'La acción requiere un perfil de administrador.';
  end if;

  select s.* into v_solicitud from public.solicitudes_servicio s where s.id = p_id for update;
  if not found then
    raise exception using errcode = 'PT404', message = 'La solicitud no existe.';
  end if;
  if v_solicitud.estado = 'finalizadas' then
    return false;
  end if;
  if v_solicitud.estado not in ('entrantes', 'aceptadas', 'iniciadas', 'en camino', 'en proceso') then
    raise exception using errcode = 'PT409', message = 'La solicitud no se puede finalizar en su estado actual.';
  end if;
  if v_solicitud.profesional_id is null and p_profesional_id is not null and not exists (
    select 1 from public.usuarios u where u.id = p_profesional_id and u.rol = 'proveedor'
  ) then
    raise exception using errcode = '22023', message = 'El proveedor seleccionado no es válido.';
  end if;

  perform set_config('hulp_sprint3.cierre_admin_id', p_id::text, true);
  update public.solicitudes_servicio s
  set estado = 'finalizadas',
      profesional_id = coalesce(s.profesional_id, p_profesional_id)
  where s.id = p_id;
  perform set_config('hulp_sprint3.cierre_admin_id', v_cierre_previo, true);
  return true;
end;
$$;

-- Admin y el cliente dueño pueden consultar la línea de tiempo completa.
-- La proveedora asignada puede consultar los eventos que registró.
create function public.solicitud_estado_historial_v1(p_actor uuid, p_id uuid)
returns table (
  id uuid, solicitud_id uuid, accion text, estado_anterior text,
  estado_nuevo text, actor_id uuid, ocurrido_en timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id, e.solicitud_id, e.accion, e.estado_anterior,
    e.estado_nuevo, e.actor_id, e.ocurrido_en
  from public.solicitud_estado_eventos e
  join public.solicitudes_servicio s on s.id = e.solicitud_id
  join public.usuarios u on u.id = p_actor
  where s.id = p_id and (
    u.rol = 'administrador'
    or (u.rol = 'usuario' and s.usuario_id = p_actor)
    or (u.rol = 'proveedor' and s.profesional_id = p_actor and e.actor_id = p_actor)
  )
  order by e.ocurrido_en, e.id;
$$;

revoke execute on function public.solicitud_transicion_v1(uuid, uuid, text, uuid)
  from public, anon, authenticated;
revoke execute on function public.solicitud_finalizar_admin_v1(uuid, uuid, uuid)
  from public, anon, authenticated;
revoke execute on function public.solicitud_estado_historial_v1(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.solicitud_transicion_v1(uuid, uuid, text, uuid) to service_role;
grant execute on function public.solicitud_finalizar_admin_v1(uuid, uuid, uuid) to service_role;
grant execute on function public.solicitud_estado_historial_v1(uuid, uuid) to service_role;

create function public.proteger_estado_solicitud_sprint3()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_backend boolean := current_user in ('postgres', 'service_role');
  v_evento_id uuid;
begin
  if tg_op = 'DELETE' then
    if not v_backend then
      raise exception using errcode = '42501', message = 'Eliminar una solicitud requiere el backend.';
    end if;
    return old;
  end if;

  if tg_op = 'INSERT' then
    -- solicitud_crear_v1 de Finanzas envía «aceptadas» para altas asignadas.
    -- En el corte se registra la asignación como Pendiente, con el mismo proveedor.
    if v_backend and new.finanzas_version = 1 and new.estado = 'aceptadas'
      and new.profesional_id is not null and new.fecha_aceptacion is null
    then
      new.estado := 'entrantes';
    end if;
    if new.estado is distinct from 'entrantes' or new.fecha_aceptacion is not null
      or (not v_backend and new.profesional_id is not null)
    then
      raise exception using errcode = '42501', message = 'Una solicitud nueva debe quedar Pendiente.';
    end if;
    return new;
  end if;

  if not v_backend and (
    new.usuario_id is distinct from old.usuario_id
    or new.fecha is distinct from old.fecha
    or new.ciudad_id is distinct from old.ciudad_id
  ) then
    raise exception using errcode = '42501',
      message = 'El titular, la fecha y la ciudad se editan desde el backend.';
  end if;

  if v_backend then
    v_evento_id := nullif(current_setting('hulp_sprint3.evento_id', true), '')::uuid;
    if v_evento_id is not null and exists (
      select 1 from public.solicitud_estado_eventos e
      where e.id = v_evento_id and e.solicitud_id = old.id
        and e.estado_anterior = old.estado and e.estado_nuevo = new.estado
        and e.actor_id = new.profesional_id
        and new.usuario_id = old.usuario_id
        and new.fecha_aceptacion is not distinct from
          case when e.accion = 'aceptar' then e.ocurrido_en else old.fecha_aceptacion end
    ) then
      return new;
    end if;
  end if;

  if new.fecha_aceptacion is distinct from old.fecha_aceptacion then
    raise exception using errcode = '42501', message = 'La hora de aceptación se guarda al aceptar.';
  end if;

  if v_backend and new.estado = 'finalizadas'
    and current_setting('hulp_sprint3.cierre_admin_id', true) = old.id::text
    and (old.profesional_id is null or new.profesional_id = old.profesional_id)
  then
    return new;
  end if;

  if new.profesional_id is distinct from old.profesional_id then
    -- Asignación de una pendiente y desvinculación por eliminar_mi_cuenta().
    if not (
      (v_backend and old.estado = 'entrantes' and new.estado = 'entrantes')
      or (current_user = 'postgres' and new.profesional_id is null and new.estado = old.estado)
    ) then
      raise exception using errcode = '42501', message = 'La asignación no se puede cambiar en esta operación.';
    end if;
  end if;

  if new.estado is not distinct from old.estado then
    return new;
  end if;
  if new.estado in ('cancelada', 'canceladas', 'reagendada', 'reagendadas')
    and (v_backend or (
      current_user = 'authenticated' and (
        (select auth.uid()) = old.usuario_id
        or (new.estado in ('cancelada', 'canceladas') and (select auth.uid()) = old.profesional_id)
      )
    ))
  then
    return new;
  end if;

  raise exception using errcode = '42501', message = 'El cambio de estado requiere la operación de transición.';
end;
$$;

revoke execute on function public.proteger_estado_solicitud_sprint3()
  from public, anon, authenticated, service_role;

create trigger sprint3_proteger_estado_solicitud
before insert or update or delete on public.solicitudes_servicio
for each row execute function public.proteger_estado_solicitud_sprint3();

alter table public.solicitudes_servicio
  disable trigger sprint3_proteger_estado_solicitud;

notify pgrst, 'reload schema';
commit;
