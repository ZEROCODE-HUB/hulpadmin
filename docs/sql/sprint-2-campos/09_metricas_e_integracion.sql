begin;
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $$;
-- Triggers existentes invocados desde los RPC con search_path vacío.
alter function public.actualizar_mensaje_estado_recibo() set search_path=pg_catalog,public;
alter function public.actualizar_precio_solicitud_recibo() set search_path=pg_catalog,public;
alter function public.calcular_total_recibo() set search_path=pg_catalog,public;
alter function public.crear_mensaje_recibo() set search_path=pg_catalog,public;

create function public.solicitud_metricas_periodo_v1(p_inicio timestamptz,p_fin timestamptz)
returns jsonb language sql set search_path='' as $$
 select jsonb_build_object(
  'cobros_confirmados',coalesce((select sum(t.monto) from public.transacciones t
   join public.solicitudes_servicio s on s.id=t.solicitud_id where s.finanzas_version=1
   and t.fecha_pago between p_inicio and p_fin),0),
  'comision_neta',coalesce((select sum(comision_neta_hulp) from public.solicitudes_servicio
   where finanzas_version=1 and estado_pago='pagado' and fecha_pago between p_inicio and p_fin),0),
  'iva',coalesce((select sum(iva_valor) from public.solicitudes_servicio
   where finanzas_version=1 and estado_pago='pagado' and fecha_pago between p_inicio and p_fin),0));
$$;
revoke all on function public.solicitud_metricas_periodo_v1(timestamptz,timestamptz) from public,anon,authenticated;
grant execute on function public.solicitud_metricas_periodo_v1(timestamptz,timestamptz) to service_role;

-- Mantener el resto de las métricas y cada expresión histórica literalmente.
do $$ declare v text; begin
 v:=pg_get_viewdef('public.vw_dashboard_metricas'::regclass,true);
 if v not like '%THEN ss.precio%' then raise exception 'Métricas Admin cambiaron'; end if;
 v:=replace(v,'THEN ss.precio','THEN CASE WHEN ss.finanzas_version IS NULL THEN ss.precio WHEN ss.finanzas_version=1 AND ss.estado_pago=''pagado'' THEN ss.comision_neta_hulp ELSE 0::numeric END');
 execute 'create or replace view public.vw_dashboard_metricas as '||v;
 v:=pg_get_viewdef('public.vw_metricas_proveedores'::regclass,true);
 if v not like '%sum(solicitudes_servicio.precio)%' then raise exception 'Métricas Talentos cambiaron'; end if;
 v:=replace(v,'sum(solicitudes_servicio.precio)',
  'sum(CASE WHEN solicitudes_servicio.finanzas_version IS NULL THEN solicitudes_servicio.precio WHEN solicitudes_servicio.finanzas_version=1 THEN solicitudes_servicio.pago_proveedor END)');
 execute 'create or replace view public.vw_metricas_proveedores as '||v;
end $$;

-- El detalle aceptado y pagado es inmutable. Los cambios pendientes siguen
-- permitidos; no se modifica ninguna política RLS de recibos ni otros módulos.
create function hulp_finanzas.proteger_recibo_items_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare rc public.recibos; v integer;
begin
 select r.* into rc from public.recibos r where r.id=case when tg_op='DELETE' then old.recibo_id else new.recibo_id end;
 select finanzas_version into v from public.solicitudes_servicio where id=rc.solicitud_id for update;
 if v=1 and rc.estado='aceptado' then raise exception 'No modificar el detalle de un recibo aceptado'; end if;
 if tg_op='UPDATE' and new.recibo_id<>old.recibo_id then raise exception 'No cambiar el recibo del ítem'; end if;
 return case when tg_op='DELETE' then old else new end;
end $$;
create trigger sprint2_recibo_items_proteger before insert or update or delete on public.recibo_items
 for each row execute function hulp_finanzas.proteger_recibo_items_v1();

create function hulp_finanzas.proteger_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare v integer; cliente uuid; rol text;
begin
 select finanzas_version,usuario_id into v,cliente from public.solicitudes_servicio where id=new.solicitud_id for update;
 if v is distinct from 1 then return new; end if;
 if new.solicitud_id<>old.solicitud_id then raise exception 'No cambiar la solicitud del recibo'; end if;
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
create trigger sprint2_recibo_proteger before update on public.recibos
 for each row execute function hulp_finanzas.proteger_recibo_v1();
revoke all on function hulp_finanzas.proteger_recibo_items_v1(),hulp_finanzas.proteger_recibo_v1()
 from public,anon,authenticated,service_role;
commit;
