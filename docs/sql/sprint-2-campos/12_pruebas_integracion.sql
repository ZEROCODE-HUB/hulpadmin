-- Ejecutar exclusivamente en Hulp/test. Todas las filas de prueba se revierten.
begin;
do $$
declare a uuid; c uuid; proveedor uuid; srv uuid; s1 uuid; s2 uuid; rc uuid; rc2 uuid;
 s3 uuid; s4 uuid; rc3 uuid; rc4 uuid; r jsonb; quote jsonb; entradas jsonb; intento uuid; tx uuid:=gen_random_uuid(); blocked boolean:=false;
begin
 select id into a from public.usuarios where rol='administrador' limit 1;
 select id into c from public.usuarios where rol='usuario' limit 1;
 select id into proveedor from public.usuarios where rol='proveedor' limit 1;
 select id into srv from public.servicios where estado='activo' limit 1;
 entradas:='{"precio_base":120000,"precio":120000,"adelanto_proveedor":6000,"adelanto_motivo":"Prueba","aplica_wompi":true,"aplica_ajuste_iva":false,"requiere_fe":true}';
 r:=public.solicitud_crear_v1(a,jsonb_build_object('usuario_id',c,'servicio_id',srv,
  'fecha',(now() at time zone 'America/Bogota')::date,'hora','15:00','ubicacion','Prueba rollback',
  'informacion_adicional','Nota interna de prueba','notas_cliente','Nota del cliente de prueba'),entradas,'[]');
 s1:=(r->>'solicitud_id')::uuid;
 begin
  perform public.solicitud_finanzas_guardar_v1(s1,0,a,entradas,'[]');
 exception when serialization_failure then blocked:=true; end;
 if not blocked then raise exception 'Aceptó revisión obsoleta'; end if;
 blocked:=false;
 if (r->>'pago_proveedor')::numeric<>86400 or (r->>'saldo_transferir')::numeric<>80400 then raise exception 'Pago/adelanto incorrecto'; end if;
 insert into public.recibos(solicitud_id,proveedor_id,titulo,total) values(s1,proveedor,'Materiales prueba',0) returning id into rc;
 insert into public.recibo_items(recibo_id,tipo_item,descripcion,cantidad,precio_unitario)
 values(rc,'material','Material prueba',2,30000);
 quote:=public.solicitud_cobro_cotizar_v1(c,s1,rc,true);
 if (quote->>'monto')::numeric<>63000 then raise exception 'Cotización material incorrecta: %',quote; end if;
 r:=public.solicitud_cobro_preparar_v1(c,s1,rc,true,(quote->>'revision')::bigint,6300000);
 intento:=(r->>'intento_id')::uuid;
 if (r->>'monto')::numeric<>63000 then raise exception 'Importe de recibo incorrecto'; end if;
 begin
  perform public.solicitud_cobro_preparar_v1(c,s1,rc,true,null,null);
 exception when raise_exception then blocked:=true; end;
 if not blocked then raise exception 'No bloqueó cobro simultáneo'; end if;
 perform public.solicitud_pago_confirmar_v1(c,s1,(r->>'revision')::bigint,tx,'TEST-'||tx,63000,'CARD','WOMPI',rc,'{"prueba":true}','PRUEBA');
 if not (public.solicitud_pago_confirmar_v1(c,s1,(r->>'revision')::bigint,tx,'TEST-'||tx,63000,'CARD','WOMPI',rc)->>'existente')::boolean then raise exception 'No fue idempotente'; end if;
 update public.intentos_cobro set resultado='aprobado' where id=intento;
 if (select estado_pago from public.solicitudes_servicio where id=s1)<>'pendiente' then raise exception 'Pago parcial marcó solicitud pagada'; end if;
 if (select total_cliente from public.solicitudes_servicio where id=s1)<>189000 then raise exception 'Total duplicó materiales'; end if;
 if (select pago_proveedor from public.solicitudes_servicio where id=s1)<>86400 then raise exception 'Material aumentó pago proveedor'; end if;
 quote:=public.solicitud_cobro_cotizar_v1(c,s1,null,true);
 if (quote->>'recargo')::numeric<>6000 then raise exception 'Recargo previo no descontado'; end if;
 if (quote->>'monto')::numeric<>126000 then raise exception 'No descontó pago del recibo'; end if;
 r:=public.solicitud_cobro_preparar_v1(c,s1,null,true,(quote->>'revision')::bigint,12600000);
 tx:=gen_random_uuid();
 perform public.solicitud_pago_confirmar_v1(c,s1,(r->>'revision')::bigint,tx,'TEST-'||tx,126000,'CARD','WOMPI');
 update public.intentos_cobro set resultado='aprobado' where id=(r->>'intento_id')::uuid;
 if (select sum(monto) from public.transacciones where solicitud_id=s1)<>189000 then raise exception 'Cobró dos veces'; end if;
 if (select estado_pago from public.solicitudes_servicio where id=s1)<>'pagado' then raise exception 'Pago completo sin acreditar'; end if;
 if (select estado from public.solicitudes_servicio where id=s1)<>'entrantes' then raise exception 'Pago cambió estado operativo'; end if;
 entradas:='{"precio_base":68900,"precio":68900,"adelanto_proveedor":0,"aplica_wompi":false,"aplica_ajuste_iva":false,"requiere_fe":false}';
 r:=public.solicitud_crear_v1(a,jsonb_build_object('usuario_id',c,'servicio_id',srv,
  'fecha',(now() at time zone 'America/Bogota')::date,'hora','16:00','ubicacion','Prueba rollback 2'),entradas,'[]');
 s2:=(r->>'solicitud_id')::uuid;
 insert into public.recibos(solicitud_id,proveedor_id,titulo,total) values(s2,proveedor,'Mano de obra prueba',0) returning id into rc2;
 insert into public.recibo_items(recibo_id,tipo_item,descripcion,cantidad,precio_unitario)
 values(rc2,'mano_obra','Trabajo acordado',1,120000),(rc2,'material','Material',1,60000);
 quote:=public.solicitud_cobro_cotizar_v1(c,s2,rc2,false);
 if (quote->>'monto')::numeric<>180000 then raise exception 'No reemplazó cotización'; end if;
 r:=public.solicitud_cobro_preparar_v1(c,s2,rc2,false,(quote->>'revision')::bigint,18000000);
 if (select precio from public.solicitudes_servicio where id=s2)<>120000 then raise exception 'Sumó ambas cotizaciones'; end if;
 if (select count(*) from public.solicitud_items where solicitud_id=s2)<>2 then raise exception 'Detalle de recibo incompleto'; end if;
 r:=public.solicitud_metricas_periodo_v1(now()-interval '1 minute',now()+interval '1 minute');
 if (r->>'cobros_confirmados')::numeric<>189000 or (r->>'comision_neta')::numeric<>28235
  or (r->>'iva')::numeric<>5365 then raise exception 'Métricas mezclan conceptos: %',r; end if;
 select id into srv from public.servicios where estado='activo' and precio>0 limit 1;
 select jsonb_build_object('precio_base',precio,'precio',precio,'adelanto_proveedor',0,
  'aplica_wompi',false,'aplica_ajuste_iva',false,'requiere_fe',false) into entradas from public.servicios where id=srv;
 r:=public.solicitud_crear_v1(c,jsonb_build_object('usuario_id',c,'servicio_id',srv,
  'fecha',(now() at time zone 'America/Bogota')::date,'hora','17:00','ubicacion','Prueba cliente rollback','notas_cliente','Indicación cliente'),entradas,'[]');
 if (r->>'version')::int<>1 then raise exception 'Reserva del cliente sin versión'; end if;
 if exists(select 1 from public.vw_solicitudes_servicios_completa v join public.solicitudes_servicio s on s.id=v.solicitud_id
  where s.finanzas_version is null and v.precio_total is distinct from coalesce(s.precio_base,s.precio,0)+coalesce(s.precio_adicionales,0)) then
  raise exception 'Fórmula histórica alterada'; end if;
 -- Pago directo: quitar estimación de tarjeta y no competir con un intento pendiente.
 entradas:='{"precio_base":2000,"precio":2000,"adelanto_proveedor":0,"aplica_wompi":true,"aplica_ajuste_iva":false,"requiere_fe":false}';
 r:=public.solicitud_crear_v1(a,jsonb_build_object('usuario_id',c,'servicio_id',srv,'fecha',current_date,'hora','18:00','ubicacion','Prueba QR rollback'),entradas,'[]');
 s3:=(r->>'solicitud_id')::uuid;
 r:=public.solicitud_cobro_preparar_v1(a,s3,null,true,1,210000);
 blocked:=false;
 begin perform public.solicitud_pago_qr_v1(a,s3); exception when raise_exception then blocked:=true; end;
 if not blocked then raise exception 'QR compitió con cobro pendiente'; end if;
 update public.intentos_cobro set resultado='rechazado' where id=(r->>'intento_id')::uuid;
 perform public.solicitud_pago_qr_v1(a,s3);
 if (select total_cliente from public.solicitudes_servicio where id=s3)<>2000
  or (select monto from public.transacciones where solicitud_id=s3)<>2000
  or (select wompi_valor from public.solicitudes_servicio where id=s3)<>0 then raise exception 'QR conservó recargo de tarjeta'; end if;
 if not (public.solicitud_pago_qr_v1(a,s3)->>'existente')::boolean then raise exception 'QR no idempotente'; end if;
 -- Una compra de materiales pagada no bloquea cotizar mano de obra todavía no cobrada.
 entradas:='{"precio_base":68900,"precio":68900,"adelanto_proveedor":0,"aplica_wompi":true,"aplica_ajuste_iva":false,"requiere_fe":false}';
 r:=public.solicitud_crear_v1(a,jsonb_build_object('usuario_id',c,'servicio_id',srv,'fecha',current_date,'hora','19:00','ubicacion','Prueba materiales primero'),entradas,'[]');
 s4:=(r->>'solicitud_id')::uuid;
 insert into public.recibos(solicitud_id,proveedor_id,titulo,total) values(s4,proveedor,'Materiales antes de cotizar',0) returning id into rc3;
 insert into public.recibo_items(recibo_id,tipo_item,descripcion,cantidad,precio_unitario) values(rc3,'material','Material',1,60000);
 r:=public.solicitud_cobro_preparar_v1(c,s4,rc3,true,1,6300000);
 tx:=gen_random_uuid();
 perform public.solicitud_pago_confirmar_v1(c,s4,(r->>'revision')::bigint,tx,'TEST-'||tx,63000,'CARD','WOMPI',rc3);
 update public.intentos_cobro set resultado='aprobado' where id=(r->>'intento_id')::uuid;
 insert into public.recibos(solicitud_id,proveedor_id,titulo,total) values(s4,proveedor,'Cotización posterior',0) returning id into rc4;
 insert into public.recibo_items(recibo_id,tipo_item,descripcion,cantidad,precio_unitario) values(rc4,'mano_obra','Trabajo final',1,120000);
 quote:=public.solicitud_cobro_cotizar_v1(c,s4,rc4,true);
 r:=public.solicitud_cobro_preparar_v1(c,s4,rc4,true,(quote->>'revision')::bigint,12600000);
 if (r->>'monto')::numeric<>126000 or (select precio from public.solicitudes_servicio where id=s4)<>120000 then raise exception 'Material pagado bloquea cotización de mano de obra'; end if;
 perform set_config('hulp.test_id',s1::text,true);
 perform set_config('hulp.test_admin',a::text,true);
 perform set_config('hulp.test_proveedor',proveedor::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',c,'role','authenticated')::text,true);
end $$;
set constraints all immediate;
set local role authenticated;
do $$ declare denied boolean:=false; begin
 if not has_table_privilege('public.solicitudes_servicio','INSERT')
 or not has_table_privilege('public.solicitudes_servicio','UPDATE')
 or not has_table_privilege('public.solicitudes_servicio','DELETE') then raise exception 'Se perdieron permisos operativos'; end if;
 if exists(select 1 from pg_attribute where attrelid='public.solicitudes_servicio'::regclass
  and attnum>0 and not attisdropped and attname not in ('informacion_adicional','notas_cliente')
  and not has_column_privilege('public.solicitudes_servicio',attname,'SELECT')) then raise exception 'Se restringieron columnas operativas'; end if;
 begin execute 'select informacion_adicional from public.solicitudes_servicio limit 1';
 exception when insufficient_privilege then denied:=true; end;
 if not denied then raise exception 'Nota interna visible directamente'; end if;
 if (select informacion_adicional from public.vw_solicitudes_servicios_completa where solicitud_id=current_setting('hulp.test_id')::uuid) is not null then raise exception 'Vista expone nota interna al cliente'; end if;
 if (select notas_cliente from public.vw_solicitudes_servicios_completa where solicitud_id=current_setting('hulp.test_id')::uuid) <> 'Nota del cliente de prueba' then raise exception 'Cliente no ve su propia nota'; end if;
end $$;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('hulp.test_proveedor'),'role','authenticated')::text,true);
do $$ begin
 if exists(select 1 from public.vw_solicitudes_servicios_completa where solicitud_id=current_setting('hulp.test_id')::uuid
  and (informacion_adicional is not null or notas_cliente is not null)) then raise exception 'Vista expone notas a proveedora'; end if;
end $$;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('hulp.test_admin'),'role','authenticated')::text,true);
do $$ begin
 if (select informacion_adicional from public.vw_solicitudes_servicios_completa where solicitud_id=current_setting('hulp.test_id')::uuid) <> 'Nota interna de prueba' then raise exception 'Admin perdió acceso a notas'; end if;
end $$;
reset role;
select 'OK: recibos, reserva única, saldo, idempotencia, mano de obra y permisos acotados' resultado;
rollback;
