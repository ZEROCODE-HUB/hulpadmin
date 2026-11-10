-- PREPARADO, NO EJECUTADO. Requiere 01. RPC SOLO service_role.
begin;
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
commit;
