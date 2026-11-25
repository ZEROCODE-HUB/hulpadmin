-- Aplicar en Hulp/test después de desplegar solicitudes-finanzas con los RPC
-- de transición y habilitar el corte a la versión actualizada de Talento.
begin;
set local lock_timeout = '5s';

alter table public.solicitudes_servicio
  enable trigger sprint3_proteger_estado_solicitud;

commit;
