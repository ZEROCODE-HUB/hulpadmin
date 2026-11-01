-- SOLO LECTURA. Preparado, no ejecutado. Destino exclusivo: Hulp/test.
select current_database(), current_setting('server_version') as version;
select to_regclass('public.direcciones_usuario') as tabla_nueva,
       to_regprocedure('public.validar_direccion_usuario()') as funcion_nueva;
select md5(pg_get_functiondef('public.eliminar_mi_cuenta()'::regprocedure)) as funcion_hash,
       md5(pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass, true)) as vista_hash;
-- Roles usados por las políticas nuevas; no se cambian sus protecciones actuales.
select rol, count(*) from public.usuarios group by rol;
select count(*) as clientes,
       count(*) filter (where nullif(btrim(direccion), '') is not null) as a_migrar
from public.usuarios where rol = 'usuario';
-- Casos que quedarán sin ciudad: no se modifica su texto ni se usa fuzzy match.
select u.id, u.ciudad,
       (select count(*) from public.ciudades c
        where lower(btrim(c.nombre)) = lower(btrim(u.ciudad))) as coincidencias
from public.usuarios u
where u.rol = 'usuario' and nullif(btrim(u.direccion), '') is not null
and (select count(*) from public.ciudades c
     where lower(btrim(c.nombre)) = lower(btrim(u.ciudad))) <> 1;
select conname, pg_get_constraintdef(oid) as definicion
from pg_constraint where conrelid = 'public.solicitudes_servicio'::regclass;
select * from pg_policies where schemaname = 'public'
and tablename in ('usuarios', 'solicitudes_servicio');
