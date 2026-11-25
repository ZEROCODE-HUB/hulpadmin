CREATE OR REPLACE FUNCTION public.validar_disponibilidad_profesional_solicitud()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_disponibilidad boolean;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.profesional_id IS NOT DISTINCT FROM OLD.profesional_id THEN
    RETURN NEW;
  END IF;

  IF NEW.profesional_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT u.disponibilidad
    INTO v_disponibilidad
    FROM public.usuarios AS u
   WHERE u.id = NEW.profesional_id
     AND u.rol = 'proveedor';

  IF NOT FOUND OR v_disponibilidad IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION USING
      ERRCODE = 'check_violation',
      MESSAGE = 'El profesional seleccionado no está disponible para recibir nuevas solicitudes.';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.validar_disponibilidad_profesional_solicitud()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS zz_validar_profesional_disponible
  ON public.solicitudes_servicio;

CREATE TRIGGER zz_validar_profesional_disponible
BEFORE INSERT OR UPDATE OF profesional_id
ON public.solicitudes_servicio
FOR EACH ROW
EXECUTE FUNCTION public.validar_disponibilidad_profesional_solicitud();
