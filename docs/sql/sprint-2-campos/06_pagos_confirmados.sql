-- PREPARADO, NO EJECUTADO. Ejecutar antes de activar 05.
-- No consulta Wompi: el backend verifica aprobación, moneda, monto, solicitud,
-- fuente y firma antes de invocar. Solo registra una confirmación comprobada.
begin;
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $$;

-- Importe de un recibo aceptado cuyos materiales ya están incorporados a v1.
-- No infiere mano de obra de un recibo mixto ni cobra materiales dos veces.
create function hulp_finanzas.importe_recibo_v1(p_id uuid,p_recibo uuid)
returns numeric language plpgsql set search_path='' as $$
declare rc public.recibos; incorporado numeric; s public.solicitudes_servicio; pagado numeric;
begin
 select * into rc from public.recibos where id=p_recibo for share;
 if rc.id is null or rc.solicitud_id is distinct from p_id
  or rc.estado is distinct from 'aceptado' then
  raise exception 'Recibo inexistente, ajeno o sin aceptación';
 end if;
 if not exists(select 1 from public.recibo_items ri where ri.recibo_id=p_recibo)
 or exists(select 1 from public.recibo_items ri where ri.recibo_id=p_recibo and
  (lower(ri.tipo_item) not in ('material','mano_obra') or (ri.tipo_item='material' and not exists
   (select 1 from public.solicitud_items si where si.solicitud_id=p_id
    and si.recibo_item_id=ri.id and si.tipo_item='material'
    and si.cantidad=ri.cantidad and si.precio_unitario=ri.precio_unitario)))) then
  raise exception 'Recibo mixto, vacío o con materiales sin incorporar';
 end if;
 select coalesce(sum(si.total),0) into incorporado from public.solicitud_items si
 join public.recibo_items ri on ri.id=si.recibo_item_id
 where si.solicitud_id=p_id and ri.recibo_id=p_recibo;
 select * into s from public.solicitudes_servicio where id=p_id;
 select coalesce(sum(monto),0) into pagado from public.transacciones where solicitud_id=p_id;
 if exists(select 1 from public.recibo_items where recibo_id=p_recibo and tipo_item='mano_obra') then
  return round(s.total_cliente-pagado,2);
 end if;
 if rc.total is null or rc.total<=0 or incorporado is distinct from rc.total then
  raise exception 'Total de recibo diferente del detalle';
 end if;
 return round(rc.total * case when s.aplica_wompi then 1.05 else 1 end,2);
end $$;
revoke all on function hulp_finanzas.importe_recibo_v1(uuid,uuid) from public,anon,authenticated;
grant execute on function hulp_finanzas.importe_recibo_v1(uuid,uuid) to service_role;

create function public.solicitud_recibo_importe_cobro_v1(p_actor uuid,p_id uuid,
 p_revision bigint,p_recibo uuid) returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; importe numeric; pagado numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 or p_revision is distinct from s.finanzas_revision then
  raise exception 'Versión o revisión financiera incorrecta' using errcode='40001';
 end if;
 if p_recibo is null then raise exception 'Recibo requerido'; end if;
 if exists(select 1 from public.transacciones t where t.recibo_id=p_recibo) then
  raise exception 'El recibo ya tiene un pago confirmado';
 end if;
 importe:=hulp_finanzas.importe_recibo_v1(p_id,p_recibo);
 select coalesce(sum(t.monto),0) into pagado from public.transacciones t where t.solicitud_id=p_id;
 if importe>s.total_cliente-pagado then raise exception 'Recibo superior al saldo del servicio'; end if;
 return jsonb_build_object('version',1,'revision',s.finanzas_revision,'recibo_id',p_recibo,
  'monto',importe,'centavos',importe*100);
end $$;
revoke all on function public.solicitud_recibo_importe_cobro_v1(uuid,uuid,bigint,uuid)
 from public,anon,authenticated;
grant execute on function public.solicitud_recibo_importe_cobro_v1(uuid,uuid,bigint,uuid) to service_role;

create function public.solicitud_pago_confirmar_v1(p_actor uuid,p_id uuid,p_revision bigint,
 p_transaccion uuid,p_numero text,p_monto numeric,p_metodo text,p_proveedor text,
 p_recibo uuid default null) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; t public.transacciones;
 pagado numeric; saldo numeric;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 or p_revision is distinct from s.finanzas_revision then
  raise exception 'Versión o revisión financiera incorrecta' using errcode='40001';
 end if;
 if p_transaccion is null or p_monto is null or p_monto<=0
  or p_monto::text in ('NaN','Infinity','-Infinity') or p_monto*100<>trunc(p_monto*100) then
  raise exception 'Identificador e importe exacto en centavos requeridos';
 end if;
 if nullif(btrim(p_metodo),'') is null or nullif(btrim(p_proveedor),'') is null then
  raise exception 'Método y proveedor requeridos';
 end if;
 if p_proveedor<>'QR' and nullif(btrim(p_numero),'') is null then
  raise exception 'Número confirmado del procesador requerido';
 end if;
 if p_proveedor='QR' and not exists(select 1 from public.usuarios u
  where u.id=p_actor and u.rol='administrador') then
  raise exception 'Solo Admin confirma pago manual' using errcode='42501';
 end if;
 -- ID estable en reintentos; el mismo número de Wompi tampoco puede duplicarse.
 select * into t from public.transacciones where id=p_transaccion
  or (p_numero is not null and numero_transaccion=p_numero) limit 1;
 if found then
  if t.solicitud_id is distinct from p_id or t.monto is distinct from p_monto
   or t.recibo_id is distinct from p_recibo
   or t.numero_transaccion is distinct from nullif(btrim(p_numero),'')
   or t.metodo_pago is distinct from p_metodo or t.proveedor_pago is distinct from p_proveedor then
   raise exception 'Referencia de pago reutilizada con otros datos';
  end if;
  return jsonb_build_object('transaccion_id',t.id,'existente',true);
 end if;
 select coalesce(sum(monto),0) into pagado from public.transacciones
 where solicitud_id=p_id;
 saldo:=round(s.total_cliente-pagado,2);
 if p_recibo is null then
  if p_monto is distinct from saldo then raise exception 'El pago no coincide con el saldo'; end if;
 else
  if p_monto is distinct from hulp_finanzas.importe_recibo_v1(p_id,p_recibo) then
   raise exception 'El pago no coincide con el recibo incorporado';
  end if;
  if exists(select 1 from public.transacciones where recibo_id=p_recibo) then
   raise exception 'El recibo ya tiene un pago confirmado';
  end if;
 end if;
 if p_monto>saldo then raise exception 'Pago superior al saldo; requiere conciliación'; end if;
 insert into public.transacciones(id,solicitud_id,usuario_id,numero_transaccion,monto,
  moneda,proveedor_pago,metodo_pago,fecha_pago,fecha_registro,recibo_id)
 values(p_transaccion,p_id,s.usuario_id,nullif(btrim(p_numero),''),p_monto,'COP',
  p_proveedor,p_metodo,now(),now(),p_recibo);
 -- Acreditar la solicitud solo cuando los pagos cubren su total.
 if round(pagado+p_monto,2)=round(s.total_cliente,2) then
  update public.solicitudes_servicio set estado_pago='pagado',fecha_pago=now() where id=p_id;
 end if;
 return jsonb_build_object('transaccion_id',p_transaccion,'existente',false,
  'pendiente',s.total_cliente-pagado-p_monto);
end $$;
revoke all on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid)
 from public,anon,authenticated;
grant execute on function public.solicitud_pago_confirmar_v1(uuid,uuid,bigint,uuid,text,numeric,text,text,uuid)
 to service_role;

create function hulp_finanzas.proteger_pago_v1() returns trigger
language plpgsql security invoker set search_path='' as $$
declare v integer;
begin
 -- Validar pertenencia también en escrituras directas del backend y filas
 -- legacy que aporten explícitamente un vínculo. No rellenar históricos NULL.
 if new.recibo_id is not null and not exists(select 1 from public.recibos r
  where r.id=new.recibo_id and r.solicitud_id=new.solicitud_id) then
  raise exception 'El recibo no pertenece a la solicitud de la transacción';
 end if;
 select finanzas_version into v from public.solicitudes_servicio where id=new.solicitud_id;
 if v is null then return new; end if;
 -- Usar el rol SQL efectivo: en eliminar_mi_cuenta (SECURITY DEFINER) es
 -- postgres aunque el JWT original siga siendo authenticated. El trigger
 -- INVOKER conserva ese contexto y permite anonimizar solo usuario_id.
 if current_user not in ('postgres','service_role') then
  raise exception 'Confirmación de pagos v1 solo desde backend' using errcode='42501';
 end if;
 if tg_op='UPDATE' then
  -- Compatibilidad con eliminar_mi_cuenta: solo reasigna el usuario.
  if (to_jsonb(new)-'usuario_id')=(to_jsonb(old)-'usuario_id') then return new; end if;
  raise exception 'Pago confirmado v1 inmutable; usar flujo de devolución';
 end if;
 return new;
end $$;
revoke all on function hulp_finanzas.proteger_pago_v1() from public,anon,authenticated,service_role;
create trigger sprint2_pago_proteger before insert or update on public.transacciones
 for each row execute function hulp_finanzas.proteger_pago_v1();
commit;
