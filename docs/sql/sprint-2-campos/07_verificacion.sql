-- Verificación posterior al despliegue exclusivo en Test. Ver README.
-- Solo SELECT y cálculos puros; no inserta/actualiza filas ni llama RPC de cobro.
select finanzas_version,count(*) from public.solicitudes_servicio group by 1;
select ticket,precio,precio_base,precio_adicionales,finanzas_version
from public.solicitudes_servicio where ticket in (1000,1003,1005,1039,1047) order by ticket;
select column_name,column_default,is_nullable from information_schema.columns
where table_schema='public' and table_name='solicitudes_servicio'
and column_name='finanzas_version';
select rolname,
 has_function_privilege(rolname,'public.solicitud_crear_v1(uuid,jsonb,jsonb,jsonb)','EXECUTE') as crear,
 has_function_privilege(rolname,'public.solicitud_finanzas_guardar_v1(uuid,bigint,uuid,jsonb,jsonb,text)','EXECUTE') as guardar,
 has_table_privilege(rolname,'public.solicitud_finanzas_historial','SELECT') as historial
from pg_roles where rolname in ('anon','authenticated','service_role');
-- Después de activar: notas directas false; vista disponible true y columnas operativas legibles.
select has_table_privilege('authenticated','public.solicitudes_servicio','SELECT') as tabla_completa,
 has_column_privilege('authenticated','public.solicitudes_servicio','informacion_adicional','SELECT') as notas,
 has_table_privilege('authenticated','public.vw_solicitudes_servicios_completa','SELECT') as vista_completa;

-- Todos los OK deben ser true. Función pura: no toca tablas.
with casos(nombre,l,p,m,a,tarjeta,ajuste,esperado) as (values
 ('limpieza',119900::numeric,119900::numeric,0::numeric,0::numeric,false,false,
  '{"pago_proveedor":86328,"comision_hulp_iva":33572,"comision_neta_hulp":28212,"iva_valor":5360,"total_cliente":119900}'::jsonb),
 ('descuento',119900,109900,0,0,false,false,
  '{"pago_proveedor":86328,"comision_hulp_iva":23572,"comision_neta_hulp":19808,"iva_valor":3764,"total_cliente":109900}'::jsonb),
 ('tarjeta',119900,119900,0,0,true,false,
  '{"wompi_valor":5995,"total_cliente":125895}'::jsonb),
 ('materiales',120000,120000,60000,0,true,false,
  '{"pago_proveedor":86400,"wompi_valor":9000,"total_cliente":189000}'::jsonb),
 ('iva adicional',390000,390000,0,0,false,true,
  '{"pago_proveedor":280800,"ajuste_iva_valor":20748,"comision_hulp_iva":129948,"comision_neta_hulp":109200,"iva_valor":20748,"total_cliente":410748}'::jsonb),
 ('adelanto',119900,119900,0,6000,false,false,
  '{"pago_proveedor":86328,"saldo_transferir":80328,"total_cliente":119900}'::jsonb)
)
select nombre,hulp_finanzas.calcular_v1(l,p,m,a,tarjeta,ajuste) @> esperado as ok
from casos;
select hulp_finanzas.calcular_v1(0,0,0,0,false,false)->'comision_efectiva'
 = 'null'::jsonb as cero_sin_division;

-- Inconsistencias de versión 1: ambas consultas deben devolver cero filas.
select s.id,s.ticket from public.solicitudes_servicio s
where s.finanzas_version=1 and (s.total_cliente is null or s.finanzas_revision<1
 or not exists(select 1 from public.solicitud_finanzas_historial h
  where h.solicitud_id=s.id and h.revision=s.finanzas_revision));
select s.id from public.solicitudes_servicio s
where s.finanzas_version is null and (s.total_cliente is not null
 or s.finanzas_revision is not null or s.finanzas_calculadas_en is not null);

-- Revisar las rutas relacionadas con la privacidad de notas de solicitud.
-- Alcance: solo rutas que exponen las notas/importes nuevos; no auditoría
-- general ni requisito de reparar reagendar_solicitud.
select has_column_privilege('authenticated','public.solicitudes_servicio','id','SELECT')
 and has_column_privilege('authenticated','public.solicitudes_servicio','servicio_id','SELECT')
 as conteo_categorias_conservado;
-- Esquema de pago-recibo: nullable, sin default; FK e índice único parcial.
select column_name,data_type,is_nullable,column_default from information_schema.columns
where table_schema='public' and table_name='transacciones' and column_name='recibo_id';
select conname,pg_get_constraintdef(oid) from pg_constraint
where conrelid='public.transacciones'::regclass and contype='f';
select indexdef from pg_indexes where schemaname='public'
and tablename='transacciones' and indexname='transacciones_recibo_id_unico_idx';
-- Debe devolver cero filas: vínculo a una solicitud diferente o pago duplicado.
select t.id from public.transacciones t join public.recibos r on r.id=t.recibo_id
where t.solicitud_id is distinct from r.solicitud_id;
select recibo_id,count(*) from public.transacciones where recibo_id is not null
group by recibo_id having count(*)>1;

-- Inventario de lectura: no implica modificar cada vista o sus políticas.
select distinct nv.nspname,v.relname
from pg_depend d join pg_rewrite r on r.oid=d.objid
join pg_class v on v.oid=r.ev_class join pg_namespace nv on nv.oid=v.relnamespace
where d.refobjid='public.solicitudes_servicio'::regclass and v.relkind in ('v','m');

