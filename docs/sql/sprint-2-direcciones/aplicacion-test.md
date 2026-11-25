# Aplicación en Hulp/test — 2 de noviembre de 2026

Destino: `ptafsiwlhxomgqmdmidf`, rama `test` del proyecto Hulp. Confirmado mediante
MCP antes de aplicar. No se aplicó nada en otras ramas o proyectos.

Migración remota: `20261102141742_sprint2_direcciones_clientes`.
Archivo preparado: `20261029154702_sprint2_direcciones_clientes.sql`.
MCP asignó la versión remota al aplicar: no tratar el archivo local como otra
migración pendiente. Conciliar el historial antes de operar con CLI.

La primera ejecución falló por un punto y coma ausente al terminar la definición
de `eliminar_mi_cuenta`. Se confirmó ausencia de objetos nuevos y conservación del
hash original de la función; se corrigió el archivo y la segunda ejecución pasó.

## Comprobaciones realizadas

- Función/vista originales coincidentes con los hashes de preflight.
- Nueve direcciones migradas, texto idéntico al perfil y etiqueta Dirección anterior.
- Tres sin ciudad inequívoca: se conservaron sin asignar ciudad automáticamente.
- RLS habilitado y tres políticas instaladas: SELECT, INSERT, UPDATE.
- FK compuesta instalada con SET NULL solo sobre direccion_usuario_id.
- Nueva columna al final de la vista; función de anonimización desvincula dirección.
- Cero referencias nuevas en las 47 solicitudes históricas.
- Hash de las 26 filas de usuarios conservado:
  `e508b83ed23e038dc11448fd7ccce10b`.
- Hash de solicitudes, excluyendo la columna nueva, conservado:
  `885e3d05ad60c1604f436f5cc9b0b9a5`.
- `usuarios_externos` sigue vacía; no se modificaron sus datos ni estructura.

Pruebas en una transacción con ROLLBACK, simulando identidades autenticadas:
cliente no ve filas ajenas; puede insertar, editar y archivar una dirección propia;
se rechaza crear para otro dueño, cambiar el propietario y crear sin ciudad.
Admin ve todas las filas; proveedor no ve ninguna. Se comprobaron los privilegios:
anon carece de SELECT y authenticated carece de DELETE.
Al terminar quedaron nueve direcciones y cero residuos de prueba.

El asesor de seguridad no reportó avisos para direcciones_usuario. Los avisos
previos de otras tablas/vistas y el riesgo del rol permanecen fuera del cambio.

## Límites

No se ejecutó una eliminación real de cuenta ni una prueba integral de Flutter.
La revisión de la FK y función no sustituye esa prueba. Falta comprobar los flujos
de aplicación, Google Maps y la aceptación de datos reales. No se validó una
restauración física de plataforma; se guardaron localmente definiciones previas
y hashes de los datos, lo cual no es un respaldo completo de la base.
