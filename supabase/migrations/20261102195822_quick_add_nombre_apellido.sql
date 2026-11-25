-- Aplicada en Hulp/test: versión remota 20261102195822.
-- Guardar nombre y apellido en sus columnas.
begin;
-- Mantener la firma anterior para compatibilidad con versiones previas.
-- La función Edge actual usa esta nueva firma con p_apellido obligatorio.
create function public.quick_add_finalizar(p_usuario uuid,p_operador uuid,p_request uuid,
  p_nombre text,p_telefono text,p_direccion jsonb,p_apellido text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare existente jsonb; ciudad public.ciudades; cliente public.usuarios; direccion public.direcciones_usuario;
begin
  if not exists(select 1 from public.usuarios where id=p_operador and rol='administrador') then
    raise exception 'No autorizado';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_telefono,0));
  existente := public.quick_add_buscar(p_telefono);
  if existente is not null then return existente; end if;
  if p_nombre is null or length(btrim(p_nombre)) not between 1 and 200
    or p_apellido is null or length(btrim(p_apellido)) not between 1 and 200
    or p_telefono is null or p_telefono !~ '^573[0-9]{9}$' then
    raise exception 'Nombre, apellido y celular válidos son obligatorios';
  end if;
  if not exists(select 1 from auth.users where id=p_usuario and phone=p_telefono
    and raw_app_meta_data->>'quick_add_request_id'=p_request::text
    and raw_app_meta_data->>'quick_add_operador_id' is not null
    and phone_confirmed_at is null
    and not exists(select 1 from auth.sessions where user_id=p_usuario)) then
    raise exception 'Identidad no válida para este alta';
  end if;
  select * into ciudad from public.ciudades where id=(p_direccion->>'ciudad_id')::uuid and activo;
  if ciudad.id is null then raise exception 'Selecciona una ciudad activa'; end if;
  insert into public.usuarios(id,nombres,apellidos,telefono,codigo_pais,pais,rol,usuario_externo,
    direccion,ciudad,correo_electronico)
  values(p_usuario,btrim(p_nombre),btrim(p_apellido),substring(p_telefono from 3),'+57','Colombia','usuario',true,
    concat_ws(', ',nullif(btrim(p_direccion->>'direccion'),''),nullif(btrim(p_direccion->>'complemento'),''),
      nullif(btrim(p_direccion->>'referencia'),'')),ciudad.nombre,null) returning * into cliente;
  insert into public.direcciones_usuario(usuario_id,tipo,nombre,direccion,complemento,referencia,ciudad_id,latitud,longitud)
  values(p_usuario,coalesce(p_direccion->>'tipo','otra'),coalesce(p_direccion->>'nombre','Dirección inicial'),
    p_direccion->>'direccion',nullif(btrim(p_direccion->>'complemento'),''),nullif(btrim(p_direccion->>'referencia'),''),
    ciudad.id,(p_direccion->>'latitud')::numeric,(p_direccion->>'longitud')::numeric) returning * into direccion;
  return jsonb_build_object('cliente',to_jsonb(cliente),'direccion',to_jsonb(direccion),'existente',false);
end;
$$;
revoke all on function public.quick_add_finalizar(uuid,uuid,uuid,text,text,jsonb,text) from public,anon,authenticated;
grant execute on function public.quick_add_finalizar(uuid,uuid,uuid,text,text,jsonb,text) to service_role;
commit;
