-- PREPARADO, NO EJECUTADO. Requiere 01 y 02. No activa nuevos INSERT todavía.
begin;
do $hulp_campos$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $hulp_campos$;

-- Contraste de test 2026-11-05: estos triggers existentes no fijan search_path
-- y referencian relaciones sin esquema. Los RPC nuevos usan search_path vacío;
-- fijar el contexto de los triggers sin cambiar sus cuerpos ni sus fórmulas.
alter function public.sync_ticket_seq() set search_path=pg_catalog,public;
alter function public.crear_chat_al_asignar_proveedor() set search_path=pg_catalog,public;
alter function public.programar_cleanup_conversaciones() set search_path=pg_catalog,public;

create function public.solicitud_crear_v1(p_actor uuid,p_datos jsonb,p_finanzas jsonb,
 p_items jsonb default '[]'::jsonb) returns jsonb
language plpgsql set search_path='' as $hulp_campos$
declare s public.solicitudes_servicio; id_nuevo uuid:=gen_random_uuid(); r jsonb; admin boolean;
begin
 if not (select activado from hulp_finanzas.config where singleton) then
  raise exception 'Contrato financiero nuevo todavía no activado';
 end if;
 if jsonb_typeof(p_datos) is distinct from 'object' then raise exception 'Datos requeridos'; end if;
 if exists(select 1 from jsonb_object_keys(p_datos) k where k not in
  ('usuario_id','servicio_id','descripcion','informacion_adicional','notas_cliente','ubicacion',
   'fecha','hora','profesional_id','ciudad_id','latitud','longitud','direccion_usuario_id')) then
  raise exception 'Campo operativo no permitido';
 end if;
 select exists(select 1 from public.usuarios u where u.id=p_actor and u.rol='administrador') into admin;
 s:=jsonb_populate_record(null::public.solicitudes_servicio,p_datos);
 if not admin then
  if s.usuario_id is distinct from p_actor or s.profesional_id is not null
   or s.informacion_adicional is not null or s.descripcion is not null then
   raise exception 'Cliente no autorizado para esos datos' using errcode='42501';
  end if;
 end if;
 if s.fecha<(now() at time zone 'America/Bogota')::date then
  raise exception 'No se puede crear para fecha anterior';
 end if;
 if not exists(select 1 from public.usuarios u where u.id=s.usuario_id and u.rol='usuario') then
  raise exception 'Cliente inválido';
 end if;
 if not exists(select 1 from public.servicios where id=s.servicio_id and estado='activo') then
  raise exception 'Servicio activo requerido';
 end if;
 if not admin then
  s.descripcion:=(select descripcion from public.servicios where id=s.servicio_id);
 end if;
 insert into public.solicitudes_servicio(id,usuario_id,servicio_id,servicio_nombre,
  descripcion,informacion_adicional,notas_cliente,ubicacion,fecha,hora,precio,precio_base,
  precio_adicionales,estado,estado_pago,profesional_id,tipo,ciudad_id,latitud,longitud,
  direccion_usuario_id,finanzas_version,finanzas_revision)
 values(id_nuevo,s.usuario_id,s.servicio_id,(select nombre from public.servicios where id=s.servicio_id),
  s.descripcion,s.informacion_adicional,s.notas_cliente,s.ubicacion,s.fecha,s.hora,
  (p_finanzas->>'precio')::numeric,(p_finanzas->>'precio_base')::numeric,0,
  -- Preservar el comportamiento actual de asignación, no introducir otra
  -- transición operativa en esta entrega financiera.
  case when s.profesional_id is null then 'entrantes' else 'aceptadas' end,
  'pendiente',s.profesional_id,case when admin then 'externo' else 'app' end,
  s.ciudad_id,s.latitud,s.longitud,s.direccion_usuario_id,1,0);
 r:=hulp_finanzas.guardar_v1(id_nuevo,0,p_actor,p_finanzas,p_items,'Creación');
 return r || jsonb_build_object('ticket',(select ticket from public.solicitudes_servicio where id=id_nuevo));
end $hulp_campos$;
revoke all on function public.solicitud_crear_v1(uuid,jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.solicitud_crear_v1(uuid,jsonb,jsonb,jsonb) to service_role;

-- Trigger invoker: el current_user real distingue SQL privilegiado del cliente.
-- No usar una GUC que el usuario pueda establecer como prueba de autorización.
create function hulp_finanzas.proteger_solicitud() returns trigger
language plpgsql set search_path='' as $hulp_campos$
declare trusted boolean:=current_user in ('postgres','service_role'); activo boolean;
begin
 -- SECURITY INVOKER: lectura config solo requerida por INSERT de backend;
 -- clientes directos se rechazan al activar mediante 05.
 if tg_op='INSERT' then
  if trusted then
   if (select activado from hulp_finanzas.config where singleton)
    and new.finanzas_version is distinct from 1 then
    raise exception 'Después de activar, crear únicamente mediante solicitud_crear_v1';
   end if;
  end if;
  if new.finanzas_version is null then return new; end if;
  if not trusted or new.finanzas_version<>1 or new.finanzas_revision<>0 then
   raise exception 'Creación versión 1 solo mediante backend validado' using errcode='42501';
  end if;
  return new;
 end if;
 if new.finanzas_version is distinct from old.finanzas_version then
  raise exception 'La versión financiera de una solicitud existente es inmutable';
 end if;
 if old.finanzas_version is null then
  if (to_jsonb(new)-array['id','usuario_id','servicio_id','servicio_nombre','descripcion',
   'informacion_adicional','ubicacion','fecha','hora','precio','estado','estado_pago',
   'profesional_id','creado_en','fecha_cancelacion','fecha_reagendamiento','fecha_pago',
   'fecha_aceptacion','solicitud_original_id','ticket','precio_base','tipo','precio_adicionales',
   'ciudad_id','latitud','longitud','direccion_usuario_id','notas_cliente'])
    is distinct from
   (to_jsonb(old)-array['id','usuario_id','servicio_id','servicio_nombre','descripcion',
   'informacion_adicional','ubicacion','fecha','hora','precio','estado','estado_pago',
   'profesional_id','creado_en','fecha_cancelacion','fecha_reagendamiento','fecha_pago',
   'fecha_aceptacion','solicitud_original_id','ticket','precio_base','tipo','precio_adicionales',
   'ciudad_id','latitud','longitud','direccion_usuario_id','notas_cliente']) then
   raise exception 'No rellenar resultados financieros nuevos en históricos';
  end if;
  return new;
 end if;
 if old.finanzas_version<>1 then raise exception 'Versión desconocida'; end if;
 if not trusted and row(new.precio,new.precio_base,new.precio_adicionales,new.estado_pago,
  new.motivo_precio_pagado,new.adelanto_proveedor,new.adelanto_concepto,new.adelanto_motivo,
  new.aplica_wompi,new.aplica_ajuste_iva,new.requiere_fe,new.informacion_adicional,new.notas_cliente,
  new.materiales_total,new.pago_proveedor,new.saldo_transferir,new.comision_base,
  new.ajuste_iva_valor,new.comision_hulp_iva,new.comision_neta_hulp,new.iva_valor,
  new.comision_efectiva,new.wompi_valor,new.total_cliente,new.finanzas_revision,new.finanzas_calculadas_en)
  is distinct from row(old.precio,old.precio_base,old.precio_adicionales,old.estado_pago,
  old.motivo_precio_pagado,old.adelanto_proveedor,old.adelanto_concepto,old.adelanto_motivo,
  old.aplica_wompi,old.aplica_ajuste_iva,old.requiere_fe,old.informacion_adicional,old.notas_cliente,
  old.materiales_total,old.pago_proveedor,old.saldo_transferir,old.comision_base,
  old.ajuste_iva_valor,old.comision_hulp_iva,old.comision_neta_hulp,old.iva_valor,
  old.comision_efectiva,old.wompi_valor,old.total_cliente,old.finanzas_revision,old.finanzas_calculadas_en) then
  raise exception 'Finanzas/notas privadas solo mediante backend validado' using errcode='42501';
 end if;
 return new;
end $hulp_campos$;
revoke all on function hulp_finanzas.proteger_solicitud() from public,anon,authenticated;
create trigger sprint2_finanzas_proteger before insert or update on public.solicitudes_servicio
 for each row execute function hulp_finanzas.proteger_solicitud();

-- Validar al COMMIT, después de insertar ítems y recalcular el padre.
-- SQL directo de service_role tampoco puede dejar resultados divergentes.
create function hulp_finanzas.validar_consistencia() returns trigger
language plpgsql security definer set search_path='' as $hulp_campos$
declare s public.solicitudes_servicio; m numeric; r jsonb; id_s uuid;
begin
 if tg_table_name='solicitudes_servicio' then id_s:=new.id;
 elsif tg_op='DELETE' then id_s:=old.solicitud_id;
 else id_s:=new.solicitud_id; end if;
 select * into s from public.solicitudes_servicio where id=id_s;
 if s.id is null then return null; end if;
 if s.finanzas_version is null then
  if tg_table_name='solicitud_items' then raise exception 'Histórico no admite ítems versión 1'; end if;
  return null;
 end if;
 if s.finanzas_version<>1 or s.finanzas_revision is null or s.finanzas_revision<1
 or s.finanzas_calculadas_en is null or s.requiere_fe is null then
  raise exception 'Resultados de versión 1 incompletos';
 end if;
 select coalesce(sum(total),0) into m from public.solicitud_items
 where solicitud_id=id_s and tipo_item='material';
 r:=hulp_finanzas.calcular_v1(s.precio_base,s.precio,m,s.adelanto_proveedor,
  s.aplica_wompi,s.aplica_ajuste_iva);
 if exists(select 1 from jsonb_each(r) e where (to_jsonb(s)->e.key) is distinct from e.value) then
  raise exception 'Resultados financieros inconsistentes con entradas/ítems';
 end if;
 if s.precio<>s.precio_base and nullif(btrim(s.motivo_precio_pagado),'') is null then
  raise exception 'Motivo de precio requerido';
 end if;
 if not exists(select 1 from public.solicitud_finanzas_historial h
  where h.solicitud_id=id_s and h.revision=s.finanzas_revision and h.resultados=r) then
  raise exception 'Revisión financiera sin historial consistente';
 end if;
 return null;
end $hulp_campos$;
revoke all on function hulp_finanzas.validar_consistencia() from public,anon,authenticated,service_role;
create constraint trigger sprint2_finanzas_consistencia after insert or update
 on public.solicitudes_servicio deferrable initially deferred
 for each row execute function hulp_finanzas.validar_consistencia();
create constraint trigger sprint2_items_consistencia after insert or update or delete
 on public.solicitud_items deferrable initially deferred
 for each row execute function hulp_finanzas.validar_consistencia();

-- No mover ítems a otro padre ni borrar/editar el historial por API.
create function hulp_finanzas.proteger_item() returns trigger
language plpgsql set search_path='' as $hulp_campos$
declare id_s uuid;
begin
 id_s:=case when tg_op='DELETE' then old.solicitud_id else new.solicitud_id end;
 perform 1 from public.solicitudes_servicio where id=id_s and finanzas_version=1 for update;
 if not found then raise exception 'Ítems solo para versión 1'; end if;
 if tg_op='UPDATE' then
  if new.id<>old.id or new.solicitud_id<>old.solicitud_id then raise exception 'Identidad de ítem inmutable'; end if;
  new.creado_en:=old.creado_en; new.actualizado_en:=now();
 end if;
 if tg_op='DELETE' then return old; end if;
 return new;
end $hulp_campos$;
revoke all on function hulp_finanzas.proteger_item() from public,anon,authenticated;
grant execute on function hulp_finanzas.proteger_item() to service_role;
create trigger sprint2_item_proteger before insert or update or delete on public.solicitud_items
 for each row execute function hulp_finanzas.proteger_item();

create function hulp_finanzas.historial_inmutable() returns trigger
language plpgsql set search_path='' as $hulp_campos$ begin
 -- SET NULL por eliminación de autor debe seguir funcionando.
 if tg_op='UPDATE' and old.autor_id is not null and new.autor_id is null
  and (to_jsonb(new)-'autor_id')=(to_jsonb(old)-'autor_id') then return new; end if;
 raise exception 'Las revisiones financieras son inmutables';
end $hulp_campos$;
revoke all on function hulp_finanzas.historial_inmutable() from public,anon,authenticated,service_role;
create trigger sprint2_historial_inmutable before update or delete
 on public.solicitud_finanzas_historial for each row
 execute function hulp_finanzas.historial_inmutable();
commit;
