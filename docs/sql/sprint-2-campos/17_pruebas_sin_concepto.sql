-- Solo Hulp/test. Comprobación transaccional: no deja solicitudes ni pagos.
begin;
do $prueba$
declare a uuid; c uuid; proveedor uuid; srv uuid; id_nuevo uuid;
 datos jsonb; entradas jsonb; items jsonb; r jsonb; original jsonb; rechazada boolean:=false;
begin
 select id into a from public.usuarios where rol='administrador' limit 1;
 select id into c from public.usuarios where rol='usuario' limit 1;
 select id into proveedor from public.usuarios where rol='proveedor' limit 1;
 select id into srv from public.servicios where estado='activo' limit 1;
 if a is null or c is null or proveedor is null or srv is null then
  raise exception 'Requiere usuarios y servicio de prueba existentes';
 end if;
 datos:=jsonb_build_object('usuario_id',c,'servicio_id',srv,'profesional_id',proveedor,
  'fecha',(now() at time zone 'America/Bogota')::date,'hora','15:00',
  'ubicacion','Prueba sin concepto (rollback)');
 entradas:='{"precio_base":10000,"precio":10000,"adelanto_proveedor":2000,
  "adelanto_motivo":"","aplica_wompi":true,"aplica_ajuste_iva":true,"requiere_fe":false}';
 items:='[{"tipo_item":"material","descripcion":"Tubos","cantidad":2,"precio_unitario":1500}]';
 begin
  perform public.solicitud_crear_v1(a,datos,entradas,items);
 exception when raise_exception then
  if sqlerrm <> 'Adelanto requiere motivo' then raise; end if;
  rechazada:=true;
 end;
 if not rechazada then raise exception 'Aceptó adelanto positivo sin motivo'; end if;
 entradas:=entradas || '{"adelanto_motivo":"Para su pasaje"}';
 r:=public.solicitud_crear_v1(a,datos,entradas,items);
 id_nuevo:=(r->>'solicitud_id')::uuid;
 if (r->>'pago_proveedor')::numeric<>7200
  or (r->>'saldo_transferir')::numeric<>5200
  or (r->>'total_cliente')::numeric<>14208.6 then
  raise exception 'Cambió los importes: %',r;
 end if;
 select to_jsonb(s)-array['adelanto_motivo','finanzas_revision','finanzas_calculadas_en']
 into original from public.solicitudes_servicio s where id=id_nuevo;
 entradas:=entradas || '{"adelanto_motivo":"Pasaje de regreso"}';
 perform public.solicitud_editar_v1(a,id_nuevo,1,'{}',entradas,items);
 if (select to_jsonb(s)-array['adelanto_motivo','finanzas_revision','finanzas_calculadas_en']
  from public.solicitudes_servicio s where id=id_nuevo) is distinct from original then
  raise exception 'Editar el motivo alteró otros datos';
 end if;
 if (select adelanto_motivo from public.solicitudes_servicio where id=id_nuevo)
  is distinct from 'Pasaje de regreso' then raise exception 'No guardó el motivo'; end if;
 if exists(select 1 from public.solicitud_finanzas_historial h where h.solicitud_id=id_nuevo
  and h.entradas->'datos' ? 'adelanto_concepto') then raise exception 'Historial nuevo incluye concepto'; end if;
 entradas:=entradas || '{"adelanto_proveedor":0,"adelanto_motivo":""}';
 perform public.solicitud_crear_v1(a,datos,entradas,items);
 perform set_config('hulp.prueba_sin_concepto',id_nuevo::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',proveedor,'role','authenticated')::text,true);
end $prueba$;
-- Ejecuta también la rama no privilegiada del trigger de protección.
set local role authenticated;
do $prueba$
declare cantidad integer;
begin
 update public.solicitudes_servicio set estado=estado
 where id=current_setting('hulp.prueba_sin_concepto')::uuid;
 get diagnostics cantidad=row_count;
 if cantidad<>1 then raise exception 'No pudo actualizar su solicitud asignada'; end if;
end $prueba$;
reset role;
select 'OK: adelanto sin concepto, motivo obligatorio, edición, fórmulas y trigger de proveedor' resultado;
rollback;
