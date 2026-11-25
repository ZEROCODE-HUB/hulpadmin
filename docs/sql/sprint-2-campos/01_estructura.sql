-- PREPARADO, NO EJECUTADO. No copiar a Producción. Ver README.
-- Requiere confirmación del destino en la sesión: SET hulp.target_ref = '...';
begin;

set
  local lock_timeout = '5s';

set
  local statement_timeout = '60s';

do $$ begin if current_setting('hulp.target_ref', true) is distinct
from
  'ptafsiwlhxomgqmdmidf' then raise exception 'Destino test no confirmado; revisar conexión y README';

end if;

if current_setting('server_version_num') :: int < 150000 then raise exception 'Requiere PostgreSQL 15+';

end if;

-- Huellas leídas del catálogo real de Hulp/test el 2026-11-05.
-- Si cambia un contrato dependiente, abortar y contrastar otra vez; no pisarlo.
if md5(pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass,true))
 <> '87920163697c65a1fb379957337444c2'
 or md5(pg_get_functiondef('public.actualizar_precio_solicitud_recibo()'::regprocedure))
 <> 'a54dd02662f2a1985b12396ef72d3f14'
 or md5(pg_get_functiondef('public.eliminar_mi_cuenta()'::regprocedure))
 <> 'a3fcd68fd465dfc42ddfe7f5edd27ea3' then
 raise exception 'Vista/trigger/eliminación cambió desde el contraste de test; revisar antes de aplicar';
end if;

end $$;

create schema hulp_finanzas;

revoke all on schema hulp_finanzas
from
  public,
  anon,
  authenticated;

grant usage on schema hulp_finanzas to service_role;

create table hulp_finanzas.config (
  singleton boolean primary key default true check(singleton),
  activado boolean not null default false
);

insert into
  hulp_finanzas.config(singleton, activado)
values
(true, false);

revoke all on hulp_finanzas.config
from
  public,
  anon,
  authenticated;

grant
select
  on hulp_finanzas.config to service_role;

-- No DEFAULT 1, UPDATE, backfill ni normalización de datos anteriores.
alter table
  public.solicitudes_servicio
add
  column motivo_precio_pagado text,
add
  column adelanto_proveedor numeric,
add
  column adelanto_concepto text,
add
  column adelanto_motivo text,
add
  column aplica_wompi boolean,
add
  column aplica_ajuste_iva boolean,
add
  column requiere_fe boolean,
add
  column notas_cliente text,
add
  column materiales_total numeric,
add
  column pago_proveedor numeric,
add
  column saldo_transferir numeric,
add
  column comision_base numeric,
add
  column ajuste_iva_valor numeric,
add
  column comision_hulp_iva numeric,
add
  column comision_neta_hulp numeric,
add
  column iva_valor numeric,
add
  column comision_efectiva numeric,
add
  column wompi_valor numeric,
add
  column total_cliente numeric,
add
  column finanzas_version integer,
add
  column finanzas_revision bigint,
add
  column finanzas_calculadas_en timestamptz,
add
  constraint solicitud_finanzas_version_check check (
    finanzas_version is null
    or finanzas_version = 1
  );

comment on column public.solicitudes_servicio.finanzas_version is 'NULL: cálculos/presentación anteriores; 1: contrato nuevo. No migrar históricos.';

comment on column public.solicitudes_servicio.precio is 'Version 1: mano de obra acordada sin materiales/recargos. NULL: significado histórico intacto.';

create table public.solicitud_items (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references public.solicitudes_servicio(id) on delete restrict,
  tipo_item text not null check(tipo_item in ('material', 'mano_obra')),
  descripcion text not null check(btrim(descripcion) <> ''),
  cantidad numeric not null check(
    cantidad > 0
    and cantidad :: text not in ('NaN', 'Infinity', '-Infinity')
  ),
  precio_unitario numeric not null check(
    precio_unitario >= 0
    and precio_unitario :: text not in ('NaN', 'Infinity', '-Infinity')
  ),
  total numeric generated always as (cantidad * precio_unitario) stored,
  orden integer not null default 0 check(orden >= 0),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index solicitud_items_solicitud_idx on public.solicitud_items(solicitud_id);

-- Enlace 1:1 propuesto para materiales aceptados de recibos, no agregado ciego.
-- El preflight debe confirmar el contrato remoto antes de aplicar esta extensión.
alter table
  public.solicitud_items
add
  column recibo_item_id uuid unique references public.recibo_items(id) on delete restrict;

create table public.solicitud_finanzas_historial (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references public.solicitudes_servicio(id) on delete restrict,
  revision bigint not null check(revision > 0),
  version_calculo integer not null check(version_calculo = 1),
  entradas jsonb not null check(jsonb_typeof(entradas) = 'object'),
  resultados jsonb not null check(jsonb_typeof(resultados) = 'object'),
  autor_id uuid references public.usuarios(id) on delete
  set
    null,
    motivo text,
    creado_en timestamptz not null default now(),
    unique(solicitud_id, revision)
);

create index solicitud_finanzas_historial_autor_idx on public.solicitud_finanzas_historial(autor_id)
where
  autor_id is not null;

-- Único dato nuevo en pagos: origen opcional del cobro de recibo.
-- Sin DEFAULT/backfill: todas las transacciones anteriores conservan NULL.
alter table public.transacciones add column recibo_id uuid
 references public.recibos(id) on delete restrict;
-- El flujo preparado confirma el recibo completo, no abonos al mismo recibo.
-- Los reintentos se resuelven por id/número de transacción, sin otro pago.
create unique index transacciones_recibo_id_unico_idx
 on public.transacciones(recibo_id) where recibo_id is not null;
comment on column public.transacciones.recibo_id is
 'Recibo pagado, opcional. NULL para cobro de solicitud e históricos sin reconstrucción. Versión/revisión no se duplican aquí.';

-- Las políticas abiertas antiguas no deben exponer las notas NUEVAS antes
-- de la activación de permisos: negar lectura de columnas nuevas por cliente.
-- El bloqueo global de SELECT * se hace coordinadamente en 05, no aquí.
-- No almacenar notas privadas nuevas antes de aplicar 05.
alter table
  public.solicitud_items enable row level security;

alter table
  public.solicitud_finanzas_historial enable row level security;

revoke all on public.solicitud_items,
public.solicitud_finanzas_historial
from
  public,
  anon,
  authenticated;

grant
select
,
insert
,
update
,
  delete on public.solicitud_items to service_role;

grant
select
,
insert
  on public.solicitud_finanzas_historial to service_role;

-- RLS sin políticas para clientes: acceso mediante backend autenticado,
-- que devuelve proyecciones por rol; no SELECT directo de JSON privados.
commit;
