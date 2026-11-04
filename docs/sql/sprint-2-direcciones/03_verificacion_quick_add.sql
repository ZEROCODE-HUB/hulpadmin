-- Ejecutar únicamente en Hulp/test (ptafsiwlhxomgqmdmidf).
-- Los registros temporales de Auth, perfil y dirección se revierten al final.
-- Esto verifica la transacción SQL; no sustituye probar Auth mediante su API.
begin;
do $test$
declare
  op uuid;
  city uuid;
  uid uuid := gen_random_uuid();
  req uuid := gen_random_uuid();
  result jsonb;
  payload jsonb;
begin
  select id into op from public.usuarios where rol = 'administrador' limit 1;
  select id into city from public.ciudades where activo limit 1;
  if op is null or city is null then raise exception 'Faltan fixtures existentes'; end if;
  if exists(select 1 from auth.users where phone = '573999999901') or
     exists(select 1 from public.usuarios
       where public.quick_add_normalizar_telefono(telefono) = '573999999901') then
    raise exception 'Celular de prueba ocupado';
  end if;
  payload := jsonb_build_object('tipo','casa','direccion','Calle de prueba Quick Add','ciudad_id',city);
  insert into auth.users(id,phone,raw_app_meta_data) values(uid,'573999999901',
    jsonb_build_object('quick_add_request_id',req,'quick_add_operador_id',op));
  if not (public.quick_add_identidad('573999999901')->>'recuperable')::boolean then
    raise exception 'No recupera pendiente';
  end if;
  begin
    perform public.quick_add_finalizar(uid,gen_random_uuid(),req,'Prueba','573999999901',payload,'Apellido de prueba');
    raise exception 'Aceptó operador inválido';
  exception when raise_exception then
    if sqlerrm = 'Aceptó operador inválido' then raise; end if;
  end;
  begin
    perform public.quick_add_finalizar(uid,op,req,'Prueba','573999999901',payload || '{"direccion":""}'::jsonb,'Apellido de prueba');
    raise exception 'Aceptó dirección vacía';
  exception when check_violation then null;
  end;
  if exists(select 1 from public.usuarios where id = uid) then
    raise exception 'Dejó perfil parcial';
  end if;
  result := public.quick_add_finalizar(uid,op,req,'Prueba Quick Add','573999999901',payload,'Apellido de prueba');
  if result->>'existente' <> 'false' or result->'cliente'->>'rol' <> 'usuario' or
    result->'cliente'->>'correo_electronico' is not null or
    result->'cliente'->>'apellidos' <> 'Apellido de prueba' then
    raise exception 'Perfil incorrecto';
  end if;
  result := public.quick_add_finalizar(uid,op,req,'No sobrescribir','573999999901',payload,'Apellido de prueba');
  if result->>'existente' <> 'true' or result->'cliente'->>'nombres' <> 'Prueba Quick Add' then
    raise exception 'Reintento no idempotente';
  end if;
  if (select count(*) from public.direcciones_usuario where usuario_id = uid) <> 1 then
    raise exception 'Número incorrecto de direcciones';
  end if;
  if has_function_privilege('anon','public.quick_add_buscar(text)','EXECUTE') or
    has_function_privilege('authenticated','public.quick_add_finalizar(uuid,uuid,uuid,text,text,jsonb,text)','EXECUTE') then
    raise exception 'RPC expuesto';
  end if;
  if not has_function_privilege('service_role','public.quick_add_finalizar(uuid,uuid,uuid,text,text,jsonb,text)','EXECUTE') then
    raise exception 'Backend sin permiso';
  end if;
end $test$;
select 'OK: atomicidad, duplicados, reintento, recuperación y permisos' as resultado;
rollback;
