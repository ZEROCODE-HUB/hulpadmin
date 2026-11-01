# SQL preparado — direcciones múltiples, Sprint 2

Estado: archivos locales preparados, ninguna migración aplicada. Destino exclusivo:
Hulp, rama `test`, referencia `ptafsiwlhxomgqmdmidf`.

## Archivos

- `01_preflight.sql`: consultas de lectura previas; revisar esquema, hashes,
  roles existentes y ciudades sin coincidencia inequívoca.
- `../../../supabase/migrations/20261029154702_sprint2_direcciones_clientes.sql`:
  migración única y transaccional, creada con `supabase migration new`.
- `02_verificacion.sql`: consultas de lectura para la verificación posterior.

## Contenido y decisiones

La migración crea `direcciones_usuario`, sus checks, índices y timestamps;
migra solo direcciones no vacías de perfiles con `rol = 'usuario'`; añade
`direccion_usuario_id` y una FK compuesta que comprueba al propietario;
adapta `eliminar_mi_cuenta()` para desvincular la dirección al anonimizar;
y añade la referencia al final de la vista de solicitudes, sin cambiar sus joins.
La función y la vista parten de las definiciones desplegadas leídas en `test`;
sus hashes se comprueban antes de reemplazarlas. No se usa el SQL histórico local
de `_eliminar_cuenta`, que difiere de la función realmente desplegada.

El backfill conserva literalmente `usuarios.direccion`, usa la etiqueta
«Dirección anterior» y solo relaciona ciudades por nombre normalizado exacto
con una coincidencia. Conserva incluso una ciudad inactiva histórica; para
direcciones nuevas, cambios de ubicación y reactivación se exige ciudad activa.
Las solicitudes existentes quedan sin referencia. No hay cambios masivos en
ubicación, ciudad, coordenadas, pagos ni campos antiguos del perfil.

`usuarios_externos` se conserva sin cambios. Quick Add queda fuera del alcance.
Agregar una dirección no crea usuarios ni identidades Auth.

## Autorización

Se usa exclusivamente `usuarios.rol`: un administrador autenticado puede
consultar, insertar y actualizar direcciones de clientes existentes. Un cliente
autenticado con rol `usuario` puede hacer lo mismo solo sobre filas con
`usuario_id = auth.uid()`. Proveedores y anon no reciben acceso a la libreta.
No se crea lista privada, esquema privado ni se incluye un UUID de operador.
No hay DELETE para clientes API: se archiva con `activo = false`.
El trigger impide transferir una dirección a otro dueño, incluso desde Admin.
Estas políticas ya permiten integrar la app del cliente sin otra migración para
consultar, agregar, editar o archivar sus direcciones; las pantallas móviles
siguen pendientes y no se implementan en este paquete.
`service_role` conserva acceso de backend y nunca se entrega a Flutter.

Las políticas abiertas existentes de `usuarios` y `solicitudes_servicio` no se
modifican en este paquete, ni se añaden protecciones a `usuarios.rol`, por decisión
expresa del alcance. El riesgo de que se modifique ese rol permanece y afecta a
la autorización de direcciones y a la Edge Function de edición de contacto.
Las restricciones descritas suponen que los roles conservan sus valores legítimos;
no se afirma que este paquete solucione la escalada de privilegios existente.

## Aplicación futura y validación

Confirmar respaldo recuperable y revisar preflight primero. La carpeta local de
migraciones no contiene las siete migraciones históricas remotas: NO usar
`db push`, `db reset` ni reparar historial a ciegas. Antes del despliegue hay que
conciliar el historial real con la CLI y confirmar el destino `test`.
Estas instrucciones no autorizan aplicar nada por sí solas.

Ejecutar en una futura ventana autorizada la migración completa como propietario
de la base. Si falla una precondición, FK, lock o instrucción, revertir la
transacción; no omitir controles para continuar. No es un script para repetir
manualmente: los objetos nuevos y el backfill se crean una sola vez.

Después, comprobar conteos y snapshots contra el respaldo, y probar en un entorno
controlado permisos de anon, cliente, proveedor, operador y backend; dirección
ajena, archivado, ciudad inválida, coordenadas incompletas y anonimización con
solicitud vinculada. Las consultas de verificación no sustituyen esas pruebas.
Probar también alta, edición y archivo propios como cliente, rechazo de filas
ajenas y rechazo de cambio de propietario. Esta verificación no acredita la
protección de `usuarios.rol`, que se mantiene sin cambios.

No se ejecutó el SQL, ni siquiera sobre una base local. La revisión estática no
acredita aceptación funcional, RLS efectiva ni despliegue. Falta la implementación
Flutter y su validación al integrar el contrato.

## Recuperación

Antes del commit, un ROLLBACK revierte todo el paquete. Tras el commit, si el
problema está en Flutter, volver a la versión anterior: los campos nuevos son
opcionales y no alteran el contrato anterior. Conservar las direcciones creadas.
Para deshacer datos/esquema tras su uso, detener escrituras y utilizar un respaldo
verificado o preparar una migración inversa tras exportar las direcciones nuevas.
Restaurar una copia anterior descarta cambios posteriores: no automatizar ese paso.
No se incluye un DROP destructivo que pueda borrar domicilios nuevos por accidente.
