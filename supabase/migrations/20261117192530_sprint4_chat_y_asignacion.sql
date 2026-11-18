-- Todas las lecturas de la vista anterior deben pasar por las políticas del chat.
alter view public.vw_mensajes_chat_completo set (security_invoker=true);

-- Guardar el evento de alta con la oferta vigente desde el primer día.
create or replace function hulp_ofertas.publicar_alta_sprint4() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  if new.tipo_asignacion<>'sin_asignar' then
    v_id:=hulp_ofertas.nueva_publicacion(new,new.tipo_asignacion,'alta');
    update public.solicitudes_servicio set publicacion_id=v_id where id=new.id;
    new.publicacion_id:=v_id;
    perform hulp_ofertas.registrar(new,'publicar_oferta','entrantes',null,gen_random_uuid(),
      jsonb_build_object('tipo',new.tipo_asignacion,'proveedor_nuevo',new.profesional_id));
  end if;
  return new;
end $$;

create or replace function hulp_ofertas.etiquetar_mensaje() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_rol text;
begin
  if tg_op='INSERT' then
    select s.asignacion_chat_id into new.asignacion_chat_id
    from public.chats_solicitud c join public.solicitudes_servicio s on s.id=c.solicitud_id
    where c.id=new.chat_id for share of s;
    if current_setting('role',true)='authenticated' then
      select rol into v_rol from public.usuarios where id=(select auth.uid());
      new.rol_remitente:=v_rol;
    end if;
  else
    new.asignacion_chat_id:=old.asignacion_chat_id;
    if current_setting('role',true)='authenticated'
      and (to_jsonb(new)-'leido') is distinct from (to_jsonb(old)-'leido') then
      raise exception using errcode='42501',message='Solo se puede actualizar el estado de lectura.';
    end if;
  end if;
  return new;
end $$;

notify pgrst,'reload schema';
