-- Integración de formularios. Instalar después de 06 y antes de 05.
begin;
do $$ begin
 if current_setting('hulp.target_ref',true) is distinct from 'ptafsiwlhxomgqmdmidf' then
  raise exception 'Destino test no confirmado';
 end if;
end $$;

create function public.solicitud_finanzas_previsualizar_v1(p_entradas jsonb,p_items jsonb)
returns jsonb language sql set search_path='' as $$
 select hulp_finanzas.calcular_v1((p_entradas->>'precio_base')::numeric,
  (p_entradas->>'precio')::numeric,
  coalesce((select sum((x->>'cantidad')::numeric*(x->>'precio_unitario')::numeric)
    from jsonb_array_elements(p_items) x where x->>'tipo_item'='material'),0),
  coalesce((p_entradas->>'adelanto_proveedor')::numeric,0),
  coalesce((p_entradas->>'aplica_wompi')::boolean,false),
  coalesce((p_entradas->>'aplica_ajuste_iva')::boolean,false));
$$;

create function public.solicitud_editar_v1(p_actor uuid,p_id uuid,p_revision bigint,
 p_datos jsonb,p_finanzas jsonb,p_items jsonb) returns jsonb
language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; n public.solicitudes_servicio; r jsonb;
begin
 if not exists(select 1 from public.usuarios where id=p_actor and rol='administrador') then
  raise exception 'Solo Admin puede editar' using errcode='42501';
 end if;
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
 if exists(select 1 from jsonb_object_keys(p_datos) k where k not in
  ('descripcion','informacion_adicional','ubicacion','fecha','hora','profesional_id',
   'servicio_id','servicio_nombre','ciudad_id','latitud','longitud','direccion_usuario_id','estado')) then
  raise exception 'Campo operativo no permitido';
 end if;
 n:=jsonb_populate_record(s,p_datos);
 update public.solicitudes_servicio set descripcion=n.descripcion,
 informacion_adicional=n.informacion_adicional,ubicacion=n.ubicacion,fecha=n.fecha,hora=n.hora,
 profesional_id=n.profesional_id,servicio_id=n.servicio_id,servicio_nombre=n.servicio_nombre,
 ciudad_id=n.ciudad_id,latitud=n.latitud,longitud=n.longitud,direccion_usuario_id=n.direccion_usuario_id,
 estado=n.estado where id=p_id;
 r:=hulp_finanzas.guardar_v1(p_id,p_revision,p_actor,p_finanzas,p_items,'Edición Admin');
 return r;
end $$;

-- Recibos aceptados: la lista de mano de obra reemplaza la cotización anterior.
-- Materiales se incorporan por su ID de origen y solo una vez. Los recibos ya
-- pagados conservan su detalle; no se promueven ni recalculan históricos.
create function hulp_finanzas.sincronizar_recibo_v1() returns trigger
language plpgsql security definer set search_path='' as $$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; labor numeric;
begin
 select * into s from public.solicitudes_servicio where id=new.solicitud_id for update;
 if s.finanzas_version is distinct from 1 then return new; end if;
 if new.estado is distinct from 'aceptado' then return new; end if;
 if tg_op='UPDATE' and old.estado='aceptado' then return new; end if;
 select coalesce(jsonb_agg(jsonb_build_object('tipo_item',tipo_item,'descripcion',descripcion,
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',recibo_item_id) order by orden,id),'[]')
 into items from public.solicitud_items where solicitud_id=s.id;
 select coalesce(jsonb_agg(jsonb_build_object('tipo_item','material','descripcion',coalesce(descripcion,'Material'),
  'cantidad',cantidad,'precio_unitario',precio_unitario,'recibo_item_id',id)),'[]') || items
 into items from public.recibo_items where recibo_id=new.id and tipo_item='material'
 and id not in(select recibo_item_id from public.solicitud_items where recibo_item_id is not null);
 select sum(cantidad*precio_unitario) into labor from public.recibo_items
 where recibo_id=new.id and tipo_item='mano_obra';
 entradas:=jsonb_build_object('precio_base',coalesce(labor,s.precio_base),
  'precio',coalesce(labor,s.precio),'motivo_precio_pagado',s.motivo_precio_pagado,
  'adelanto_proveedor',s.adelanto_proveedor,'adelanto_concepto',s.adelanto_concepto,
  'adelanto_motivo',s.adelanto_motivo,'aplica_wompi',s.aplica_wompi,
  'aplica_ajuste_iva',s.aplica_ajuste_iva,'requiere_fe',s.requiere_fe);
 perform hulp_finanzas.guardar_v1(s.id,s.finanzas_revision,null,entradas,items,'Recibo aceptado');
 return new;
end $$;
create trigger sprint2_recibo_incorporar after update of estado on public.recibos
 for each row execute function hulp_finanzas.sincronizar_recibo_v1();

revoke all on function public.solicitud_finanzas_previsualizar_v1(jsonb,jsonb),
 public.solicitud_editar_v1(uuid,uuid,bigint,jsonb,jsonb,jsonb),
 hulp_finanzas.sincronizar_recibo_v1() from public,anon,authenticated;
grant execute on function public.solicitud_finanzas_previsualizar_v1(jsonb,jsonb),
 public.solicitud_editar_v1(uuid,uuid,bigint,jsonb,jsonb,jsonb) to service_role;

-- Un solo cobro v1 pendiente por solicitud, incluso entre dos dispositivos.
-- El detalle ya existente conserva la revisión de la intención, sin columnas
-- financieras redundantes en transacciones.
create unique index intentos_cobro_finanzas_pendiente_idx on public.intentos_cobro(solicitud_id)
 where resultado='pendiente' and detalle ? 'finanzas_revision';

create function public.solicitud_cobro_preparar_v1(p_actor uuid,p_id uuid,p_recibo uuid,
 p_tarjeta boolean) returns jsonb language plpgsql set search_path='' as $$
declare s public.solicitudes_servicio; entradas jsonb; items jsonb; r jsonb;
begin
 perform public.solicitud_finanzas_leer(p_actor,p_id);
 select * into s from public.solicitudes_servicio where id=p_id for update;
 if s.finanzas_version is distinct from 1 then raise exception 'Solo versión 1'; end if;
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
 return r;
end $$;
revoke all on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.solicitud_cobro_preparar_v1(uuid,uuid,uuid,boolean) to service_role;
commit;
