begin;
set local lock_timeout = '5s';

alter table public.solicitud_estado_eventos
  drop constraint solicitud_estado_eventos_transicion_valida;
alter table public.solicitud_estado_eventos
  add constraint solicitud_estado_eventos_transicion_valida check (
    (accion = 'aceptar' and estado_anterior = 'entrantes' and estado_nuevo = 'aceptadas')
    or (accion = 'en_camino' and estado_anterior in ('aceptadas', 'iniciadas') and estado_nuevo = 'en camino')
    or (accion = 'empece' and estado_anterior = 'en camino' and estado_nuevo = 'en proceso')
    or (accion = 'termine' and estado_anterior = 'en proceso' and estado_nuevo = 'finalizadas')
    or (accion = 'finalizar_admin'
      and estado_anterior in ('entrantes', 'aceptadas', 'iniciadas', 'en camino', 'en proceso')
      and estado_nuevo = 'finalizadas')
  );

create or replace function public.solicitud_finalizar_admin_v1(
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

  insert into public.solicitud_estado_eventos
    (solicitud_id, accion, estado_anterior, estado_nuevo, actor_id, ocurrido_en, idempotencia_id)
  values
    (p_id, 'finalizar_admin', v_solicitud.estado, 'finalizadas', p_actor, clock_timestamp(), gen_random_uuid());

  perform set_config('hulp_sprint3.cierre_admin_id', p_id::text, true);
  update public.solicitudes_servicio s
  set estado = 'finalizadas',
      profesional_id = coalesce(s.profesional_id, p_profesional_id)
  where s.id = p_id;
  perform set_config('hulp_sprint3.cierre_admin_id', v_cierre_previo, true);
  return true;
end;
$$;

commit;
