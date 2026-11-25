-- Cerrar la ventana entre preparar importe y reservar el cobro.
begin;
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then raise exception 'Destino test no confirmado'; end if;
end $$;
drop function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean);
create function public.solicitud_cobro_preparar_v1(p_actor uuid,p_id uuid,p_recibo uuid,
 p_tarjeta boolean,p_revision bigint,p_centavos bigint) returns jsonb language plpgsql set search_path='' as $$
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
 if p_centavos is not null and p_centavos<>(r->>'centavos')::bigint then raise exception 'El importe cambió. Confirma el pago nuevamente' using errcode='40001'; end if;
 if (r->>'centavos')::numeric<150000 then raise exception 'El monto mínimo de pago es $1.500 COP.'; end if;
 select rol into rol_actor from public.usuarios where id=p_actor;
 insert into public.intentos_cobro(id,solicitud_id,recibo_id,ticket,usuario_id,rol_solicitante,
  metodo,monto_centavos,resultado,detalle)
 values(intento,p_id,p_recibo,s.ticket,p_actor,rol_actor,case when p_tarjeta then 'CARD' else 'OTRO' end,
  (r->>'centavos')::bigint,'pendiente',jsonb_build_object('finanzas_revision',s.finanzas_revision));
 return r || jsonb_build_object('intento_id',intento);
end $$;
drop function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid);
create function public.solicitud_pago_confirmar_v1(p_actor uuid,p_id uuid,p_revision bigint,
 p_transaccion uuid,p_numero text,p_monto numeric,p_metodo text,p_proveedor text,
 p_recibo uuid default null,p_datos jsonb default null,p_referencia text default null) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; t public.transacciones;
 pagado numeric; saldo numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
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
 if s.finanzas_version is distinct from 1 or p_revision is distinct from s.finanzas_revision then
  raise exception 'Versión o revisión financiera incorrecta' using errcode='40001';
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
  moneda,proveedor_pago,metodo_pago,fecha_pago,fecha_registro,recibo_id,datos_pago,referencia_externa)
 values(p_transaccion,p_id,s.usuario_id,nullif(btrim(p_numero),''),p_monto,'COP',
  p_proveedor,p_metodo,now(),now(),p_recibo,p_datos,p_referencia);
 -- Acreditar la solicitud solo cuando los pagos cubren su total.
 if round(pagado+p_monto,2)=round(s.total_cliente,2) then
  update public.solicitudes_servicio set estado_pago='pagado',fecha_pago=now() where id=p_id;
 end if;
 return jsonb_build_object('transaccion_id',p_transaccion,'existente',false,
  'pendiente',s.total_cliente-pagado-p_monto);
end $$;
revoke all on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean,bigint,bigint) from public,anon,authenticated;
grant execute on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean,bigint,bigint) to service_role;
create or replace function hulp_finanzas.guardar_v1(p_id uuid,p_revision bigint,p_actor uuid,
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

create or replace function hulp_finanzas.sincronizar_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
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
  'adelanto_proveedor',s.adelanto_proveedor,'adelanto_concepto',s.adelanto_concepto,
  'adelanto_motivo',s.adelanto_motivo,'aplica_wompi',s.aplica_wompi,
  'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
 perform hulp_finanzas.guardar_v1(s.id,s.finanzas_revision,null,entradas,items,'Recibo aceptado');
 return new;
end $$;
create or replace function hulp_finanzas.proteger_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare v integer; cliente uuid; rol text;
begin
 select finanzas_version,usuario_id into v,cliente from public.solicitudes_servicio where id=new.solicitud_id for update;
 if v is distinct from 1 then return new; end if;
 if new.solicitud_id<>old.solicitud_id then raise exception 'No cambiar la solicitud del recibo'; end if;
 -- eliminar_mi_cuenta conserva recibos y reasigna su proveedora al usuario eliminado.
 if (to_jsonb(new)-'proveedor_id')=(to_jsonb(old)-'proveedor_id')
  and exists(select 1 from public.usuarios where id=new.proveedor_id and rol='eliminado')
  and (auth.uid()=old.proveedor_id or coalesce(auth.role(),'service_role')='service_role') then return new; end if;
 if old.estado='aceptado' and (new.estado<>old.estado or new.total<>old.total or new.proveedor_id<>old.proveedor_id) then
  raise exception 'Recibo aceptado inmutable';
 end if;
 if new.estado='aceptado' and old.estado is distinct from new.estado and auth.role() in ('authenticated','anon') then
  select u.rol into rol from public.usuarios u where u.id=auth.uid();
  if auth.uid() is distinct from cliente and rol is distinct from 'administrador' then
   raise exception 'Solo el cliente o Admin puede aceptar';
  end if;
 end if;
 return new;
end $$;
revoke all on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid,jsonb,text) from public,anon,authenticated;
grant execute on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid,jsonb,text) to service_role;
commit;
