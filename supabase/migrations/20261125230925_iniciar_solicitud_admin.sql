-- Extiende la transición administrativa existente para permitir En curso.
do $$
declare
  v_check text;
  v_trigger text := pg_get_functiondef(
    'public.proteger_estado_solicitud_sprint3()'::regprocedure
  );
  v_proveedor text := $regla$e.accion <> 'activar_admin' and e.actor_id = new.profesional_id$regla$;
  v_admin text := $regla$or (e.accion = 'activar_admin'$regla$;
begin
  select pg_get_expr(conbin, conrelid) into strict v_check
  from pg_constraint
  where conrelid = 'public.solicitud_estado_eventos'::regclass
    and conname = 'solicitud_estado_eventos_transicion_valida';

  if strpos(v_trigger, 'iniciar_admin') > 0 and strpos(v_check, 'iniciar_admin') > 0 then
    return;
  end if;
  if strpos(v_trigger, v_proveedor) = 0 or strpos(v_trigger, v_admin) = 0 then
    raise exception 'La protección no contiene la transición de Admin a Activo.';
  end if;

  alter table public.solicitud_estado_eventos
    drop constraint solicitud_estado_eventos_transicion_valida;
  execute format($check$
    alter table public.solicitud_estado_eventos
    add constraint solicitud_estado_eventos_transicion_valida check (
      (%s) or (accion = 'iniciar_admin'
        and estado_anterior in ('entrantes', 'aceptadas', 'iniciadas', 'en camino')
        and estado_nuevo = 'en proceso')
    )
  $check$, v_check);

  v_trigger := replace(v_trigger, v_proveedor,
    $regla$e.accion not in ('activar_admin', 'iniciar_admin') and e.actor_id = new.profesional_id$regla$);
  execute replace(v_trigger, v_admin,
    $regla$or (e.accion in ('activar_admin', 'iniciar_admin')$regla$);
end;
$$;

create or replace function public.solicitud_iniciar_admin_v1(p_actor uuid, p_id uuid)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_estado text;
  v_evento_id uuid;
  v_evento_previo text := coalesce(current_setting('hulp_sprint3.evento_id', true), '');
begin
  if not exists (
    select 1 from public.usuarios where id = p_actor and rol = 'administrador'
  ) then
    raise exception using errcode = '42501', message = 'La acción requiere un perfil de administrador.';
  end if;

  select estado into v_estado
  from public.solicitudes_servicio where id = p_id for update;
  if not found then
    raise exception using errcode = 'PT404', message = 'La solicitud no existe.';
  end if;
  if v_estado = 'en proceso' then
    return false;
  end if;
  if v_estado is null or v_estado not in ('entrantes', 'aceptadas', 'iniciadas', 'en camino') then
    raise exception using errcode = 'PT409', message = 'La solicitud no se puede poner en curso en su estado actual.';
  end if;

  insert into public.solicitud_estado_eventos
    (solicitud_id, accion, estado_anterior, estado_nuevo, actor_id, ocurrido_en, idempotencia_id)
  values
    (p_id, 'iniciar_admin', v_estado, 'en proceso', p_actor, clock_timestamp(), gen_random_uuid())
  returning id into v_evento_id;

  perform set_config('hulp_sprint3.evento_id', v_evento_id::text, true);
  update public.solicitudes_servicio set estado = 'en proceso' where id = p_id;
  perform set_config('hulp_sprint3.evento_id', v_evento_previo, true);
  return true;
end;
$$;

revoke all on function public.solicitud_iniciar_admin_v1(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.solicitud_iniciar_admin_v1(uuid, uuid) to service_role;
