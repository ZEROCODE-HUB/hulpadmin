begin;
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then raise exception 'Destino test no confirmado'; end if;
end $$;
-- Solo lectura: mostrar el importe antes de aceptar/cobrar. No reservar cobros
-- ni cambiar recibos al abrir una pantalla.
create function public.solicitud_cobro_cotizar_v1(p_actor uuid,p_id uuid,p_recibo uuid,p_tarjeta boolean)
returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; rc public.recibos; l numeric; p numeric; m numeric;
 labor numeric; pagado numeric; r jsonb; importe numeric; recargo numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id;
 if p_recibo is not null then
  select * into rc from public.recibos where id=p_recibo and solicitud_id=p_id;
  if rc.id is null then raise exception 'Recibo ajeno o inexistente'; end if;
 end if;
 if s.finanzas_version is null then return jsonb_build_object('version',null,
  'monto',coalesce(rc.total,coalesce(s.precio_base,s.precio,0)+coalesce(s.precio_adicionales,0)),'recargo',0); end if;
 if exists(select 1 from public.transacciones where recibo_id=p_recibo) then
  return jsonb_build_object('version',1,'monto',0,'recargo',0,'pagado',true);
 end if;
 select coalesce(sum(monto),0) into pagado from public.transacciones where solicitud_id=p_id;
 l:=s.precio_base; p:=s.precio; m:=s.materiales_total;
 if p_recibo is not null then
  select sum(cantidad*precio_unitario) into labor from public.recibo_items where recibo_id=p_recibo and tipo_item='mano_obra';
  if labor is not null then l:=labor; p:=labor; end if;
  select m+coalesce(sum(ri.cantidad*ri.precio_unitario),0) into m from public.recibo_items ri
   where ri.recibo_id=p_recibo and ri.tipo_item='material'
   and not exists(select 1 from public.solicitud_items si where si.recibo_item_id=ri.id);
 end if;
 r:=hulp_finanzas.calcular_v1(l,p,m,s.adelanto_proveedor,p_tarjeta,s.aplica_ajuste_iva);
 if p_recibo is not null and labor is null then
  recargo:=case when p_tarjeta then rc.total*0.05 else 0 end;
  importe:=rc.total+recargo;
 else
  recargo:=(r->>'wompi_valor')::numeric;
  importe:=(r->>'total_cliente')::numeric-pagado;
 end if;
 return jsonb_build_object('version',1,'monto',round(importe,2),'recargo',round(recargo,2),
  'tarjeta',p_tarjeta,'revision',s.finanzas_revision,'pagado',importe<=0);
end $$;
revoke all on function public.solicitud_cobro_cotizar_v1(uuid,uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.solicitud_cobro_cotizar_v1(uuid,uuid,uuid,boolean) to service_role;
commit;
