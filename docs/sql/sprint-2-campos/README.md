# Campos y cálculos de solicitudes — Sprint 2

Implementado y activado únicamente en **Hulp/test (`ptafsiwlhxomgqmdmidf`)**,
6 de noviembre de 2026. No ejecutar estos scripts de nuevo ni aplicarlos en main.

## Migraciones desplegadas

La fuente canónica está en `hulpadmin/supabase/migrations/`. Los nombres locales
coinciden con el historial remoto leído después de aplicar las migraciones.

| Versión | Nombre | Contenido |
| --- | --- | --- |
| 20261106042519 | sprint2_campos_estructura | Columnas, ítems, historial, cálculo, RPC y configuración inicialmente apagada; fuentes 01, 02, 03, 04, 06 y 08. |
| 20261106042849 | sprint2_campos_integracion | Métricas por versión, compatibilidad de triggers y detalle de recibos; fuente 09. |
| 20261106114025 | sprint2_campos_activacion | Reserva de cobro, cotización previa y activación con permisos acotados; fuentes 10, 11 y 05. |
| 20261106114356 | sprint2_campos_ajustes_verificados | Corregir alias de rol en recibos y descontar el recargo ya cobrado; fuente 13. |
| 20261106114512 | sprint2_cobro_centavos | Conversión numeric→bigint de los centavos, validada con un recibo real transaccional de Test; fuente 14. |
| 20261106120957 | sprint2_materiales_y_pago_directo | Pago directo sin recargo ni competencia con Wompi pendiente; permite cotizar mano de obra aún no cobrada tras pagar solo materiales; fuente 15. |
| 20261106121109 | sprint2_validacion_materiales_pagados | Valida la conservación de los renglones ya cobrados sin ambigüedad de alias; fuente 16. |
| 20261108144503 | eliminar_concepto_adelanto | Quita `adelanto_concepto`, adapta cinco funciones y reconstruye la vista sin cambiar sus permisos. Conserva importe, motivo y JSON históricos. |

Los archivos numerados de esta carpeta son fuentes de revisión y pruebas. No son
idempotentes. Los comentarios iniciales de preparación describen cuándo se
redactaron, no el estado actual del despliegue. Las migraciones ya aplicadas son
inmutables: las correcciones están registradas en migraciones posteriores.

## Accesos finales

No se revoca INSERT, UPDATE ni DELETE en `solicitudes_servicio`, ni los permisos
de su vista completa. Se sustituye SELECT global por grants de todas las columnas
excepto `informacion_adicional` y `notas_cliente`; es el mecanismo de PostgreSQL
para excluir esas dos columnas sin quitar las lecturas operativas.

La vista conserva las columnas operativas y enmascara únicamente notas según la identidad:
Admin puede leer ambas, el cliente sus propias notas y Talentos ninguna.
Los formularios usan el backend para el guardado financiero atómico y para leer
los datos privados autorizados. Los triggers validan versión e importes sin cambiar
las políticas de filas de usuarios, catálogo, soporte u otras tablas.

## Reglas efectivas

- NULL conserva cálculos anteriores; toda solicitud nueva se crea con versión 1.
- `precio` es el acuerdo de mano de obra; `precio_base` es lista. Materiales,
  ajuste y Wompi se suman al total cliente, sin aumentar el 72 % de proveedora.
- Mano de obra aceptada en un recibo reemplaza la cotización anterior. Materiales
  se enlazan una sola vez por `recibo_item_id`; sus pagos tienen `recibo_id`.
- Recibos pagados reducen el saldo de cobro y su recargo ya pagado se descuenta
  de la cotización del saldo. No se cobra dos veces el mismo concepto.
- La reserva y la revisión financiera se guardan en una sola transacción.
  Solo una aprobación verificada por el servidor confirma un pago de Wompi.
- La comisión neta se redondea al peso según las fórmulas. Se conservan los
  resultados decimales y se redondea a dos decimales en la frontera del cobro.
- Con mano de obra ya cobrada no se cambia su precio ni ajuste. Si solo se han
  pagado materiales, puede cotizarse la mano de obra aún no cobrada, conservando
  los renglones pagados. No se cambia el recargo tras un pago confirmado; mezclar
  métodos con distinto recargo requiere otro flujo de ajuste.
- El pago directo QR elimina el recargo estimado de Wompi antes de confirmar,
  siempre que no haya pagos previos que lo congelen. Un intento Wompi pendiente
  impide confirmar otro pago hasta consultar su resultado. Una solicitud ya
  liquidada requiere otro flujo para alterar el total.
- `reagendar_solicitud` permanece pendiente, por decisión expresa del usuario.
- Desde el 8 de noviembre el adelanto conserva solo importe y motivo; este
  último es obligatorio si el importe es mayor que cero. No cambia ninguna fórmula.

## Verificación

- `07_verificacion.sql`: consultas de catálogo y seis ejemplos económicos.
- `12_pruebas_integracion.sql`: creación de Admin y cliente, revisión obsoleta,
  recibos, reserva única, idempotencia, saldo final, reemplazo de mano de obra,
  métricas, notas por rol, pago directo y cotización tras pagar solo materiales.
  Termina en ROLLBACK; no deja solicitudes ni pagos.
- `17_pruebas_sin_concepto.sql`: creación y edición sin concepto, motivo
  obligatorio con adelanto positivo, fórmulas conservadas y actualización de
  proveedora a través del trigger. También termina en ROLLBACK.
- [Verificación de la eliminación del concepto](../../../../documents/changes/sprint-2/verificacion-eliminar-concepto-adelanto-2026-11-08.md).
- [Informe de implementación y evidencia](../../../../documents/changes/sprint-2/verificacion-campos-formulario-solicitud-2026-11-06.md).

Las verificaciones SQL no envían cobros a Wompi. La aceptación del procesador
externo y de las pantallas con sesión real queda explícitamente separada.

## Aclaración comercial: Wompi incluye NEQUI (6 de noviembre de 2026)

Todos los medios procesados por Wompi llevan el recargo del 5 %, no solo CARD.
Cotización y preparación usan `p_tarjeta = true` para CARD, NEQUI, DAVIPLATA y
BANCOLOMBIA_TRANSFER; el nombre del parámetro se conserva por compatibilidad.
La fórmula SQL existente no cambia, por lo que no se requiere migración.
Pago directo mantiene recargo cero. No se modifican solicitudes ya liquidadas
ni el contrato histórico sin versión financiera.
