# Contraste del catálogo real de Hulp test

Fecha: 5 de noviembre de 2026. Rama confirmada por Supabase: **Hulp → test**,
ref `ptafsiwlhxomgqmdmidf`, PostgreSQL **15.14**. Todas las consultas remotas
fueron SELECT. No se ejecutaron migraciones, RPC de escritura, DML ni DDL.

## Evidencia y compatibilidad

El [snapshot del catálogo](./snapshot-catalogo-test-2026-11-05.json) conserva
131 columnas relevantes, 25 restricciones, 8 índices, 11 triggers, 10 vistas
dependientes, políticas, grants, vista completa y función de anonimización.
Son metadatos sin registros de clientes ni credenciales; no es un respaldo.

- UUID, NUMERIC, DATE, TIME y los campos operativos requeridos coinciden.
  solicitudes_servicio tiene 27 columnas; profesional_id sigue nullable.
- El ticket tiene DEFAULT de secuencia y se omite en la creación nueva.
- recibo_items tiene CHECK para material/mano_obra, cantidad > 0 y precio >= 0.
- transacciones tiene UNIQUE(numero_transaccion), útil para idempotencia.
- No existen hulp_finanzas, solicitud_items, solicitud_finanzas_historial ni las
  columnas financieras nuevas. El inventario no identificó historial financiero
  genérico reutilizable; limpiar_cleanup_historial tiene otro propósito.
- Se probaron las expresiones de transformación de la vista mediante SELECT de
  cadenas: precio_total y precio_calculado se transforman, se agregan columnas y
  quedan las dos ramas antiguas. No se ejecutó CREATE VIEW.
- eliminar_mi_cuenta reasigna solicitudes, transacciones y recibos a la identidad
  de anonimización; no los borra en ese recorrido. Las FK restrictivas nuevas no
  impiden esas reasignaciones.

| Definición inspeccionada | MD5 |
| --- | --- |
| pg_get_viewdef de la vista completa | `87920163697c65a1fb379957337444c2` |
| pg_get_functiondef del trigger de precios desde recibos | `a54dd02662f2a1985b12396ef72d3f14` |
| pg_get_functiondef de eliminar_mi_cuenta | `a3fcd68fd465dfc42ddfe7f5edd27ea3` |

## Correcciones en archivos locales

1. Los archivos 02 y 03 usan delimitadores explícitos $hulp_campos$. Los ocho
   SQL y sus 20 cuerpos PL/pgSQL se validan con el analizador PostgreSQL pglast.
   El error anterior de delimitadores no está presente en la copia revisada.
2. Los triggers existentes sync_ticket_seq, crear_chat_al_asignar_proveedor y
   programar_cleanup_conversaciones no fijan search_path y usan relaciones sin
   esquema. El archivo 03 prepara ALTER FUNCTION con pg_catalog,public para
   que funcionen cuando el RPC llamador usa search_path vacío, sin cambiar sus
   cuerpos ni fórmulas. Ningún rol cliente tiene CREATE en public según catálogo.
3. El trigger propuesto de pagos pasó de SECURITY DEFINER a SECURITY INVOKER y
   usa current_user. Así reconoce el rol SQL postgres de eliminar_mi_cuenta
   aunque el JWT original siga siendo authenticated, permitiendo solo cambiar
   usuario_id en la anonimización sin alterar el resto del pago confirmado.
4. Se agregaron huellas de deriva en 01. En 05 se prepararon guardas para que
   actualizar_estado_pago_solicitud y procesar_pago_exitoso conserven su lógica
   antigua en NULL, pero rechacen versión 1: hoy marcan pagado por existir una
   transacción y también cambian el estado operativo a pagado.

## Seguimiento de hallazgos y decisión de alcance del 6 de noviembre

- reagendar_solicitud inserta otra solicitud sin precio_base ni versión. Por
  decisión del usuario queda pendiente para otra entrega y no bloquea activar
  estos cambios. Se acepta su posible fallo posterior; no modificar la función
  ni convertir la solicitud original histórica.
- vw_dashboard_metricas y vw_metricas_proveedores suman precio. Requieren aporte
  por versión al integrar métricas nuevas; los scripts aún no cambian esas dos
  vistas. Mantener el aporte anterior para NULL.
- Existen políticas ALL con USING/WITH CHECK true y grants amplios; la vista
  completa usa permisos del dueño. Activar la privacidad requiere adaptar los
  lectores necesarios para las notas; el hallazgo no autoriza cambiar políticas
  de otras tablas. No se cambia usuarios.rol ni se hace una auditoría general.
- Hay 10 vistas dependientes. Para vw_resumen_categorias (security_invoker),
  el SQL 05 conserva el permiso mínimo de lectura de id/servicio_id en
  solicitudes, evitando modificar la vista, sus tablas o el módulo de Categorías.
- Siguen pendientes las reglas del README: mano de obra adicional, fracciones
  de centavo, edición tras pago y distribución de Wompi en recibos.

El contraste del catálogo está completado; la sintaxis no equivale a probar
escrituras, concurrencia, permisos efectivos nuevos o callbacks. No se aplicó
ninguno de los SQL preparados. La validación funcional tras una futura
aplicación autorizada en test permanece pendiente.
