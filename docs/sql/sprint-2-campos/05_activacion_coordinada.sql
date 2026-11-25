-- PREPARADO, NO EJECUTADO. NO aplicar hasta adaptar las tres apps y Wompi.
-- Conserva permisos operativos. Solo protege las notas y valida escrituras financieras.
-- Alcance 2026-11-06: reagendar_solicitud queda pendiente; su posible rechazo
-- tras activar se acepta y no es condición para ejecutar esta activación.
-- Sin cambios de políticas RLS de otras tablas ni auditoría general.
begin;
set local lock_timeout='5s';
do $$
declare cuerpo text; ddl text; existe boolean; firma text;
begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf'
 or current_setting('hulp.apps_finanzas_v1_listas',true) is distinct from 'si' then
  raise exception 'Confirmar destino test y adaptación coordinada antes de activar';
 end if;
 -- Revisar solo accesos a notas/importes del contrato nuevo. El inventario de
 -- 00 no autoriza modificar políticas o módulos ajenos a esta implementación.
 if current_setting('hulp.accesos_revisados',true) is distinct from 'si' then
  raise exception 'Revisar accesos a notas e importes del contrato nuevo primero';
 end if;
 -- Conservar el cuerpo remoto del trigger de recibos, introduciendo solo
 -- la exclusión para v1. No sustituirlo por la copia antigua de documentación.
 select prosrc into cuerpo from pg_proc
 where oid='public.actualizar_precio_solicitud_recibo()'::regprocedure;
 if cuerpo not ilike '%precio_original%' or cuerpo not ilike '%total_adicionales%'
  or cuerpo ilike '%finanzas_version%' then
  raise exception 'Trigger remoto distinto del documentado; revisar manualmente';
 end if;
 ddl:=pg_get_functiondef('public.actualizar_precio_solicitud_recibo()'::regprocedure);
 ddl:=replace(ddl,cuerpo,regexp_replace(cuerpo,'\mBEGIN\M',
  'BEGIN IF EXISTS (SELECT 1 FROM public.solicitudes_servicio WHERE id=NEW.solicitud_id AND finanzas_version=1) THEN RETURN NEW; END IF;','i'));
 execute ddl;
 -- RPC antiguos de pagos hallados en test: no deben marcar v1 pagado por
 -- existir cualquier transacción ni cambiar su estado operativo a 'pagado'.
 -- Mantener su comportamiento original para solicitudes sin versión.
 foreach firma in array array[
  'public.actualizar_estado_pago_solicitud(uuid)',
  'public.procesar_pago_exitoso(uuid,character varying,numeric,character varying,jsonb,character varying)'
 ] loop
  select prosrc into cuerpo from pg_proc where oid=firma::regprocedure;
  if cuerpo ilike '%finanzas_version%' then
   raise exception 'RPC de pago ya modificada; revisar antes de aplicar: %',firma;
  end if;
  ddl:=pg_get_functiondef(firma::regprocedure);
  ddl:=replace(ddl,cuerpo,regexp_replace(cuerpo,'\mBEGIN\M',
   'BEGIN IF EXISTS (SELECT 1 FROM public.solicitudes_servicio WHERE id=p_solicitud_id AND finanzas_version IS NOT NULL) THEN RAISE EXCEPTION ''Usar la confirmación de pagos financiera v1''; END IF;','i'));
  execute ddl;
 end loop;
end $$;
-- Protección ACOTADA a las dos notas. Conservar INSERT/UPDATE/DELETE y
-- SELECT de TODAS las demás columnas; ninguna política de filas cambia.
-- PostgreSQL requiere sustituir el SELECT de tabla por grants de columnas
-- para excluir estas dos: no basta REVOKE SELECT(notas) si existe SELECT global.
revoke select on public.solicitudes_servicio from public,anon,authenticated;
revoke select(informacion_adicional,notas_cliente) on public.solicitudes_servicio from public,anon,authenticated;
do $$ declare cols text; v text; begin
 select string_agg(quote_ident(attname),',' order by attnum) into cols from pg_attribute
 where attrelid='public.solicitudes_servicio'::regclass and attnum>0 and not attisdropped
 and attname not in ('informacion_adicional','notas_cliente');
 execute 'grant select ('||cols||') on public.solicitudes_servicio to anon,authenticated';
 -- La vista sigue disponible con el mismo nombre, columnas y tipos.
 -- Solo enmascarar notas según el rol; no revocar ALL ni SELECT de la vista.
 v:=pg_get_viewdef('public.vw_solicitudes_servicios_completa'::regclass,true);
 if v not like '%ss.informacion_adicional,%' or v not like '%ss.notas_cliente,%' then
  raise exception 'Revisar las expresiones de notas de la vista';
 end if;
 v:=replace(v,'ss.informacion_adicional,',
  'CASE WHEN current_user IN (''postgres'',''service_role'') OR EXISTS (SELECT 1 FROM public.usuarios operador WHERE operador.id=auth.uid() AND operador.rol=''administrador'') THEN ss.informacion_adicional ELSE NULL::text END AS informacion_adicional,');
 v:=replace(v,'ss.notas_cliente,',
  'CASE WHEN current_user IN (''postgres'',''service_role'') OR ss.usuario_id=auth.uid() OR EXISTS (SELECT 1 FROM public.usuarios operador WHERE operador.id=auth.uid() AND operador.rol=''administrador'') THEN ss.notas_cliente ELSE NULL::text END AS notas_cliente,');
 execute 'create or replace view public.vw_solicitudes_servicios_completa as '||v;
end $$;
grant select on public.solicitudes_servicio,public.vw_solicitudes_servicios_completa to service_role;
create or replace function hulp_finanzas.proteger_solicitud() returns trigger
language plpgsql set search_path='' as $hulp_campos$
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
  new.motivo_precio_pagado,new.adelanto_proveedor,new.adelanto_concepto,new.adelanto_motivo,
  new.aplica_wompi,new.aplica_ajuste_iva,new.requiere_fe,new.informacion_adicional,new.notas_cliente,
  new.materiales_total,new.pago_proveedor,new.saldo_transferir,new.comision_base,
  new.ajuste_iva_valor,new.comision_hulp_iva,new.comision_neta_hulp,new.iva_valor,
  new.comision_efectiva,new.wompi_valor,new.total_cliente,new.finanzas_revision,new.finanzas_calculadas_en)
  is distinct from row(old.precio,old.precio_base,old.precio_adicionales,old.estado_pago,
  old.motivo_precio_pagado,old.adelanto_proveedor,old.adelanto_concepto,old.adelanto_motivo,
  old.aplica_wompi,old.aplica_ajuste_iva,old.requiere_fe,old.informacion_adicional,old.notas_cliente,
  old.materiales_total,old.pago_proveedor,old.saldo_transferir,old.comision_base,
  old.ajuste_iva_valor,old.comision_hulp_iva,old.comision_neta_hulp,old.iva_valor,
  old.comision_efectiva,old.wompi_valor,old.total_cliente,old.finanzas_revision,old.finanzas_calculadas_en) then
  raise exception 'Finanzas/notas privadas solo mediante backend validado' using errcode='42501';
 end if;
 return new;
end $hulp_campos$;
-- Toda creación nueva atraviesa solicitud_crear_v1. Ningún DEFAULT retroactivo.
update hulp_finanzas.config set activado=true where singleton;
commit;
