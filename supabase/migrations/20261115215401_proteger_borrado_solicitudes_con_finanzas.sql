begin;

set local lock_timeout = '5s';

alter table public.chats_solicitud
  drop constraint chats_solicitud_solicitud_id_fkey,
  add constraint chats_solicitud_solicitud_id_fkey
    foreign key (solicitud_id) references public.solicitudes_servicio(id) on delete cascade;

alter table public.mensajes_chat
  drop constraint mensajes_chat_chat_id_fkey,
  add constraint mensajes_chat_chat_id_fkey
    foreign key (chat_id) references public.chats_solicitud(id) on delete cascade;

alter table public.cleanup_programado
  drop constraint cleanup_programado_solicitud_id_fkey,
  add constraint cleanup_programado_solicitud_id_fkey
    foreign key (solicitud_id) references public.solicitudes_servicio(id) on delete cascade;

alter table public.recibos
  drop constraint recibos_mensaje_id_fkey,
  add constraint recibos_mensaje_id_fkey
    foreign key (mensaje_id) references public.mensajes_chat(id) on delete set null;

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
