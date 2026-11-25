-- Hulp/test: eliminar únicamente el concepto del adelanto.
-- Conserva solicitudes, importes, motivos, políticas, ACL y JSON históricos.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

CREATE OR REPLACE FUNCTION hulp_finanzas.guardar_v1(p_id uuid, p_revision bigint, p_actor uuid, p_entradas jsonb, p_items jsonb, p_motivo text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
   'adelanto_motivo','aplica_wompi','aplica_ajuste_iva','requiere_fe')) then
  raise exception 'Campo financiero no permitido';
 end if;
 if (p_entradas->>'precio')::numeric is distinct from (p_entradas->>'precio_base')::numeric
 and nullif(btrim(p_entradas->>'motivo_precio_pagado'),'') is null then
  raise exception 'Motivo obligatorio cuando precio y lista difieren';
 end if;
 if coalesce((p_entradas->>'adelanto_proveedor')::numeric,0)>0 and
 nullif(btrim(p_entradas->>'adelanto_motivo'),'') is null then
  raise exception 'Adelanto requiere motivo';
 end if;
 -- Con pagos, preservar el precio/recargos ya acordados y los renglones cobrados.
 -- Se permite incorporar nuevos materiales pendientes, sin deshacer cobros.
 if exists(select 1 from public.transacciones t where t.solicitud_id=p_id) then
  if (p_entradas->>'aplica_wompi')::boolean is distinct from s.aplica_wompi then
   raise exception 'No cambiar el recargo con pagos confirmados; requiere ajuste';
  end if;
  if exists(select 1 from public.transacciones t where t.solicitud_id=p_id and
   (t.recibo_id is null or exists(select 1 from public.recibo_items ri
    where ri.recibo_id=t.recibo_id and ri.tipo_item='mano_obra')))
   and row((p_entradas->>'precio_base')::numeric,(p_entradas->>'precio')::numeric,
     (p_entradas->>'aplica_ajuste_iva')::boolean)
    is distinct from row(s.precio_base,s.precio,s.aplica_ajuste_iva) then
   raise exception 'Mano de obra ya cobrada: modificarla requiere un ajuste';
  end if;
  if exists(select 1 from public.solicitud_items si join public.recibo_items ri on ri.id=si.recibo_item_id
    join public.transacciones t on t.recibo_id=ri.recibo_id where si.solicitud_id=p_id
    and not exists(select 1 from jsonb_array_elements(p_items) AS detalle(value) where
      detalle.value->>'recibo_item_id'=si.recibo_item_id::text and (detalle.value->>'cantidad')::numeric=si.cantidad
      and (detalle.value->>'precio_unitario')::numeric=si.precio_unitario)) then
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
    or lower(recibo.tipo_item) is distinct from x->>'tipo_item'
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
 if s.estado_pago='pagado' and (r->>'total_cliente')::numeric is distinct from s.total_cliente then
  raise exception 'Solicitud liquidada: cambiar el total requiere un flujo de ajuste o devolución';
 end if;
 if (r->>'total_cliente')::numeric < (select coalesce(sum(monto),0) from public.transacciones where solicitud_id=p_id) then
  raise exception 'Total menor que los pagos confirmados';
 end if;
 update public.solicitudes_servicio set precio_base=(p_entradas->>'precio_base')::numeric,
  precio=(p_entradas->>'precio')::numeric,motivo_precio_pagado=p_entradas->>'motivo_precio_pagado',
  adelanto_proveedor=coalesce((p_entradas->>'adelanto_proveedor')::numeric,0),
  adelanto_motivo=p_entradas->>'adelanto_motivo',
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
end $function$;

CREATE OR REPLACE FUNCTION hulp_finanzas.proteger_solicitud()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare trusted boolean:=current_user in ('postgres','service_role'); activo boolean;
begin
 -- SECURITY INVOKER: lectura config solo requerida por INSERT de backend;
 -- clientes directos se rechazan al activar mediante 05.
 if tg_op='INSERT' then
  if not trusted then raise exception 'Crear mediante el backend financiero validado' using errcode='42501'; end if;
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
  new.motivo_precio_pagado,new.adelanto_proveedor,new.adelanto_motivo,
  new.aplica_wompi,new.aplica_ajuste_iva,new.requiere_fe,new.informacion_adicional,new.notas_cliente,
  new.materiales_total,new.pago_proveedor,new.saldo_transferir,new.comision_base,
  new.ajuste_iva_valor,new.comision_hulp_iva,new.comision_neta_hulp,new.iva_valor,
  new.comision_efectiva,new.wompi_valor,new.total_cliente,new.finanzas_revision,new.finanzas_calculadas_en)
  is distinct from row(old.precio,old.precio_base,old.precio_adicionales,old.estado_pago,
  old.motivo_precio_pagado,old.adelanto_proveedor,old.adelanto_motivo,
  old.aplica_wompi,old.aplica_ajuste_iva,old.requiere_fe,old.informacion_adicional,old.notas_cliente,
  old.materiales_total,old.pago_proveedor,old.saldo_transferir,old.comision_base,
  old.ajuste_iva_valor,old.comision_hulp_iva,old.comision_neta_hulp,old.iva_valor,
  old.comision_efectiva,old.wompi_valor,old.total_cliente,old.finanzas_revision,old.finanzas_calculadas_en) then
  raise exception 'Finanzas/notas privadas solo mediante backend validado' using errcode='42501';
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.solicitud_cobro_preparar_v1(p_actor uuid, p_id uuid, p_recibo uuid, p_tarjeta boolean, p_revision bigint, p_centavos bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; r jsonb; intento uuid:=gen_random_uuid(); rol_actor text;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
 if p_revision is not null and p_revision<>s.finanzas_revision then raise exception 'La solicitud cambió. Confirma el importe nuevamente' using errcode='40001'; end if;
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
   'adelanto_motivo',s.adelanto_motivo,
   'aplica_wompi',p_tarjeta,'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
  perform hulp_finanzas.guardar_v1(p_id,s.finanzas_revision,null,entradas,items,'Método verificado de cobro');
  select * into s from public.solicitudes_servicio where id=p_id;
 end if;
 if p_recibo is null then
  r:=public.solicitud_importe_cobro(p_actor,p_id,s.finanzas_revision);
 else
  r:=public.solicitud_recibo_importe_cobro_v1(p_actor,p_id,s.finanzas_revision,p_recibo);
 end if;
 if p_centavos is not null and p_centavos<>(r->>'centavos')::numeric::bigint then raise exception 'El importe cambió. Confirma el pago nuevamente' using errcode='40001'; end if;
 if (r->>'centavos')::numeric<150000 then raise exception 'El monto mínimo de pago es $1.500 COP.'; end if;
 select rol into rol_actor from public.usuarios where id=p_actor;
 insert into public.intentos_cobro(id,solicitud_id,recibo_id,ticket,usuario_id,rol_solicitante,
  metodo,monto_centavos,resultado,detalle)
 values(intento,p_id,p_recibo,s.ticket,p_actor,rol_actor,case when p_tarjeta then 'CARD' else 'OTRO' end,
  (r->>'centavos')::numeric::bigint,'pendiente',jsonb_build_object('finanzas_revision',s.finanzas_revision));
 return r || jsonb_build_object('intento_id',intento);
end $function$;

CREATE OR REPLACE FUNCTION hulp_finanzas.sincronizar_recibo_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; labor numeric;
begin
 select * into s from public.solicitudes_servicio where id=new.solicitud_id for update;
 if s.finanzas_version is distinct from 1 then return new; end if;
 if new.estado is distinct from 'aceptado' then return new; end if;
 if tg_op='UPDATE' and old.estado='aceptado' then return new; end if;
 select sum(cantidad*precio_unitario) into labor from public.recibo_items
 where recibo_id=new.id and tipo_item='mano_obra';

 select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',descripcion,
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',recibo_item_id) order by orden,id),'[]')
 into items from public.solicitud_items where solicitud_id=s.id and (tipo_item<>'mano_obra' or labor is null);
 select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',coalesce(descripcion,'Material'),
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',id)),'[]') || items
 into items from public.recibo_items where recibo_id=new.id
 and id not in(select recibo_item_id from public.solicitud_items where recibo_item_id is not null);
 entradas:=jsonb_build_object('precio_base',coalesce(labor,s.precio_base),
  'precio',coalesce(labor,s.precio),'motivo_precio_pagado',s.motivo_precio_pagado,
  'adelanto_proveedor',s.adelanto_proveedor,
  'adelanto_motivo',s.adelanto_motivo,'aplica_wompi',s.aplica_wompi,
  'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
 perform hulp_finanzas.guardar_v1(s.id,s.finanzas_revision,null,entradas,items,'Recibo aceptado');
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.solicitud_pago_qr_v1(p_actor uuid, p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; importe jsonb;
begin
 if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
  raise exception 'Solo Admin confirma pago directo' using errcode='42501';
 end if;
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
 if s.estado_pago='pagado' then return jsonb_build_object('existente',true); end if;
 if exists(select 1 from public.intentos_cobro where solicitud_id=p_id and resultado='pendiente'
  and detalle ? 'finanzas_revision') then raise exception 'Consultar el cobro pendiente antes de confirmar otro pago'; end if;
 if s.aplica_wompi then
  select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',descripcion,
   'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',recibo_item_id) order by orden,id),'[]')
   into items from public.solicitud_items where solicitud_id=p_id;
  entradas:=jsonb_build_object('precio_base',s.precio_base,'precio',s.precio,
   'motivo_precio_pagado',s.motivo_precio_pagado,'adelanto_proveedor',s.adelanto_proveedor,
   'adelanto_motivo',s.adelanto_motivo,
   'aplica_wompi',false,'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
  perform hulp_finanzas.guardar_v1(p_id,s.finanzas_revision,p_actor,entradas,items,'Pago directo sin recargo');
  select * into s from public.solicitudes_servicio where id=p_id;
 end if;
 importe:=public.solicitud_importe_cobro(p_actor,p_id,s.finanzas_revision);
 return public.solicitud_pago_confirmar_v1(p_actor,p_id,s.finanzas_revision,p_id,null,
  (importe->>'monto')::numeric,'QR','QR');
end $function$;

-- PostgreSQL no permite quitar una columna mediante CREATE OR REPLACE VIEW.
-- Sin CASCADE: cualquier dependencia inesperada cancela toda la transacción.
drop view public.vw_solicitudes_servicios_completa;
create view public.vw_solicitudes_servicios_completa as
SELECT ss.id AS solicitud_id,
    ss.ticket,
    ss.usuario_id,
    ss.descripcion AS solicitud_descripcion,
        CASE
            WHEN (CURRENT_USER = ANY (ARRAY['postgres'::name, 'service_role'::name])) OR (EXISTS ( SELECT 1
               FROM usuarios operador
              WHERE operador.id = auth.uid() AND operador.rol = 'administrador'::text)) THEN ss.informacion_adicional
            ELSE NULL::text
        END AS informacion_adicional,
    ss.ubicacion,
    ss.fecha,
    ss.hora,
    ss.precio AS precio_solicitud,
    ss.precio_base,
    ss.precio_adicionales,
        CASE
            WHEN ss.finanzas_version IS NULL THEN COALESCE(ss.precio_base, ss.precio, 0::numeric) + COALESCE(ss.precio_adicionales, 0::numeric)
            WHEN ss.finanzas_version = 1 THEN ss.total_cliente
            ELSE NULL::numeric
        END AS precio_total,
        CASE
            WHEN ss.finanzas_version IS NULL THEN COALESCE(ss.precio_base, ss.precio, s.precio, 0::numeric) + COALESCE(ss.precio_adicionales, 0::numeric)
            WHEN ss.finanzas_version = 1 THEN ss.total_cliente
            ELSE NULL::numeric
        END AS precio_calculado,
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
    ss.direccion_usuario_id,
    ss.finanzas_version,
    ss.finanzas_revision,
    ss.finanzas_calculadas_en,
        CASE
            WHEN (CURRENT_USER = ANY (ARRAY['postgres'::name, 'service_role'::name])) OR ss.usuario_id = auth.uid() OR (EXISTS ( SELECT 1
               FROM usuarios operador
              WHERE operador.id = auth.uid() AND operador.rol = 'administrador'::text)) THEN ss.notas_cliente
            ELSE NULL::text
        END AS notas_cliente,
    ss.motivo_precio_pagado,
    ss.adelanto_proveedor,
    ss.adelanto_motivo,
    ss.aplica_wompi,
    ss.aplica_ajuste_iva,
    ss.requiere_fe,
    ss.materiales_total,
    ss.pago_proveedor,
    ss.saldo_transferir,
    ss.comision_base,
    ss.ajuste_iva_valor,
    ss.comision_hulp_iva,
    ss.comision_neta_hulp,
    ss.iva_valor,
    ss.comision_efectiva,
    ss.wompi_valor,
    ss.total_cliente
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
alter view public.vw_solicitudes_servicios_completa owner to postgres;
-- Los mismos permisos que tenía la vista desplegada antes de este cambio.
grant all on public.vw_solicitudes_servicios_completa to anon, authenticated, service_role;

alter table public.solicitudes_servicio drop column adelanto_concepto;
notify pgrst, 'reload schema';
commit;
