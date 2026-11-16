begin;

set local lock_timeout = '5s';

alter table public.solicitud_finanzas_historial
  drop constraint solicitud_finanzas_historial_solicitud_id_fkey,
  add constraint solicitud_finanzas_historial_solicitud_id_fkey
    foreign key (solicitud_id) references public.solicitudes_servicio(id) on delete cascade;

alter table public.solicitud_items
  drop constraint solicitud_items_solicitud_id_fkey,
  add constraint solicitud_items_solicitud_id_fkey
    foreign key (solicitud_id) references public.solicitudes_servicio(id) on delete cascade;

CREATE OR REPLACE FUNCTION hulp_finanzas.historial_inmutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if tg_op = 'DELETE' and pg_trigger_depth() > 1 and not exists (
   select 1 from public.solicitudes_servicio where id = old.solicitud_id
 ) then
   return old;
 end if;

 -- SET NULL por eliminación de autor debe seguir funcionando.
 if tg_op='UPDATE' and old.autor_id is not null and new.autor_id is null
  and (to_jsonb(new)-'autor_id')=(to_jsonb(old)-'autor_id') then return new; end if;
 raise exception 'Las revisiones financieras son inmutables';
end $function$;

CREATE OR REPLACE FUNCTION hulp_finanzas.proteger_item()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare id_s uuid;
begin
 if tg_op = 'DELETE' and pg_trigger_depth() > 1 and not exists (
   select 1 from public.solicitudes_servicio where id = old.solicitud_id
 ) then
   return old;
 end if;

 id_s:=case when tg_op='DELETE' then old.solicitud_id else new.solicitud_id end;
 perform 1 from public.solicitudes_servicio where id=id_s and finanzas_version=1 for update;
 if not found then raise exception 'Ítems solo para versión 1'; end if;
 if tg_op='UPDATE' then
  if new.id<>old.id or new.solicitud_id<>old.solicitud_id then raise exception 'Identidad de ítem inmutable'; end if;
  new.creado_en:=old.creado_en; new.actualizado_en:=now();
 end if;
 if tg_op='DELETE' then return old; end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.proteger_estado_solicitud_sprint3()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_backend boolean := current_user in ('postgres', 'service_role');
  v_evento_id uuid;
begin
  if tg_op = 'DELETE' then
    if not v_backend then
      raise exception using errcode = '42501', message = 'Eliminar una solicitud requiere el backend.';
    end if;
    if old.estado = 'finalizadas'
       and coalesce(nullif(lower(btrim(old.estado_pago)), ''), 'pendiente') = 'pendiente' then
      raise exception using errcode = 'PT409',
        message = 'No puedes eliminar la solicitud porque está finalizada y el pago sigue pendiente.';
    end if;
    if exists (
      select 1
      from public.intentos_cobro i
      where i.solicitud_id = old.id and i.resultado = 'pendiente'
    ) then
      raise exception using errcode = 'PT409',
        message = 'No puedes eliminar la solicitud porque tiene un cobro pendiente.';
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
$function$;

commit;
