-- Preparado para Hulp/test (ptafsiwlhxomgqmdmidf). NO EJECUTADO.
-- Una sola transacción: tabla, seguridad, backfill, FK, eliminación y vista.
-- No usar en otros ambientes sin contrastar su esquema.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- Abortar ante diferencias con la función/vista inspeccionadas; no reemplazar
-- cambios remotos posteriores por una copia antigua de sus definiciones.
do $precondiciones$
begin
  if current_setting('server_version_num')::integer < 150000 then
    raise exception 'Esta migración requiere PostgreSQL 15 o posterior';
  end if;
  if md5(pg_get_functiondef('public.eliminar_mi_cuenta()'::regprocedure))
      <> 'b002b680ddb2c4a5060889f421daa6d4'
    or md5(pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass, true))
      <> '044a81c05fcd34d9e3e2237d04fb691b' then
    raise exception 'La función o vista cambió desde la revisión de test; reconciliar antes de aplicar';
  end if;
end;
$precondiciones$;

create table public.direcciones_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  tipo text not null check (tipo in ('casa', 'oficina', 'otra')),
  nombre text,
  direccion text not null check (length(btrim(direccion)) > 0),
  complemento text,
  referencia text,
  ciudad_id uuid references public.ciudades(id) on delete restrict,
  latitud numeric(10,7),
  longitud numeric(10,7),
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint direcciones_usuario_id_propietario_key unique (id, usuario_id),
  constraint direcciones_usuario_nombre_otra_check
    check (tipo <> 'otra' or (nombre is not null and length(btrim(nombre)) > 0)),
  constraint direcciones_usuario_coordenadas_check
    check ((latitud is null) = (longitud is null)),
  constraint direcciones_usuario_latitud_check
    check (latitud is null or latitud between -90 and 90),
  constraint direcciones_usuario_longitud_check
    check (longitud is null or longitud between -180 and 180)
);
comment on table public.direcciones_usuario is
  'Direcciones del perfil. No sustituye el snapshot histórico de solicitudes.';
create index direcciones_usuario_propietario_activo_idx
  on public.direcciones_usuario(usuario_id, activo);
create index direcciones_usuario_ciudad_idx on public.direcciones_usuario(ciudad_id);

alter table public.direcciones_usuario enable row level security;
revoke all on public.direcciones_usuario from public, anon, authenticated;
grant select, insert, update on public.direcciones_usuario to authenticated;
grant all on public.direcciones_usuario to service_role;
-- Autorización por rol existente, sin lista privada. Se conservan los permisos
-- actuales de usuarios. Por decisión de alcance, su riesgo de modificación
-- del rol no se corrige aquí; estas políticas dependen de ese campo.
-- Contrato listo para Admin y cliente, aunque Flutter móvil se integre después.
create policy direcciones_select on public.direcciones_usuario
  for select to authenticated using (
    (select exists (select 1 from public.usuarios
      where id = auth.uid() and rol = 'administrador'))
    or (usuario_id = (select auth.uid()) and
      (select exists (select 1 from public.usuarios
        where id = auth.uid() and rol = 'usuario')))
  );
create policy direcciones_insert on public.direcciones_usuario
  for insert to authenticated with check (
    (select exists (select 1 from public.usuarios
      where id = auth.uid() and rol = 'administrador'))
    or (usuario_id = (select auth.uid()) and
      (select exists (select 1 from public.usuarios
        where id = auth.uid() and rol = 'usuario')))
  );
create policy direcciones_update on public.direcciones_usuario
  for update to authenticated using (
    (select exists (select 1 from public.usuarios
      where id = auth.uid() and rol = 'administrador'))
    or (usuario_id = (select auth.uid()) and
      (select exists (select 1 from public.usuarios
        where id = auth.uid() and rol = 'usuario')))
  ) with check (
    (select exists (select 1 from public.usuarios
      where id = auth.uid() and rol = 'administrador'))
    or (usuario_id = (select auth.uid()) and
      (select exists (select 1 from public.usuarios
        where id = auth.uid() and rol = 'usuario')))
  );
-- Sin DELETE para clientes API: archivar con activo=false.

-- Backfill único, antes del trigger de validación de direcciones nuevas.
-- Preserva literalmente el texto. Ciudad solo con coincidencia exacta
-- normalizada e inequívoca; no usa historial ni usuarios_externos.
insert into public.direcciones_usuario(usuario_id, tipo, nombre, direccion, ciudad_id)
select u.id, 'otra', 'Dirección anterior', u.direccion,
       (select case when count(*) = 1 then (array_agg(c.id))[1] end
        from public.ciudades c
        where lower(btrim(c.nombre)) = lower(btrim(u.ciudad)))
from public.usuarios u
where u.rol = 'usuario' and nullif(btrim(u.direccion), '') is not null;

create function public.validar_direccion_usuario()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id or new.usuario_id is distinct from old.usuario_id then
      raise exception 'No se puede cambiar el propietario ni el ID de una dirección'
        using errcode = '23514';
    end if;
    new.creado_en := old.creado_en;
  end if;
  if tg_op = 'INSERT' then
    if not exists (select 1 from public.usuarios where id = new.usuario_id and rol = 'usuario') then
      raise exception 'La dirección debe pertenecer a un cliente existente' using errcode = '23514';
    end if;
  end if;
  -- Una dirección legacy incompleta puede archivarse sin alterar su texto.
  if tg_op = 'INSERT' then
    if not exists (select 1 from public.ciudades where id = new.ciudad_id and activo) then
      raise exception 'Selecciona una ciudad activa' using errcode = '23514';
    end if;
    new.creado_en := now();
  elsif row(new.direccion,new.complemento,new.referencia,new.ciudad_id,new.latitud,new.longitud)
    is distinct from row(old.direccion,old.complemento,old.referencia,old.ciudad_id,old.latitud,old.longitud)
    or (new.activo and not old.activo) then
    if not exists (select 1 from public.ciudades where id = new.ciudad_id and activo) then
      raise exception 'Selecciona una ciudad activa' using errcode = '23514';
    end if;
  end if;
  new.actualizado_en := now();
  return new;
end;
$$;
revoke all on function public.validar_direccion_usuario() from public, anon, authenticated, service_role;
create trigger direcciones_usuario_validar
  before insert or update on public.direcciones_usuario
  for each row execute function public.validar_direccion_usuario();

alter table public.solicitudes_servicio add column direccion_usuario_id uuid;
alter table public.solicitudes_servicio
  add constraint solicitudes_direccion_propietario_fkey
  foreign key (direccion_usuario_id, usuario_id)
  references public.direcciones_usuario(id, usuario_id)
  on delete set null (direccion_usuario_id);
create index solicitudes_direccion_propietario_idx
  on public.solicitudes_servicio(direccion_usuario_id, usuario_id)
  where direccion_usuario_id is not null;
comment on column public.solicitudes_servicio.direccion_usuario_id is
  'Origen opcional. Ubicacion, ciudad y coordenadas de la solicitud conservan la copia histórica.';

-- Cuerpo desplegado en test, con una sola modificación: desvincular
-- direccion_usuario_id al reasignar a la identidad de anonimización.
CREATE OR REPLACE FUNCTION public.eliminar_mi_cuenta()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  c_lapida        constant uuid := '00000000-0000-0000-0000-000000000000';
  v_uid           uuid := auth.uid();
  v_email         text;
  v_rol           text;
  v_solicitudes   int := 0;
  v_transacciones int := 0;
  v_recibos       int := 0;
  v_perfil        int := 0;
begin
  -- Sin parametros a proposito: el usuario sale de auth.uid(), asi que es
  -- imposible pedir el borrado de la cuenta de otra persona.
  if v_uid is null then
    raise exception 'No hay sesion activa' using errcode = '28000';
  end if;

  -- Sin esto, un token con ese uuid vaciaria el historial de todos.
  if v_uid = c_lapida then
    raise exception 'La cuenta lapida no se puede eliminar' using errcode = '42501';
  end if;

  select rol into v_rol from public.usuarios where id = v_uid;
  select email into v_email from auth.users where id = v_uid;

  -- =========================================================================
  -- A. REASIGNAR A LA LAPIDA
  --    Va primero: en cuanto se borre la fila de usuarios, estas cascadas se
  --    disparan. Lo que aqui no se salve, se pierde.
  -- =========================================================================

  -- Lado CLIENTE: usuario_id es NOT NULL y CASCADE, asi que o va a la lapida
  -- o la solicitud entera se destruye con sus recibos, pagos y resenas.
  -- Cambiar solo esta columna no despierta al trigger de abajo, que se fija
  -- unicamente en profesional_id.
  update public.solicitudes_servicio
     set usuario_id = c_lapida,
         direccion_usuario_id = null
   where usuario_id = v_uid;
  get diagnostics v_solicitudes = row_count;

  -- Lado PROVEEDOR: aqui va NULL, no la lapida, y es a proposito.
  --
  -- trigger_crear_chat_al_asignar_proveedor corre AFTER UPDATE y, cuando el
  -- profesional cambia a un valor NO NULO, borra todos los mensajes del chat.
  -- Si ese chat tiene un recibo asociado (recibos.mensaje_id), el DELETE choca
  -- contra recibos_mensaje_id_fkey y aborta el borrado de cuenta entero.
  -- Poniendo NULL la condicion del trigger no se cumple y no se dispara.
  --
  -- Ademas es lo semanticamente correcto: profesional_id nulo significa "sin
  -- asignar", asi que los trabajos aun activos vuelven al pool. La identidad
  -- de quien presto el servicio no se pierde: queda en recibos.proveedor_id,
  -- que si apunta a la lapida.
  update public.solicitudes_servicio
     set profesional_id = null
   where profesional_id = v_uid;

  -- Pagos. transacciones.usuario_id es NO ACTION y NOT NULL: si queda una
  -- sola fila apuntando al usuario, el DELETE final aborta la transaccion
  -- entera.
  update public.transacciones
     set usuario_id = c_lapida
   where usuario_id = v_uid;
  get diagnostics v_transacciones = row_count;

  -- Recibos emitidos como proveedor: son el comprobante del CLIENTE.
  update public.recibos
     set proveedor_id = c_lapida
   where proveedor_id = v_uid;
  get diagnostics v_recibos = row_count;

  -- Reputacion: la resena escrita le sirve al proveedor, y la recibida le
  -- sirve al cliente. Se conservan sin autor identificable.
  update public.resenas       set usuario_id   = c_lapida where usuario_id   = v_uid;
  update public.resenas       set proveedor_id = c_lapida where proveedor_id = v_uid;
  update public.calificaciones set usuario_id   = c_lapida where usuario_id   = v_uid;
  update public.calificaciones set proveedor_id = c_lapida where proveedor_id = v_uid;

  -- Los mensajes se quedan para que la contraparte conserve el hilo legible.
  update public.mensajes_chat
     set remitente_id = c_lapida
   where remitente_id = v_uid;

  -- =========================================================================
  -- B. ANONIMIZAR TICKETS DE SOPORTE
  --    Guardan nombre, telefono y email en texto plano. id_proveedor es TEXT
  --    y sin FK; del cliente no hay id, solo el email.
  -- =========================================================================
  update public.soporte
     set nombre_proveedor   = 'Cuenta eliminada',
         telefono_proveedor = null,
         email_proveedor    = null
   where id_proveedor = v_uid::text;

  if v_email is not null then
    update public.soporte
       set nombre_usuario   = 'Cuenta eliminada',
           telefono_usuario = null,
           email_usuario    = null
     where email_usuario = v_email;
  end if;

  -- =========================================================================
  -- C. BORRAR LO EXCLUSIVAMENTE PERSONAL
  --    Casi todas tienen ON DELETE CASCADE, pero se listan explicitamente
  --    para que el borrado no dependa de que nadie afloje una FK mas adelante.
  --    conversaciones NO tiene FK: aqui es imprescindible.
  -- =========================================================================
  delete from public.tarjetas_guardadas    where usuario_id = v_uid;
  delete from public.metodos_pago          where usuario_id = v_uid;
  delete from public.cuentas_bancarias     where usuario_id = v_uid;
  delete from public.certificaciones       where usuario_id = v_uid;
  delete from public.referencias_laborales where usuario_id = v_uid;
  delete from public.profesional_servicios where usuario_id = v_uid;
  delete from public.favoritos             where usuario_id = v_uid;
  delete from public.conversaciones        where usuario_id = v_uid;
  delete from public.cleanup_programado    where usuario_id = v_uid;
  delete from public.user_notifications    where user_id    = v_uid;

  delete from public.notificaciones
   where usuario_id = v_uid or proveedor_id = v_uid;

  -- usuarios_externos.id es el uuid de auth; id_usuario es un bigint de
  -- secuencia, NO comparar contra un uuid.
  delete from public.usuarios_externos where id = v_uid;

  delete from public.usuarios where id = v_uid;
  get diagnostics v_perfil = row_count;

  -- =========================================================================
  -- D. Cuenta de autenticacion, al final: una vez borrada, auth.uid() deja de
  --    resolver dentro de esta misma transaccion.
  -- =========================================================================
  delete from auth.users where id = v_uid;

  return json_build_object(
    'ok', true,
    'uid', v_uid,
    'rol', v_rol,
    'perfil_borrado', v_perfil > 0,
    'solicitudes_preservadas', v_solicitudes,
    'transacciones_preservadas', v_transacciones,
    'recibos_preservados', v_recibos
  );
end;
$function$


-- Añadir columna al final: conserva orden, contratos y ACL de la vista existente.
-- Sin JOIN a direcciones; ubicación histórica sigue siendo ss.ubicacion.
create or replace view public.vw_solicitudes_servicios_completa as
 SELECT ss.id AS solicitud_id,
    ss.ticket,
    ss.usuario_id,
    ss.descripcion AS solicitud_descripcion,
    ss.informacion_adicional,
    ss.ubicacion,
    ss.fecha,
    ss.hora,
    ss.precio AS precio_solicitud,
    ss.precio_base,
    ss.precio_adicionales,
    COALESCE(ss.precio_base, ss.precio, 0::numeric) + COALESCE(ss.precio_adicionales, 0::numeric) AS precio_total,
    COALESCE(ss.precio_base, ss.precio, s.precio, 0::numeric) + COALESCE(ss.precio_adicionales, 0::numeric) AS precio_calculado,
    ss.estado AS estado_solicitud,
    ss.estado_pago,
    ss.creado_en AS solicitud_creada_en,
    u_cliente.id_usuario AS cliente_id_usuario,
    u_cliente.nombres AS cliente_nombres,
    u_cliente.apellidos AS cliente_apellidos,
    concat(u_cliente.nombres, ' ', u_cliente.apellidos) AS cliente_nombre_completo,
    u_cliente.telefono AS cliente_telefono,
    u_cliente.correo_electronico AS cliente_correo,
    u_cliente.direccion AS cliente_direccion,
    u_cliente.foto_perfil_url AS cliente_foto_perfil,
    ss.servicio_id,
    COALESCE(s.nombre, ss.servicio_nombre) AS servicio_nombre,
    s.descripcion AS servicio_descripcion,
    s.precio AS servicio_precio_base,
    s.estado AS servicio_estado,
    s.informacion_relevante AS servicio_informacion_relevante,
    s.fotos AS servicio_fotos,
    s.items AS servicio_items,
    ss.profesional_id,
    u_proveedor.id_usuario AS proveedor_id_usuario,
    u_proveedor.nombres AS proveedor_nombres,
    u_proveedor.apellidos AS proveedor_apellidos,
    concat(u_proveedor.nombres, ' ', u_proveedor.apellidos) AS proveedor_nombre_completo,
    u_proveedor.telefono AS proveedor_telefono,
    u_proveedor.correo_electronico AS proveedor_correo,
    u_proveedor.direccion AS proveedor_direccion,
    u_proveedor.foto_perfil_url AS proveedor_foto_perfil,
    u_proveedor.anios_experiencia AS proveedor_experiencia,
    u_proveedor.registro_tributario AS proveedor_registro_tributario,
    u_proveedor.verificado AS proveedor_verificado,
    u_proveedor.disponibilidad AS proveedor_disponible,
    sub.id AS subcategoria_id,
    sub.nombre AS subcategoria_nombre,
    sub.descripcion AS subcategoria_descripcion,
    cat.id AS categoria_id,
    cat.nombre AS categoria_nombre,
    cat.imagen_url AS categoria_imagen,
    r_solicitud.calificacion AS puntuacion,
    ( SELECT avg(r.calificacion) AS avg
           FROM resenas r
          WHERE r.proveedor_id = ss.profesional_id) AS proveedor_calificacion_promedio,
    ( SELECT count(*) AS count
           FROM resenas r
          WHERE r.proveedor_id = ss.profesional_id) AS proveedor_total_resenas,
    ( SELECT count(*) AS count
           FROM solicitudes_servicio ss2
          WHERE ss2.profesional_id = ss.profesional_id AND ss2.estado = 'completado'::text) AS proveedor_servicios_completados,
    c.nombre AS solicitud_ciudad,
    ss.latitud,
    ss.longitud,
    ss.direccion_usuario_id
   FROM solicitudes_servicio ss
     LEFT JOIN usuarios u_cliente ON ss.usuario_id = u_cliente.id
     LEFT JOIN usuarios u_proveedor ON ss.profesional_id = u_proveedor.id
     LEFT JOIN servicios s ON ss.servicio_id = s.id
     LEFT JOIN subcategorias sub ON s.subcategoria_id = sub.id
     LEFT JOIN categorias cat ON sub.categoria_id = cat.id
     LEFT JOIN resenas r_solicitud ON r_solicitud.solicitud_servicio_id = ss.id
     LEFT JOIN ciudades c ON c.id = ss.ciudad_id
  WHERE ss.servicio_id IS NOT NULL
  ORDER BY ss.creado_en DESC;

commit;
