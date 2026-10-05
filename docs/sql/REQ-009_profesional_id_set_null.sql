-- REQ-009: borrar un proveedor ya no borra las solicitudes de servicio
--
-- Aplicado en producción (zexegravzidwloxeimxx) el 2026-09-01.
--
-- `solicitudes_servicio.profesional_id` apuntaba a `usuarios(id)` con
-- ON DELETE CASCADE: al borrar un proveedor desaparecían sus solicitudes y,
-- en cascada, `recibos`, `transacciones`, `calificaciones`, `resenas` y
-- `chats_solicitud`. Es decir, se destruía también el historial del cliente
-- que contrató el servicio, que no tiene nada que ver con esa baja.
--
-- `eliminar_mi_cuenta()` v2 ya nulificaba `profesional_id` antes de borrar,
-- así que el borrado desde la app estaba a salvo; el daño solo aparece cuando
-- alguien borra usuarios directamente por SQL o desde el admin — que es lo que
-- ocurrió en el borrado masivo de agosto de 2026.
--
-- NULL en esta columna ya significa "sin asignar", así que SET NULL es también
-- lo semánticamente correcto: libera el trabajo en lugar de destruirlo. El
-- trigger `trigger_crear_chat_al_asignar_proveedor` no se activa, porque su
-- condición exige `NEW.profesional_id IS NOT NULL`.

begin;

alter table public.solicitudes_servicio
  drop constraint solicitudes_servicio_profesional_id_fkey;

alter table public.solicitudes_servicio
  add constraint solicitudes_servicio_profesional_id_fkey
  foreign key (profesional_id) references public.usuarios(id)
  on update cascade
  on delete set null;

commit;

-- Verificación:
--   select pg_get_constraintdef(oid) from pg_constraint
--   where conname = 'solicitudes_servicio_profesional_id_fkey';
--   -> FOREIGN KEY (profesional_id) REFERENCES usuarios(id)
--      ON UPDATE CASCADE ON DELETE SET NULL
--
-- Probado con un borrado real dentro de begin/rollback: la solicitud y su
-- chat sobreviven, y `profesional_id` queda en NULL.
--
-- PENDIENTE (no incluido aquí, cambia la semántica del borrado de clientes):
-- `solicitudes_servicio.usuario_id`, `recibos.proveedor_id`, `resenas` y
-- `calificaciones` siguen en CASCADE contra `usuarios`.
