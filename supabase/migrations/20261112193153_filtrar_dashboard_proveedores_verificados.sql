CREATE OR REPLACE VIEW public.vw_dashboard_metricas AS
SELECT
  count(CASE WHEN ss.estado = 'entrantes' THEN 1 END) AS servicios_pendientes,
  count(CASE
    WHEN ss.estado = ANY (ARRAY['aceptadas', 'iniciadas', 'en camino'])
    THEN 1
  END) AS servicios_activos,
  count(CASE WHEN ss.estado = 'en proceso' THEN 1 END) AS servicios_en_curso,
  count(CASE WHEN ss.estado = 'finalizadas' THEN 1 END) AS servicios_finalizados,
  count(CASE
    WHEN ss.estado = ANY (
      ARRAY['aceptadas', 'iniciadas', 'en camino', 'en proceso', 'finalizadas']
    )
    THEN 1
  END) AS total_solicitudes_servicio,
  (
    SELECT count(*)
    FROM public.usuarios AS u
    JOIN auth.users AS au ON u.id = au.id
    WHERE u.rol = 'proveedor'
      AND u.verificado = 'verificado'
      AND au.last_sign_in_at >= (CURRENT_DATE - '30 days'::interval)
  ) AS total_proveedores_activos,
  count(CASE
    WHEN ss.fecha = CURRENT_DATE AND ss.estado = 'entrantes' THEN 1
  END) AS solicitudes_hoy_entrantes,
  count(CASE
    WHEN ss.fecha = CURRENT_DATE
     AND ss.estado = ANY (ARRAY['aceptadas', 'iniciadas', 'en camino'])
    THEN 1
  END) AS solicitudes_hoy_activas,
  count(CASE
    WHEN ss.fecha = CURRENT_DATE AND ss.estado = 'finalizadas' THEN 1
  END) AS solicitudes_hoy_finalizadas,
  count(CASE
    WHEN ss.fecha >= CURRENT_DATE
     AND ss.fecha <= (CURRENT_DATE + 1)
     AND ss.estado = 'entrantes'
    THEN 1
  END) AS solicitudes_proximas_entrantes,
  count(CASE
    WHEN ss.fecha >= CURRENT_DATE
     AND ss.fecha <= (CURRENT_DATE + 1)
     AND ss.estado = ANY (ARRAY['aceptadas', 'iniciadas', 'en camino'])
    THEN 1
  END) AS solicitudes_proximas_activas,
  COALESCE(sum(CASE
    WHEN ss.fecha >= (CURRENT_DATE - 6)
     AND ss.fecha <= CURRENT_DATE
     AND ss.estado <> 'entrantes'
    THEN CASE
      WHEN ss.finanzas_version IS NULL THEN ss.precio
      WHEN ss.finanzas_version = 1 AND ss.estado_pago = 'pagado'
      THEN ss.comision_neta_hulp
      ELSE 0::numeric
    END
    ELSE 0::numeric
  END), 0::numeric) AS ingresos_totales_semanales,
  COALESCE(sum(CASE
    WHEN ss.fecha >= date_trunc('month', CURRENT_DATE::timestamptz)
     AND ss.fecha <= (
       date_trunc('month', CURRENT_DATE::timestamptz)
       + '1 mon'::interval - '1 day'::interval
     )
     AND ss.estado <> 'entrantes'
    THEN CASE
      WHEN ss.finanzas_version IS NULL THEN ss.precio
      WHEN ss.finanzas_version = 1 AND ss.estado_pago = 'pagado'
      THEN ss.comision_neta_hulp
      ELSE 0::numeric
    END
    ELSE 0::numeric
  END), 0::numeric) AS ingresos_totales_mensuales,
  COALESCE(sum(CASE
    WHEN ss.fecha >= date_trunc('year', CURRENT_DATE::timestamptz)
     AND ss.fecha <= (
       date_trunc('year', CURRENT_DATE::timestamptz)
       + '1 year'::interval - '1 day'::interval
     )
     AND ss.estado <> 'entrantes'
    THEN CASE
      WHEN ss.finanzas_version IS NULL THEN ss.precio
      WHEN ss.finanzas_version = 1 AND ss.estado_pago = 'pagado'
      THEN ss.comision_neta_hulp
      ELSE 0::numeric
    END
    ELSE 0::numeric
  END), 0::numeric) AS ingresos_totales_anuales
FROM public.solicitudes_servicio AS ss;
