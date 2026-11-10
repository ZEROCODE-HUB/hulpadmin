-- PREPARADO, NO EJECUTADO. Ejecutar solo tras revisar 00 y adaptar consumidores.
begin;
do $$
declare v text; expresion text; n integer;
begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
 v:=pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass,true);
 -- Conservar exactamente las expresiones anteriores en la rama NULL.
 -- Aborta si la vista remota ya no coincide con los aliases documentados.
 foreach expresion in array array['precio_total','precio_calculado'] loop
  if v !~* ('COALESCE\(ss\.precio_base[^;]+? AS '||expresion) then
   raise exception 'Revisar expresión remota de % antes de reemplazar',expresion;
  end if;
  v:=regexp_replace(v,
   '(COALESCE\(ss\.precio_base[^\n]+?)( AS '||expresion||')',
   'CASE WHEN ss.finanzas_version IS NULL THEN \1 WHEN ss.finanzas_version = 1 THEN ss.total_cliente ELSE NULL::numeric END\2','i');
 end loop;
 if v !~ 'CASE WHEN ss.finanzas_version IS NULL' then raise exception 'No se transformó la vista'; end if;
 -- Agregar columnas únicamente al final; no romper el orden/tipos anteriores.
 -- La expresión se inserta antes de FROM solicitudes_servicio, sin DROP VIEW.
 v:=regexp_replace(v,'(\sFROM (?:public\.)?solicitudes_servicio ss)(\s)',
  ', ss.finanzas_version, ss.finanzas_revision, ss.finanzas_calculadas_en, ss.notas_cliente,'||
  ' ss.motivo_precio_pagado, ss.adelanto_proveedor, ss.adelanto_concepto, ss.adelanto_motivo,'||
  ' ss.aplica_wompi, ss.aplica_ajuste_iva, ss.requiere_fe, ss.materiales_total,'||
  ' ss.pago_proveedor, ss.saldo_transferir, ss.comision_base, ss.ajuste_iva_valor,'||
  ' ss.comision_hulp_iva, ss.comision_neta_hulp, ss.iva_valor, ss.comision_efectiva,'||
  ' ss.wompi_valor, ss.total_cliente \1\2','i');
 if v !~ 'ss.total_cliente\s+FROM' then raise exception 'No se agregaron columnas; revisar vista'; end if;
 execute 'create or replace view public.vw_solicitudes_servicios_completa as '||v;
end $$;

create function public.solicitud_finanzas_leer(p_actor uuid,p_id uuid) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; rol_actor text; r jsonb; items jsonb;
begin
 select u.rol into rol_actor from public.usuarios u where u.id=p_actor;
 select * into s from public.solicitudes_servicio where id=p_id;
 if s.id is null then raise exception 'Solicitud inexistente'; end if;
 if rol_actor is distinct from 'administrador' and s.usuario_id is distinct from p_actor
  and s.profesional_id is distinct from p_actor then
  raise exception 'Acceso no autorizado' using errcode='42501';
 end if;
 if s.finanzas_version is not null and s.finanzas_version<>1 then raise exception 'Versión no soportada'; end if;
 if s.finanzas_version=1 and s.total_cliente is null then raise exception 'Versión 1 incompleta'; end if;
 -- El backend puede conservar el mapa operativo anterior, pero debe evitar
 -- filtrar precio acordado o notas privadas a proveedoras.
 r:=jsonb_build_object('solicitud_id',s.id,'version',s.finanzas_version);
 if s.finanzas_version is null then
  r:=r||jsonb_build_object('precio_legacy',s.precio,'base_legacy',s.precio_base,
   'adicionales_legacy',s.precio_adicionales);
  -- Cada pantalla legacy conserva su fórmula; no unificarla con este RPC.
 else
  if rol_actor='proveedor' and s.profesional_id=p_actor then
   return r||jsonb_build_object('pago_proveedor',s.pago_proveedor,
    'saldo_transferir',s.saldo_transferir,'adelanto_proveedor',s.adelanto_proveedor,
    'descripcion',s.descripcion);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'tipo_item',i.tipo_item,
   'descripcion',i.descripcion,'cantidad',i.cantidad,'precio_unitario',i.precio_unitario,
   'total',i.total,'orden',i.orden,'recibo_item_id',i.recibo_item_id) order by i.orden,i.id),'[]'::jsonb)
   into items from public.solicitud_items i where i.solicitud_id=s.id;
  r:=r||jsonb_build_object('precio_base',s.precio_base,'precio',s.precio,
   'materiales_total',s.materiales_total,'wompi_valor',s.wompi_valor,
   'ajuste_iva_valor',s.ajuste_iva_valor,'total_cliente',s.total_cliente,'items',items,
   'revision',s.finanzas_revision,'requiere_fe',s.requiere_fe);
 end if;
 if rol_actor='administrador' then
  return r||jsonb_build_object('solicitud',to_jsonb(s));
 end if;
 -- Notas del cliente se permiten a su dueño; notas internas no se devuelven.
 if s.usuario_id=p_actor then r:=r||jsonb_build_object('notas_cliente',s.notas_cliente); end if;
 return r;
end $$;
revoke all on function public.solicitud_finanzas_leer(uuid,uuid) from public,anon,authenticated;
grant execute on function public.solicitud_finanzas_leer(uuid,uuid) to service_role;

-- Monto para firma/cobro de SOLICITUD; no devuelve centavos si hay fracciones
-- no representables. Esa decisión comercial sigue pendiente en el plan.
create function public.solicitud_importe_cobro(p_actor uuid,p_id uuid,p_revision bigint)
returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; monto numeric; pagado numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is null then
  monto:=coalesce(s.precio_base,s.precio,0)+coalesce(s.precio_adicionales,0);
  return jsonb_build_object('version',null,'monto',monto,'centavos',round(monto*100));
 end if;
 if p_revision is null or p_revision<>s.finanzas_revision then
  raise exception 'Revisión financiera obsoleta' using errcode='40001';
 end if;
 -- La versión es la de la solicitud, inmutable; no duplicarla en pagos.
 -- Solo se registran confirmaciones en transacciones. Los pagos de recibo
 -- (recibo_id no nulo) también reducen el saldo del servicio una sola vez.
 select coalesce(sum(t.monto),0) into pagado from public.transacciones t
 where t.solicitud_id=p_id;
 monto:=s.total_cliente-pagado;
 if monto<=0 then raise exception 'No hay saldo positivo que cobrar'; end if;
 monto:=round(monto,2);
 return jsonb_build_object('version',1,'revision',s.finanzas_revision,
  'monto',monto,'centavos',monto*100,'pagado',pagado);
end $$;
revoke all on function public.solicitud_importe_cobro(uuid,uuid,bigint) from public,anon,authenticated;
grant execute on function public.solicitud_importe_cobro(uuid,uuid,bigint) to service_role;
commit;

