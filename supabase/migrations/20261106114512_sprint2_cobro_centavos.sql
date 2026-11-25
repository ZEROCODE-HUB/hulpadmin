begin;
set local hulp.target_ref='ptafsiwlhxomgqmdmidf';
do $$ begin if current_setting('hulp.target_ref',true)<>'ptafsiwlhxomgqmdmidf' then raise exception 'Solo test'; end if; end $$;
create or replace function public.solicitud_cobro_preparar_v1(p_actor uuid,p_id uuid,p_recibo uuid,
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
 if p_centavos is not null and p_centavos<>(r->>'centavos')::numeric::bigint then raise exception 'El importe cambió. Confirma el pago nuevamente' using errcode='40001'; end if;
 if (r->>'centavos')::numeric<150000 then raise exception 'El monto mínimo de pago es $1.500 COP.'; end if;
 select rol into rol_actor from public.usuarios where id=p_actor;
 insert into public.intentos_cobro(id,solicitud_id,recibo_id,ticket,usuario_id,rol_solicitante,
  metodo,monto_centavos,resultado,detalle)
 values(intento,p_id,p_recibo,s.ticket,p_actor,rol_actor,case when p_tarjeta then 'CARD' else 'OTRO' end,
  (r->>'centavos')::numeric::bigint,'pendiente',jsonb_build_object('finanzas_revision',s.finanzas_revision));
 return r || jsonb_build_object('intento_id',intento);
end $$;
notify pgrst,'reload schema';
commit;
