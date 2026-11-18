create schema if not exists hulp_ofertas;
revoke all on schema hulp_ofertas from public, anon, authenticated;

create function hulp_ofertas.proveedores_elegibles(
  p_ciudad uuid, p_servicio uuid, p_proveedor uuid default null
)
returns table (proveedor_id uuid)
language sql stable security definer
set search_path = ''
as $$
  select u.id
  from public.ciudades c
  join public.usuarios u on lower(btrim(u.ciudad)) = lower(btrim(c.nombre))
  join auth.users a on a.id = u.id
  join public.profesional_servicios ps
    on ps.usuario_id = u.id and ps.servicio_id = p_servicio
  where c.id = p_ciudad and c.activo is true
    and nullif(btrim(c.nombre), '') is not null
    and u.rol = 'proveedor'
    and u.verificado = 'verificado'
    and u.disponibilidad is true
    -- Mismo criterio de estado activo que vw_profesionales_completo.
    and a.last_sign_in_at >= current_timestamp - interval '30 days'
    and (p_proveedor is null or u.id = p_proveedor)
    and not exists (
      select 1 from public.ciudades otra
      where otra.activo is true and otra.id <> c.id
        and lower(btrim(otra.nombre)) = lower(btrim(c.nombre))
    );
$$;

-- Una solicitud histórica pendiente sigue siendo visible según la elegibilidad
-- actual. Solo una publicación nueva genera avisos.
create table hulp_ofertas.publicaciones (
  id uuid primary key,
  solicitud_id uuid not null references public.solicitudes_servicio(id) on delete cascade,
  creada_en timestamptz not null default now()
);
create index publicaciones_solicitud_idx on hulp_ofertas.publicaciones (solicitud_id);

create table hulp_ofertas.avisos (
  id uuid primary key default gen_random_uuid(),
  publicacion_id uuid not null references hulp_ofertas.publicaciones(id) on delete cascade,
  proveedor_id uuid not null references public.usuarios(id) on delete cascade,
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'enviado', 'omitido')),
  intento_en timestamptz not null default now(),
  intentos integer not null default 0,
  peticion_id bigint,
  enviado_en timestamptz,
  referencia_push text,
  codigo_http integer,
  unique (publicacion_id, proveedor_id)
);
create index avisos_pendientes_idx on hulp_ofertas.avisos (intento_en)
  where estado = 'pendiente';
alter table hulp_ofertas.publicaciones enable row level security;
alter table hulp_ofertas.avisos enable row level security;

create function hulp_ofertas.publicar_abierta(
  p_solicitud uuid, p_publicacion uuid, p_excluir uuid default null
) returns void
language plpgsql
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes_servicio%rowtype;
begin
  select * into v_solicitud from public.solicitudes_servicio s
  where s.id = p_solicitud and s.estado = 'entrantes' and s.profesional_id is null
  for update;
  if not found then return; end if;

  insert into hulp_ofertas.publicaciones (id, solicitud_id)
  values (p_publicacion, p_solicitud) on conflict (id) do nothing;
  if not found then return; end if;

  insert into hulp_ofertas.avisos (publicacion_id, proveedor_id)
  select p_publicacion, e.proveedor_id
  from hulp_ofertas.proveedores_elegibles(v_solicitud.ciudad_id, v_solicitud.servicio_id) e
  where e.proveedor_id is distinct from p_excluir;
end;
$$;

create function hulp_ofertas.al_crear_solicitud_abierta()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  perform hulp_ofertas.publicar_abierta(new.id, new.id);
  return new;
end;
$$;

create trigger sprint4_publicar_solicitud_abierta
after insert on public.solicitudes_servicio for each row
when (new.estado = 'entrantes' and new.profesional_id is null)
execute function hulp_ofertas.al_crear_solicitud_abierta();

-- Los clientes antiguos pasan por el mismo proxy. Su filtro y su paginación
-- se aplican después de autorizar cada fila en estas proyecciones.
create function hulp_ofertas.actor_del_proxy() returns uuid
language sql stable
set search_path = ''
as $$
  select (nullif(current_setting('request.headers', true), '')::jsonb
    ->> 'x-hulp-proveedor')::uuid;
$$;

create view public.solicitudes_talento_v1 with (security_barrier = true) as
select s.* from public.solicitudes_servicio s
where s.profesional_id = (select hulp_ofertas.actor_del_proxy())
  or (s.estado = 'entrantes' and s.profesional_id is null
    and (select hulp_ofertas.actor_del_proxy()) is not null
    and exists (
      select 1 from hulp_ofertas.proveedores_elegibles(
        s.ciudad_id, s.servicio_id, (select hulp_ofertas.actor_del_proxy())
      )
    ));

create view public.solicitudes_talento_completa_v1 with (security_barrier = true) as
select v.* from public.vw_solicitudes_servicios_completa v
join public.solicitudes_talento_v1 s on s.id = v.solicitud_id;

revoke all on public.solicitudes_talento_v1, public.solicitudes_talento_completa_v1
  from public, anon, authenticated;
grant select on public.solicitudes_talento_v1, public.solicitudes_talento_completa_v1
  to service_role;

-- Cierra la lectura directa de ofertas abiertas desde la vista histórica.
-- Se preservan sus columnas, dependencias y permisos existentes.
do $$
declare
  v_def text := rtrim(pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass, true), E';\n\r ');
begin
  execute format($view$
    create or replace view public.vw_solicitudes_servicios_completa
    with (security_barrier = true) as
    select v.* from (%s) v
    where v.estado_solicitud is distinct from 'entrantes'
      or v.profesional_id is not null
      or current_user in ('postgres', 'service_role')
      or v.usuario_id = (select auth.uid())
      or exists (
        select 1 from public.usuarios operador
        where operador.id = (select auth.uid()) and operador.rol = 'administrador'
      )
    order by v.solicitud_creada_en desc
  $view$, v_def);
end;
$$;

-- Solo se sustituye la comprobación de la oferta abierta. El bloqueo,
-- la idempotencia y la escritura del evento del Sprint 3 siguen en su RPC.
do $$
declare
  v_def text := pg_get_functiondef(
    'public.solicitud_transicion_v1(uuid,uuid,text,uuid)'::regprocedure
  );
  v_inicio text := '      if v_solicitud.profesional_id is null then';
  v_fin text := '      v_estado_nuevo := ''aceptadas'';';
  v_a integer;
  v_b integer;
begin
  v_a := strpos(v_def, v_inicio);
  v_b := strpos(v_def, v_fin);
  if v_a = 0 or v_b <= v_a then
    raise exception 'No se encontró la validación de aceptación del Sprint 3';
  end if;
  v_def := left(v_def, v_a - 1) || $bloque$      if v_solicitud.profesional_id is null and not exists (
        select 1 from hulp_ofertas.proveedores_elegibles(
          v_solicitud.ciudad_id, v_solicitud.servicio_id, p_actor
        )
      ) then
        raise exception using errcode = '42501',
          message = 'Esta solicitud ya no está disponible para ti.';
      end if;
$bloque$ || substr(v_def, v_b);
  execute replace(v_def,
    $anterior$message = 'La solicitud ya no está pendiente.'$anterior$,
    $nuevo$message = case
          when v_solicitud.profesional_id <> p_actor
            and v_solicitud.fecha_aceptacion is not null
            and exists (select 1 from hulp_ofertas.publicaciones p where p.solicitud_id = p_id)
          then 'Este servicio ya fue tomado'
          else 'La solicitud ya no está pendiente.'
        end$nuevo$);
end;
$$;

create function hulp_ofertas.leer_respuesta_push(p_contenido text) returns jsonb
language plpgsql immutable strict
set search_path = ''
as $$
begin
  return p_contenido::jsonb;
exception when invalid_text_representation then
  return null;
end;
$$;

create function hulp_ofertas.procesar_avisos()
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_app_id text;
  v_api_key text;
  v_aviso record;
begin
  -- pg_net guarda la respuesta por separado. Confirmar solo con un ID de
  -- OneSignal; el UUID del aviso se reutiliza en todos los reintentos.
  update hulp_ofertas.avisos a
  set codigo_http = case when r.status_code between 200 and 299
        and not (coalesce(hulp_ofertas.leer_respuesta_push(r.content), '{}'::jsonb) ? 'id')
      then null else r.status_code end,
      referencia_push = case when r.status_code between 200 and 299
        then nullif(hulp_ofertas.leer_respuesta_push(r.content) ->> 'id', '') end,
      peticion_id = null
  from net._http_response r
  where a.estado = 'pendiente' and r.id = a.peticion_id;

  update hulp_ofertas.avisos
  set estado = 'enviado', enviado_en = now()
  where estado = 'pendiente' and referencia_push is not null;

  update hulp_ofertas.avisos a
  set estado = 'omitido', peticion_id = null
  from hulp_ofertas.publicaciones p, public.solicitudes_servicio s
  where a.publicacion_id = p.id and p.solicitud_id = s.id
    and a.estado = 'pendiente' and a.peticion_id is null
    and (s.estado is distinct from 'entrantes' or s.profesional_id is not null
      or p.creada_en < now() - interval '29 days'
      or (a.codigo_http between 200 and 299)
      or not exists (
        select 1 from hulp_ofertas.proveedores_elegibles(
          s.ciudad_id, s.servicio_id, a.proveedor_id
        )
      ));

  select decrypted_secret into v_app_id from vault.decrypted_secrets
  where name = 'hulp_talento_onesignal_app_id';
  select decrypted_secret into v_api_key from vault.decrypted_secrets
  where name = 'hulp_talento_onesignal_api_key';
  if nullif(v_app_id, '') is null or nullif(v_api_key, '') is null then return; end if;

  for v_aviso in
    select a.id, a.proveedor_id, p.solicitud_id, a.intentos
    from hulp_ofertas.avisos a
    join hulp_ofertas.publicaciones p on p.id = a.publicacion_id
    join public.solicitudes_servicio s on s.id = p.solicitud_id
    where a.estado = 'pendiente' and a.intento_en <= now()
      and p.creada_en >= now() - interval '29 days'
      and s.estado = 'entrantes' and s.profesional_id is null
      and exists (
        select 1 from hulp_ofertas.proveedores_elegibles(
          s.ciudad_id, s.servicio_id, a.proveedor_id
        )
      )
    order by a.intento_en, a.id limit 100
    for update of a skip locked
  loop
    update hulp_ofertas.avisos
    set peticion_id = net.http_post(
      url := 'https://api.onesignal.com/notifications',
      headers := jsonb_build_object(
        'Authorization', 'Key ' || v_api_key, 'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'app_id', v_app_id, 'target_channel', 'push', 'idempotency_key', v_aviso.id,
        'filters', jsonb_build_array(
          jsonb_build_object('field', 'tag', 'key', 'user_id_supabase',
            'relation', '=', 'value', v_aviso.proveedor_id),
          jsonb_build_object('field', 'tag', 'key', 'notifications_enabled',
            'relation', '=', 'value', 'true')
        ),
        'headings', jsonb_build_object('en', 'Nueva solicitud', 'es', 'Nueva solicitud'),
        'contents', jsonb_build_object('en', 'Tienes un servicio disponible en Entrantes.',
          'es', 'Tienes un servicio disponible en Entrantes.'),
        'data', jsonb_build_object('solicitud_id', v_aviso.solicitud_id)
      ),
      timeout_milliseconds := 10000
    ), intentos = intentos + 1,
    intento_en = now() + make_interval(mins => (2 ^ least(v_aviso.intentos, 8))::integer),
    codigo_http = null
    where id = v_aviso.id;
  end loop;
end;
$$;

revoke all on all functions in schema hulp_ofertas from public, anon, authenticated;
grant usage on schema hulp_ofertas to service_role;
grant execute on function hulp_ofertas.proveedores_elegibles(uuid, uuid, uuid),
  hulp_ofertas.actor_del_proxy() to service_role;

select cron.schedule('hulp_sprint4_avisos_ofertas', '* * * * *',
  'select hulp_ofertas.procesar_avisos()');

notify pgrst, 'reload schema';
