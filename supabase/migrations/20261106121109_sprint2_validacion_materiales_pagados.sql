begin;
set local hulp.target_ref='ptafsiwlhxomgqmdmidf';
do $$ begin if current_setting('hulp.target_ref',true)<>'ptafsiwlhxomgqmdmidf' then raise exception 'Solo test'; end if; end $$;
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

notify pgrst,'reload schema';
commit;
