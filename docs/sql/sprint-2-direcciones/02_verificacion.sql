-- SOLO LECTURA. Para después de una aplicación futura autorizada.
select count(*) as direcciones, count(*) filter (where ciudad_id is null) as sin_ciudad
from public.direcciones_usuario;
-- Debe ser cero inmediatamente tras migrar, antes de usar el nuevo formulario.
select count(*) as solicitudes_enlazadas
from public.solicitudes_servicio where direccion_usuario_id is not null;
select c.relrowsecurity, c.relname from pg_class c
where c.oid = 'public.direcciones_usuario'::regclass;
select * from pg_policies where schemaname = 'public' and tablename = 'direcciones_usuario';
select grantee, privilege_type from information_schema.role_table_grants
where table_schema = 'public' and table_name = 'direcciones_usuario';
select conname, pg_get_constraintdef(oid) as definicion from pg_constraint
where conrelid in ('public.direcciones_usuario'::regclass,
                  'public.solicitudes_servicio'::regclass);
select pg_get_functiondef('public.eliminar_mi_cuenta()'::regprocedure);
select column_name, ordinal_position from information_schema.columns
where table_schema = 'public' and table_name = 'vw_solicitudes_servicios_completa'
order by ordinal_position;
