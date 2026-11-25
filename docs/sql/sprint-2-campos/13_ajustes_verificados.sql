begin;
set local hulp.target_ref='ptafsiwlhxomgqmdmidf';
do $$ begin if current_setting('hulp.target_ref',true)<>'ptafsiwlhxomgqmdmidf' then raise exception 'Solo test'; end if; end $$;
create or replace function hulp_finanzas.proteger_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare v integer; cliente uuid; rol text;
begin
 select finanzas_version,usuario_id into v,cliente from public.solicitudes_servicio where id=new.solicitud_id for update;
 if v is distinct from 1 then return new; end if;
 if new.solicitud_id<>old.solicitud_id then raise exception 'No cambiar la solicitud del recibo'; end if;
 -- eliminar_mi_cuenta conserva recibos y reasigna su proveedora al usuario eliminado.
 if (to_jsonb(new)-'proveedor_id')=(to_jsonb(old)-'proveedor_id')
  and exists(select 1 from public.usuarios eliminado where eliminado.id=new.proveedor_id and eliminado.rol='eliminado')
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
create or replace function public.solicitud_cobro_cotizar_v1(p_actor uuid,p_id uuid,p_recibo uuid,p_tarjeta boolean)
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
  select greatest((r->>'wompi_valor')::numeric-coalesce(sum(
   case when t.metodo_pago='CARD' then t.monto-anterior.total else 0 end),0),0)
  into recargo from public.transacciones t join public.recibos anterior on anterior.id=t.recibo_id
  where t.solicitud_id=p_id and not exists(select 1 from public.recibo_items ri
   where ri.recibo_id=anterior.id and ri.tipo_item='mano_obra');
  importe:=(r->>'total_cliente')::numeric-pagado;
 end if;
 return jsonb_build_object('version',1,'monto',round(importe,2),'recargo',round(recargo,2),
  'tarjeta',p_tarjeta,'revision',s.finanzas_revision,'pagado',importe<=0);
end $$;
notify pgrst,'reload schema';
commit;
