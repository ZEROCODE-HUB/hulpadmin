-- SOLO LECTURA. Preparado, NO ejecutado. Destino exclusivo Hulp/test.
-- Guardar resultados antes de revisar/aplicar los archivos siguientes.
select
    current_database(),
    current_setting('server_version'),
    current_setting('app.settings.project_ref', true) as project_ref;

select
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
from
    information_schema.columns
where
    table_schema = 'public'
    and table_name in (
        'solicitudes_servicio',
        'recibos',
        'recibo_items',
        'transacciones'
    )
order by
    table_name,
    ordinal_position;

select
    c.relname,
    t.tgname,
    pg_get_triggerdef(t.oid),
    pg_get_functiondef(t.tgfoid)
from
    pg_trigger t
    join pg_class c on c.oid = t.tgrelid
where
    not t.tgisinternal
    and c.relnamespace = 'public' :: regnamespace
    and c.relname in (
        'solicitudes_servicio',
        'recibos',
        'recibo_items',
        'transacciones'
    );

select
    conrelid :: regclass,
    conname,
    pg_get_constraintdef(oid)
from
    pg_constraint
where
    conrelid in (
        'public.solicitudes_servicio' :: regclass,
        'public.transacciones' :: regclass,
        'public.recibo_items' :: regclass
    );

select
    *
from
    pg_policies
where
    schemaname = 'public'
    and tablename in (
        'solicitudes_servicio',
        'usuarios',
        'recibos',
        'transacciones'
    );

select
    grantee,
    table_name,
    privilege_type
from
    information_schema.table_privileges
where
    table_schema = 'public'
    and table_name in (
        'solicitudes_servicio',
        'vw_solicitudes_servicios_completa'
    );

select
    pg_get_viewdef(
        'public.vw_solicitudes_servicios_completa' :: regclass,
        true
    );

select
    pg_get_functiondef('public.eliminar_mi_cuenta()' :: regprocedure);

-- Rutas adicionales encontradas en el contraste real de test.
select p.proname,p.proconfig,p.prosecdef,pg_get_functiondef(p.oid)
from pg_proc p where p.oid in (
 'public.actualizar_estado_pago_solicitud(uuid)'::regprocedure,
 'public.procesar_pago_exitoso(uuid,character varying,numeric,character varying,jsonb,character varying)'::regprocedure,
 'public.reagendar_solicitud(uuid,date,time)'::regprocedure,
 'public.sync_ticket_seq()'::regprocedure,
 'public.crear_chat_al_asignar_proveedor()'::regprocedure,
 'public.programar_cleanup_conversaciones()'::regprocedure
);

select
    n.nspname,
    p.proname,
    pg_get_function_identity_arguments(p.oid)
from
    pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
where
    n.nspname not in ('pg_catalog', 'information_schema')
    and (
        p.proname ilike '%finanz%'
        or p.proname ilike '%historial%'
    );

select
    rol,
    count(*)
from
    public.usuarios
group by
    rol;

select
    count(*) as filas,
    sum(precio) as precio,
    sum(precio_base) as base,
    sum(precio_adicionales) as adicionales
from
    public.solicitudes_servicio;

-- Referencia exacta para regresión; no corregir estos registros.
-- Objetos/índices/ACL que REST no permite contrastar por sí solo.
select c.relname as tabla,a.attname as columna,
       format_type(a.atttypid,a.atttypmod) as tipo_exacto,a.attnotnull
from pg_attribute a join pg_class c on c.oid=a.attrelid
where c.oid in ('public.solicitudes_servicio'::regclass,'public.transacciones'::regclass,
 'public.recibos'::regclass,'public.recibo_items'::regclass)
and a.attnum>0 and not a.attisdropped;
select to_regnamespace('hulp_finanzas') as esquema_finanzas,
       to_regclass('public.solicitud_items') as items,
       to_regclass('public.solicitud_finanzas_historial') as historial;
select tablename,indexname,indexdef from pg_indexes where schemaname='public'
and tablename in ('solicitudes_servicio','recibos','recibo_items','transacciones');
select grantee,table_name,column_name,privilege_type
from information_schema.column_privileges where table_schema='public'
and table_name in ('solicitudes_servicio','vw_solicitudes_servicios_completa');
select distinct nv.nspname,v.relname from pg_depend d
join pg_rewrite r on r.oid=d.objid join pg_class v on v.oid=r.ev_class
join pg_namespace nv on nv.oid=v.relnamespace
where d.refobjid='public.solicitudes_servicio'::regclass and v.relkind in ('v','m');

-- Referencia exacta para regresión; no corregir estos registros.
select
    ticket,
    precio,
    precio_base,
    precio_adicionales
from
    public.solicitudes_servicio
where
    ticket in (1000, 1003, 1005, 1039, 1047)
order by
    ticket;
