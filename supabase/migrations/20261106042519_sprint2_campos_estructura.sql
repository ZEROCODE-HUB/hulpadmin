begin;
set local hulp.target_ref='ptafsiwlhxomgqmdmidf';
-- Fuente: 01_estructura.sql
-- PREPARADO, NO EJECUTADO. No copiar a Producción. Ver README.
-- Requiere confirmación del destino en la sesión: SET hulp.target_ref = '...';
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

-- Fuente: 02_calculo_y_guardado.sql
-- PREPARADO, NO EJECUTADO. Requiere 01. RPC SOLO service_role.
do $hulp_campos$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $hulp_campos$;

create function hulp_finanzas.calcular_v1(l numeric,p numeric,m numeric,a numeric,
 tarjeta boolean,ajuste boolean) returns jsonb
language plpgsql immutable set search_path='' as $hulp_campos$
declare g numeric; c numeric; i numeric; h numeric; n numeric; w numeric;
begin
 if l is null or p is null or m is null or a is null or tarjeta is null or ajuste is null
 or l<0 or p<0 or m<0 or a<0
 or l::text in ('NaN','Infinity','-Infinity') or p::text in ('NaN','Infinity','-Infinity')
 or m::text in ('NaN','Infinity','-Infinity') or a::text in ('NaN','Infinity','-Infinity') then
  raise exception 'Entradas financieras incompletas, negativas o no finitas' using errcode='23514';
 end if;
 g:=l*0.72; c:=p-g;
 i:=case when ajuste then c*0.19 else 0 end;
 h:=c+i; n:=round(case when ajuste then c else c/1.19 end,0);
 w:=case when tarjeta then (p+m+i)*0.05 else 0 end;
 return jsonb_build_object('materiales_total',m,'pago_proveedor',g,
  'saldo_transferir',g-a,'comision_base',c,'ajuste_iva_valor',i,
  'comision_hulp_iva',h,'comision_neta_hulp',n,'iva_valor',h-n,
  'comision_efectiva',case when p=0 then null else c/p*100 end,
  'wompi_valor',w,'total_cliente',p+m+i+w);
end $hulp_campos$;

-- Guardado atómico de datos financieros para una solicitud versión 1.
-- Crear/actualizar la fila operativa en la MISMA transacción desde un RPC
-- de creación (03). No se admite activar versión en registros anteriores.
create function hulp_finanzas.guardar_v1(p_id uuid,p_revision bigint,p_actor uuid,
 p_entradas jsonb,p_items jsonb,p_motivo text default null) returns jsonb
language plpgsql set search_path='' as $hulp_campos$
declare s public.solicitudes_servicio; x jsonb; r jsonb; m numeric;
 idx integer:=0; recibo public.recibo_items; rc public.recibos;
begin
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if not found then raise exception 'Solicitud inexistente'; end if;
 if s.finanzas_version is distinct from 1 then raise exception 'Solicitud fuera de versión 1'; end if;
 if p_revision is null or s.finanzas_revision is distinct from p_revision then
  raise exception 'La solicitud cambió; recargar' using errcode='40001';
 end if;
 if not (p_actor is null and current_user in ('postgres','service_role')) and not exists(select 1 from public.usuarios u where u.id=p_actor and u.rol='administrador') then
  -- El cliente puede inicializar su reserva, pero nunca editar el desglose.
  if p_revision<>0 or s.usuario_id is distinct from p_actor or p_items<>'[]'::jsonb
   or not exists(select 1 from public.usuarios u where u.id=p_actor and u.rol='usuario')
   or (p_entradas->>'precio_base')::numeric is distinct from
      (select precio from public.servicios where id=s.servicio_id)
   or (p_entradas->>'precio')::numeric is distinct from (p_entradas->>'precio_base')::numeric
   or coalesce((p_entradas->>'adelanto_proveedor')::numeric,0)<>0
   or coalesce((p_entradas->>'aplica_ajuste_iva')::boolean,false) then
   raise exception 'Solo Admin puede editar el desglose' using errcode='42501';
  end if;
 end if;
 if jsonb_typeof(p_entradas) is distinct from 'object' or
    jsonb_typeof(p_items) is distinct from 'array' then raise exception 'Objeto y lista de ítems requeridos'; end if;
 if exists(select 1 from jsonb_object_keys(p_entradas) k where k not in
  ('precio_base','precio','motivo_precio_pagado','adelanto_proveedor',
   'adelanto_concepto','adelanto_motivo','aplica_wompi','aplica_ajuste_iva','requiere_fe')) then
  raise exception 'Campo financiero no permitido';
 end if;
 if (p_entradas->>'precio')::numeric is distinct from (p_entradas->>'precio_base')::numeric
 and nullif(btrim(p_entradas->>'motivo_precio_pagado'),'') is null then
  raise exception 'Motivo obligatorio cuando precio y lista difieren';
 end if;
 if coalesce((p_entradas->>'adelanto_proveedor')::numeric,0)>0 and
 (nullif(btrim(p_entradas->>'adelanto_motivo'),'') is null or
  coalesce(p_entradas->>'adelanto_concepto','') not in ('Moto','Adelanto en efectivo','Otro')) then
  raise exception 'Adelanto requiere concepto y motivo';
 end if;
 -- Con pagos, preservar el precio/recargos ya acordados y los renglones cobrados.
 -- Se permite incorporar nuevos materiales pendientes, sin deshacer cobros.
 if exists(select 1 from public.transacciones t where t.solicitud_id=p_id) then
  if row((p_entradas->>'precio_base')::numeric,(p_entradas->>'precio')::numeric,
    (p_entradas->>'aplica_wompi')::boolean,(p_entradas->>'aplica_ajuste_iva')::boolean)
    is distinct from row(s.precio_base,s.precio,s.aplica_wompi,s.aplica_ajuste_iva) then
   raise exception 'No modificar precios ni recargos con pagos confirmados';
  end if;
  if exists(select 1 from public.solicitud_items si join public.recibo_items ri on ri.id=si.recibo_item_id
    join public.transacciones t on t.recibo_id=ri.recibo_id where si.solicitud_id=p_id
    and not exists(select 1 from jsonb_array_elements(p_items) x where
      x->>'recibo_item_id'=si.recibo_item_id::text and (x->>'cantidad')::numeric=si.cantidad
      and (x->>'precio_unitario')::numeric=si.precio_unitario)) then
   raise exception 'No modificar materiales de recibos pagados';
  end if;
 end if;
 if exists(select 1 from public.intentos_cobro where solicitud_id=p_id and resultado='pendiente' and detalle ? 'finanzas_revision') then
  raise exception 'Cobro pendiente: no modificar su revisión financiera';
 end if;
 delete from public.solicitud_items where solicitud_id=p_id;
 for x in select value from jsonb_array_elements(p_items) loop
  if jsonb_typeof(x) is distinct from 'object' or exists
   (select 1 from jsonb_object_keys(x) k where k not in
    ('tipo_item','descripcion','cantidad','precio_unitario','recibo_item_id')) then
   raise exception 'Campos de ítem no permitidos';
  end if;
  if x->>'recibo_item_id' is not null then
   select * into recibo from public.recibo_items where id=(x->>'recibo_item_id')::uuid;
   select * into rc from public.recibos where id=recibo.recibo_id for share;
   if rc.solicitud_id is distinct from p_id or rc.estado is distinct from 'aceptado'
    or lower(recibo.tipo_item) is distinct from 'material'
    or recibo.cantidad is distinct from (x->>'cantidad')::numeric
    or recibo.precio_unitario is distinct from (x->>'precio_unitario')::numeric then
    raise exception 'Material de recibo no aceptado, ajeno o diferente del original';
   end if;
  end if;
  insert into public.solicitud_items(solicitud_id,tipo_item,descripcion,cantidad,
   precio_unitario,orden,recibo_item_id)
  values(p_id,x->>'tipo_item',x->>'descripcion',(x->>'cantidad')::numeric,
   (x->>'precio_unitario')::numeric,idx,(x->>'recibo_item_id')::uuid);
  idx:=idx+1;
 end loop;
 select coalesce(sum(total),0) into m from public.solicitud_items
 where solicitud_id=p_id and tipo_item='material';
 r:=hulp_finanzas.calcular_v1((p_entradas->>'precio_base')::numeric,
  (p_entradas->>'precio')::numeric,m,coalesce((p_entradas->>'adelanto_proveedor')::numeric,0),
  coalesce((p_entradas->>'aplica_wompi')::boolean,false),
  coalesce((p_entradas->>'aplica_ajuste_iva')::boolean,false));
 if (r->>'total_cliente')::numeric < (select coalesce(sum(monto),0) from public.transacciones where solicitud_id=p_id) then
  raise exception 'Total menor que los pagos confirmados';
 end if;
 update public.solicitudes_servicio set precio_base=(p_entradas->>'precio_base')::numeric,
  precio=(p_entradas->>'precio')::numeric,motivo_precio_pagado=p_entradas->>'motivo_precio_pagado',
  adelanto_proveedor=coalesce((p_entradas->>'adelanto_proveedor')::numeric,0),
  adelanto_concepto=p_entradas->>'adelanto_concepto',adelanto_motivo=p_entradas->>'adelanto_motivo',
  aplica_wompi=coalesce((p_entradas->>'aplica_wompi')::boolean,false),
  aplica_ajuste_iva=coalesce((p_entradas->>'aplica_ajuste_iva')::boolean,false),
  requiere_fe=(p_entradas->>'requiere_fe')::boolean,
  materiales_total=m,pago_proveedor=(r->>'pago_proveedor')::numeric,
  saldo_transferir=(r->>'saldo_transferir')::numeric,comision_base=(r->>'comision_base')::numeric,
  ajuste_iva_valor=(r->>'ajuste_iva_valor')::numeric,comision_hulp_iva=(r->>'comision_hulp_iva')::numeric,
  comision_neta_hulp=(r->>'comision_neta_hulp')::numeric,iva_valor=(r->>'iva_valor')::numeric,
  comision_efectiva=(r->>'comision_efectiva')::numeric,wompi_valor=(r->>'wompi_valor')::numeric,
  total_cliente=(r->>'total_cliente')::numeric,finanzas_revision=p_revision+1,
  finanzas_calculadas_en=now()
 where id=p_id;
 insert into public.solicitud_finanzas_historial(solicitud_id,revision,version_calculo,
  entradas,resultados,autor_id,motivo)
 values(p_id,p_revision+1,1,jsonb_build_object('datos',p_entradas,'items',p_items),r,p_actor,p_motivo);
 return r || jsonb_build_object('solicitud_id',p_id,'revision',p_revision+1,'version',1);
end $hulp_campos$;

create function public.solicitud_finanzas_guardar_v1(p_id uuid,p_revision bigint,p_actor uuid,
 p_entradas jsonb,p_items jsonb,p_motivo text default null) returns jsonb
language sql set search_path='' as $hulp_campos$
 select hulp_finanzas.guardar_v1(p_id,p_revision,p_actor,p_entradas,p_items,p_motivo);
$hulp_campos$;

-- ACL explícitas. Ningún cliente puede suministrar un actor suplantado:
-- solo un backend service_role que ya validó el JWT invoca estos RPC.
revoke all on all functions in schema hulp_finanzas from public,anon,authenticated;
grant execute on all functions in schema hulp_finanzas to service_role;
revoke all on function public.solicitud_finanzas_guardar_v1(uuid,bigint,uuid,jsonb,jsonb,text)
 from public,anon,authenticated;
grant execute on function public.solicitud_finanzas_guardar_v1(uuid,bigint,uuid,jsonb,jsonb,text)
 to service_role;

-- Fuente: 03_rpc_y_protecciones.sql
-- PREPARADO, NO EJECUTADO. Requiere 01 y 02. No activa nuevos INSERT todavía.
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

-- Fuente: 04_vistas_y_lecturas.sql
-- PREPARADO, NO EJECUTADO. Ejecutar solo tras revisar 00 y adaptar consumidores.
do $$
declare v text; expresion text; n integer;
begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
 v:=pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass,true);
 -- Conservar exactamente las expresiones anteriores en la rama NULL.
 -- Aborta si la vista remota ya no coincide con los aliases documentados.
 foreach expresion in array array['precio_total','precio_calculado'] loop
  if v !~* ('COALESCE\(ss\.precio_base[^;]+? AS '||expresion) then
   raise exception 'Revisar expresión remota de % antes de reemplazar',expresion;
  end if;
  v:=regexp_replace(v,
   '(COALESCE\(ss\.precio_base[^\n]+?)( AS '||expresion||')',
   'CASE WHEN ss.finanzas_version IS NULL THEN \1 WHEN ss.finanzas_version = 1 THEN ss.total_cliente ELSE NULL::numeric END\2','i');
 end loop;
 if v !~ 'CASE WHEN ss.finanzas_version IS NULL' then raise exception 'No se transformó la vista'; end if;
 -- Agregar columnas únicamente al final; no romper el orden/tipos anteriores.
 -- La expresión se inserta antes de FROM solicitudes_servicio, sin DROP VIEW.
 v:=regexp_replace(v,'(\sFROM (?:public\.)?solicitudes_servicio ss)(\s)',
  ', ss.finanzas_version, ss.finanzas_revision, ss.finanzas_calculadas_en, ss.notas_cliente,'||
  ' ss.motivo_precio_pagado, ss.adelanto_proveedor, ss.adelanto_concepto, ss.adelanto_motivo,'||
  ' ss.aplica_wompi, ss.aplica_ajuste_iva, ss.requiere_fe, ss.materiales_total,'||
  ' ss.pago_proveedor, ss.saldo_transferir, ss.comision_base, ss.ajuste_iva_valor,'||
  ' ss.comision_hulp_iva, ss.comision_neta_hulp, ss.iva_valor, ss.comision_efectiva,'||
  ' ss.wompi_valor, ss.total_cliente \1\2','i');
 if v !~ 'ss.total_cliente\s+FROM' then raise exception 'No se agregaron columnas; revisar vista'; end if;
 execute 'create or replace view public.vw_solicitudes_servicios_completa as '||v;
end $$;

create function public.solicitud_finanzas_leer(p_actor uuid,p_id uuid) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; rol_actor text; r jsonb; items jsonb;
begin
 select u.rol into rol_actor from public.usuarios u where u.id=p_actor;
 select * into s from public.solicitudes_servicio where id=p_id;
 if s.id is null then raise exception 'Solicitud inexistente'; end if;
 if rol_actor is distinct from 'administrador' and s.usuario_id is distinct from p_actor
  and s.profesional_id is distinct from p_actor then
  raise exception 'Acceso no autorizado' using errcode='42501';
 end if;
 if s.finanzas_version is not null and s.finanzas_version<>1 then raise exception 'Versión no soportada'; end if;
 if s.finanzas_version=1 and s.total_cliente is null then raise exception 'Versión 1 incompleta'; end if;
 -- El backend puede conservar el mapa operativo anterior, pero debe evitar
 -- filtrar precio acordado o notas privadas a proveedoras.
 r:=jsonb_build_object('solicitud_id',s.id,'version',s.finanzas_version);
 if s.finanzas_version is null then
  r:=r||jsonb_build_object('precio_legacy',s.precio,'base_legacy',s.precio_base,
   'adicionales_legacy',s.precio_adicionales);
  -- Cada pantalla legacy conserva su fórmula; no unificarla con este RPC.
 else
  if rol_actor='proveedor' and s.profesional_id=p_actor then
   return r||jsonb_build_object('pago_proveedor',s.pago_proveedor,
    'saldo_transferir',s.saldo_transferir,'adelanto_proveedor',s.adelanto_proveedor,
    'descripcion',s.descripcion);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'tipo_item',i.tipo_item,
   'descripcion',i.descripcion,'cantidad',i.cantidad,'precio_unitario',i.precio_unitario,
   'total',i.total,'orden',i.orden,'recibo_item_id',i.recibo_item_id) order by i.orden,i.id),'[]'::jsonb)
   into items from public.solicitud_items i where i.solicitud_id=s.id;
  r:=r||jsonb_build_object('precio_base',s.precio_base,'precio',s.precio,
   'materiales_total',s.materiales_total,'wompi_valor',s.wompi_valor,
   'ajuste_iva_valor',s.ajuste_iva_valor,'total_cliente',s.total_cliente,'items',items,
   'revision',s.finanzas_revision,'requiere_fe',s.requiere_fe);
 end if;
 if rol_actor='administrador' then
  return r||jsonb_build_object('solicitud',to_jsonb(s));
 end if;
 -- Notas del cliente se permiten a su dueño; notas internas no se devuelven.
 if s.usuario_id=p_actor then r:=r||jsonb_build_object('notas_cliente',s.notas_cliente); end if;
 return r;
end $$;
revoke all on function public.solicitud_finanzas_leer(uuid,uuid) from public,anon,authenticated;
grant execute on function public.solicitud_finanzas_leer(uuid,uuid) to service_role;

-- Monto para firma/cobro de SOLICITUD; no devuelve centavos si hay fracciones
-- no representables. Esa decisión comercial sigue pendiente en el plan.
create function public.solicitud_importe_cobro(p_actor uuid,p_id uuid,p_revision bigint)
returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; monto numeric; pagado numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is null then
  monto:=coalesce(s.precio_base,s.precio,0)+coalesce(s.precio_adicionales,0);
  return jsonb_build_object('version',null,'monto',monto,'centavos',round(monto*100));
 end if;
 if p_revision is null or p_revision<>s.finanzas_revision then
  raise exception 'Revisión financiera obsoleta' using errcode='40001';
 end if;
 -- La versión es la de la solicitud, inmutable; no duplicarla en pagos.
 -- Solo se registran confirmaciones en transacciones. Los pagos de recibo
 -- (recibo_id no nulo) también reducen el saldo del servicio una sola vez.
 select coalesce(sum(t.monto),0) into pagado from public.transacciones t
 where t.solicitud_id=p_id;
 monto:=s.total_cliente-pagado;
 if monto<=0 then raise exception 'No hay saldo positivo que cobrar'; end if;
 monto:=round(monto,2);
 return jsonb_build_object('version',1,'revision',s.finanzas_revision,
  'monto',monto,'centavos',monto*100,'pagado',pagado);
end $$;
revoke all on function public.solicitud_importe_cobro(uuid,uuid,bigint) from public,anon,authenticated;
grant execute on function public.solicitud_importe_cobro(uuid,uuid,bigint) to service_role;

-- Fuente: 06_pagos_confirmados.sql
-- PREPARADO, NO EJECUTADO. Ejecutar antes de activar 05.
-- No consulta Wompi: el backend verifica aprobación, moneda, monto, solicitud,
-- fuente y firma antes de invocar. Solo registra una confirmación comprobada.
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $$;

-- Importe de un recibo aceptado cuyos materiales ya están incorporados a v1.
-- No infiere mano de obra de un recibo mixto ni cobra materiales dos veces.
create function hulp_finanzas.importe_recibo_v1(p_id uuid,p_recibo uuid)
returns numeric language plpgsql set search_path='' as $$
declare rc public.recibos; incorporado numeric; s public.solicitudes_servicio; pagado numeric;
begin
 select * into rc from public.recibos where id=p_recibo for share;
 if rc.id is null or rc.solicitud_id is distinct from p_id
  or rc.estado is distinct from 'aceptado' then
  raise exception 'Recibo inexistente, ajeno o sin aceptación';
 end if;
 if not exists(select 1 from public.recibo_items ri where ri.recibo_id=p_recibo)
 or exists(select 1 from public.recibo_items ri where ri.recibo_id=p_recibo and
  (lower(ri.tipo_item) not in ('material','mano_obra') or (ri.tipo_item='material' and not exists
   (select 1 from public.solicitud_items si where si.solicitud_id=p_id
    and si.recibo_item_id=ri.id and si.tipo_item='material'
    and si.cantidad=ri.cantidad and si.precio_unitario=ri.precio_unitario)))) then
  raise exception 'Recibo mixto, vacío o con materiales sin incorporar';
 end if;
 select coalesce(sum(si.total),0) into incorporado from public.solicitud_items si
 join public.recibo_items ri on ri.id=si.recibo_item_id
 where si.solicitud_id=p_id and ri.recibo_id=p_recibo;
 select * into s from public.solicitudes_servicio where id=p_id;
 select coalesce(sum(monto),0) into pagado from public.transacciones where solicitud_id=p_id;
 if exists(select 1 from public.recibo_items where recibo_id=p_recibo and tipo_item='mano_obra') then
  return round(s.total_cliente-pagado,2);
 end if;
 if rc.total is null or rc.total<=0 or incorporado is distinct from rc.total then
  raise exception 'Total de recibo diferente del detalle';
 end if;
 return round(rc.total * case when s.aplica_wompi then 1.05 else 1 end,2);
end $$;
revoke all on function hulp_finanzas.importe_recibo_v1(uuid,uuid) from public,anon,authenticated;
grant execute on function hulp_finanzas.importe_recibo_v1(uuid,uuid) to service_role;

create function public.solicitud_recibo_importe_cobro_v1(p_actor uuid,p_id uuid,
 p_revision bigint,p_recibo uuid) returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; importe numeric; pagado numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 or p_revision is distinct from s.finanzas_revision then
  raise exception 'Versión o revisión financiera incorrecta' using errcode='40001';
 end if;
 if p_recibo is null then raise exception 'Recibo requerido'; end if;
 if exists(select 1 from public.transacciones t where t.recibo_id=p_recibo) then
  raise exception 'El recibo ya tiene un pago confirmado';
 end if;
 importe:=hulp_finanzas.importe_recibo_v1(p_id,p_recibo);
 select coalesce(sum(t.monto),0) into pagado from public.transacciones t where t.solicitud_id=p_id;
 if importe>s.total_cliente-pagado then raise exception 'Recibo superior al saldo del servicio'; end if;
 return jsonb_build_object('version',1,'revision',s.finanzas_revision,'recibo_id',p_recibo,
  'monto',importe,'centavos',importe*100);
end $$;
revoke all on function public.solicitud_recibo_importe_cobro_v1(uuid,uuid,bigint,uuid)
 from public,anon,authenticated;
grant execute on function public.solicitud_recibo_importe_cobro_v1(uuid,uuid,bigint,uuid) to service_role;

create function public.solicitud_pago_confirmar_v1(p_actor uuid,p_id uuid,p_revision bigint,
 p_transaccion uuid,p_numero text,p_monto numeric,p_metodo text,p_proveedor text,
 p_recibo uuid default null) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; t public.transacciones;
 pagado numeric; saldo numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 or p_revision is distinct from s.finanzas_revision then
  raise exception 'Versión o revisión financiera incorrecta' using errcode='40001';
 end if;
 if p_transaccion is null or p_monto is null or p_monto<=0
  or p_monto::text in ('NaN','Infinity','-Infinity') or p_monto*100<>trunc(p_monto*100) then
  raise exception 'Identificador e importe exacto en centavos requeridos';
 end if;
 if nullif(btrim(p_metodo),'') is null or nullif(btrim(p_proveedor),'') is null then
  raise exception 'Método y proveedor requeridos';
 end if;
 if p_proveedor<>'QR' and nullif(btrim(p_numero),'') is null then
  raise exception 'Número confirmado del procesador requerido';
 end if;
 if p_proveedor='QR' and not exists(select 1 from public.usuarios u
  where u.id=p_actor and u.rol='administrador') then
  raise exception 'Solo Admin confirma pago manual' using errcode='42501';
 end if;
 -- ID estable en reintentos; el mismo número de Wompi tampoco puede duplicarse.
 select * into t from public.transacciones where id=p_transaccion
  or (p_numero is not null and numero_transaccion=p_numero) limit 1;
 if found then
  if t.solicitud_id is distinct from p_id or t.monto is distinct from p_monto
   or t.recibo_id is distinct from p_recibo
   or t.numero_transaccion is distinct from nullif(btrim(p_numero),'')
   or t.metodo_pago is distinct from p_metodo or t.proveedor_pago is distinct from p_proveedor then
   raise exception 'Referencia de pago reutilizada con otros datos';
  end if;
  return jsonb_build_object('transaccion_id',t.id,'existente',true);
 end if;
 select coalesce(sum(monto),0) into pagado from public.transacciones
 where solicitud_id=p_id;
 saldo:=round(s.total_cliente-pagado,2);
 if p_recibo is null then
  if p_monto is distinct from saldo then raise exception 'El pago no coincide con el saldo'; end if;
 else
  if p_monto is distinct from hulp_finanzas.importe_recibo_v1(p_id,p_recibo) then
   raise exception 'El pago no coincide con el recibo incorporado';
  end if;
  if exists(select 1 from public.transacciones where recibo_id=p_recibo) then
   raise exception 'El recibo ya tiene un pago confirmado';
  end if;
 end if;
 if p_monto>saldo then raise exception 'Pago superior al saldo; requiere conciliación'; end if;
 insert into public.transacciones(id,solicitud_id,usuario_id,numero_transaccion,monto,
  moneda,proveedor_pago,metodo_pago,fecha_pago,fecha_registro,recibo_id)
 values(p_transaccion,p_id,s.usuario_id,nullif(btrim(p_numero),''),p_monto,'COP',
  p_proveedor,p_metodo,now(),now(),p_recibo);
 -- Acreditar la solicitud solo cuando los pagos cubren su total.
 if round(pagado+p_monto,2)=round(s.total_cliente,2) then
  update public.solicitudes_servicio set estado_pago='pagado',fecha_pago=now() where id=p_id;
 end if;
 return jsonb_build_object('transaccion_id',p_transaccion,'existente',false,
  'pendiente',s.total_cliente-pagado-p_monto);
end $$;
revoke all on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid)
 from public,anon,authenticated;
grant execute on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid)
 to service_role;

create function hulp_finanzas.proteger_pago_v1() returns trigger
language plpgsql security invoker set search_path='' as $$
declare v integer;
begin
 -- Validar pertenencia también en escrituras directas del backend y filas
 -- legacy que aporten explícitamente un vínculo. No rellenar históricos NULL.
 if new.recibo_id is not null and not exists(select 1 from public.recibos r
  where r.id=new.recibo_id and r.solicitud_id=new.solicitud_id) then
  raise exception 'El recibo no pertenece a la solicitud de la transacción';
 end if;
 select finanzas_version into v from public.solicitudes_servicio where id=new.solicitud_id;
 if v is null then return new; end if;
 -- Usar el rol SQL efectivo: en eliminar_mi_cuenta (SECURITY DEFINER) es
 -- postgres aunque el JWT original siga siendo authenticated. El trigger
 -- INVOKER conserva ese contexto y permite anonimizar solo usuario_id.
 if current_user not in ('postgres','service_role') then
  raise exception 'Confirmación de pagos v1 solo desde backend' using errcode='42501';
 end if;
 if tg_op='UPDATE' then
  -- Compatibilidad con eliminar_mi_cuenta: solo reasigna el usuario.
  if (to_jsonb(new)-'usuario_id')=(to_jsonb(old)-'usuario_id') then return new; end if;
  raise exception 'Pago confirmado v1 inmutable; usar flujo de devolución';
 end if;
 return new;
end $$;
revoke all on function hulp_finanzas.proteger_pago_v1() from public,anon,authenticated,service_role;
create trigger sprint2_pago_proteger before insert or update on public.transacciones
 for each row execute function hulp_finanzas.proteger_pago_v1();

-- Fuente: 08_integracion.sql
-- Integración de formularios. Instalar después de 06 y antes de 05.
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $$;

create function public.solicitud_finanzas_previsualizar_v1(p_entradas jsonb,p_items jsonb)
returns jsonb language sql set search_path='' as $$
 select hulp_finanzas.calcular_v1((p_entradas->>'precio_base')::numeric,
  (p_entradas->>'precio')::numeric,
  coalesce((select sum((x->>'cantidad')::numeric*(x->>'precio_unitario')::numeric)
    from jsonb_array_elements(p_items) x where x->>'tipo_item'='material'),0),
  coalesce((p_entradas->>'adelanto_proveedor')::numeric,0),
  coalesce((p_entradas->>'aplica_wompi')::boolean,false),
  coalesce((p_entradas->>'aplica_ajuste_iva')::boolean,false));
$$;

create function public.solicitud_editar_v1(p_actor uuid,p_id uuid,p_revision bigint,
 p_datos jsonb,p_finanzas jsonb,p_items jsonb) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; n public.solicitudes_servicio; r jsonb;
begin
 if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
  raise exception 'Solo Admin puede editar' using errcode='42501';
 end if;
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
 if exists(select 1 from jsonb_object_keys(p_datos) k where k not in
  ('descripcion','informacion_adicional','ubicacion','fecha','hora','profesional_id',
   'servicio_id','servicio_nombre','ciudad_id','latitud','longitud','direccion_usuario_id','estado')) then
  raise exception 'Campo operativo no permitido';
 end if;
 n:=jsonb_populate_record(s,p_datos);
 update public.solicitudes_servicio set descripcion=n.descripcion,
 informacion_adicional=n.informacion_adicional,ubicacion=n.ubicacion,fecha=n.fecha,hora=n.hora,
 profesional_id=n.profesional_id,servicio_id=n.servicio_id,servicio_nombre=n.servicio_nombre,
 ciudad_id=n.ciudad_id,latitud=n.latitud,longitud=n.longitud,direccion_usuario_id=n.direccion_usuario_id,
 estado=n.estado where id=p_id;
 r:=hulp_finanzas.guardar_v1(p_id,p_revision,p_actor,p_finanzas,p_items,'Edición Admin');
 return r;
end $$;

-- Recibos aceptados: la lista de mano de obra reemplaza la cotización anterior.
-- Materiales se incorporan por su ID de origen y solo una vez. Los recibos ya
-- pagados conservan su detalle; no se promueven ni recalculan históricos.
create function hulp_finanzas.sincronizar_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; labor numeric;
begin
 select * into s from public.solicitudes_servicio where id=new.solicitud_id for update;
 if s.finanzas_version is distinct from 1 then return new; end if;
 if new.estado is distinct from 'aceptado' then return new; end if;
 if tg_op='UPDATE' and old.estado='aceptado' then return new; end if;
 select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',descripcion,
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',recibo_item_id) order by orden,id),'[]')
 into items from public.solicitud_items where solicitud_id=s.id;
 select coalesce(jsonb_agg(jsonb_build_object('tipo_item','material','descripcion',coalesce(descripcion,'Material'),
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',id)),'[]') || items
 into items from public.recibo_items where recibo_id=new.id and tipo_item='material'
 and id not in(select recibo_item_id from public.solicitud_items where recibo_item_id is not null);
 select sum(cantidad*precio_unitario) into labor from public.recibo_items
 where recibo_id=new.id and tipo_item='mano_obra';
 entradas:=jsonb_build_object('precio_base',coalesce(labor,s.precio_base),
  'precio',coalesce(labor,s.precio),'motivo_precio_pagado',s.motivo_precio_pagado,
  'adelanto_proveedor',s.adelanto_proveedor,'adelanto_concepto',s.adelanto_concepto,
  'adelanto_motivo',s.adelanto_motivo,'aplica_wompi',s.aplica_wompi,
  'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
 perform hulp_finanzas.guardar_v1(s.id,s.finanzas_revision,null,entradas,items,'Recibo aceptado');
 return new;
end $$;
create trigger sprint2_recibo_incorporar after update of estado on public.recibos
 for each row execute function hulp_finanzas.sincronizar_recibo_v1();

revoke all on function public.solicitud_finanzas_previsualizar_v1(jsonb,jsonb),
 public.solicitud_editar_v1(uuid,uuid,bigint,jsonb,jsonb,jsonb),
 hulp_finanzas.sincronizar_recibo_v1() from public,anon,authenticated;
grant execute on function public.solicitud_finanzas_previsualizar_v1(jsonb,jsonb),
 public.solicitud_editar_v1(uuid,uuid,bigint,jsonb,jsonb,jsonb) to service_role;

-- Un solo cobro v1 pendiente por solicitud, incluso entre dos dispositivos.
-- El detalle ya existente conserva la revisión de la intención, sin columnas
-- financieras redundantes en transacciones.
create unique index intentos_cobro_finanzas_pendiente_idx on public.intentos_cobro(solicitud_id)
 where resultado='pendiente' and detalle ? 'finanzas_revision';

create function public.solicitud_cobro_preparar_v1(p_actor uuid,p_id uuid,p_recibo uuid,
 p_tarjeta boolean) returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; r jsonb;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
 if exists(select 1 from public.intentos_cobro where solicitud_id=p_id and resultado='pendiente'
  and detalle ? 'finanzas_revision') then raise exception 'Ya hay un cobro pendiente; consulta su estado'; end if;
 if p_recibo is not null then
  if s.usuario_id<>p_actor and not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
   raise exception 'Solo el cliente o Admin acepta el recibo';
  end if;
  if exists(select 1 from public.transacciones where recibo_id=p_recibo) then raise exception 'Recibo ya pagado'; end if;
  update public.recibos set estado='aceptado',respondido_en=now()
   where id=p_recibo and solicitud_id=p_id and estado in ('pendiente','aceptado');
  if not found then raise exception 'Recibo no disponible'; end if;
  select * into s from public.solicitudes_servicio where id=p_id;
 end if;
 if s.aplica_wompi is distinct from p_tarjeta then
  select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',descripcion,
   'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',recibo_item_id) order by orden,id),'[]')
  into items from public.solicitud_items where solicitud_id=p_id;
  entradas:=jsonb_build_object('precio_base',s.precio_base,'precio',s.precio,
   'motivo_precio_pagado',s.motivo_precio_pagado,'adelanto_proveedor',s.adelanto_proveedor,
   'adelanto_concepto',s.adelanto_concepto,'adelanto_motivo',s.adelanto_motivo,
   'aplica_wompi',p_tarjeta,'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
  perform hulp_finanzas.guardar_v1(p_id,s.finanzas_revision,null,entradas,items,'Método verificado de cobro');
  select * into s from public.solicitudes_servicio where id=p_id;
 end if;
 if p_recibo is null then
  r:=public.solicitud_importe_cobro(p_actor,p_id,s.finanzas_revision);
 else
  r:=public.solicitud_recibo_importe_cobro_v1(p_actor,p_id,s.finanzas_revision,p_recibo);
 end if;
 return r;
end $$;
revoke all on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean) to service_role;

commit;
