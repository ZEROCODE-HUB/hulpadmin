import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/solicitud_payment_helpers.dart';

/// Registra el pago manual QR sin modificar el estado operativo del servicio.
/// Listado y Detalles comparten esta operación; un pago recibido no se revierte.
Future<void> registrarPagoRecibidoQr(String solicitudId) async {
  if (solicitudId.trim().isEmpty) {
    throw ArgumentError('La solicitud es obligatoria.');
  }
  final solicitudes = await SolicitudesServicioTable().queryRows(
    queryFn: (query) => query.eq('id', solicitudId),
    limit: 1,
  );
  final solicitud = solicitudes.firstOrNull;
  if (solicitud == null) {
    throw StateError('No se encontró la solicitud.');
  }
  if (isPaymentReceived(solicitud.estadoPago)) {
    return;
  }
  if (!isPaymentPending(solicitud.estadoPago)) {
    throw StateError('El estado del pago cambió. Recarga la solicitud.');
  }

  // El ID estable permite reintentar sin duplicar el pago manual QR,
  // conservando numero_transaccion vacío y los datos del primer registro.
  await SupaFlow.client.from('transacciones').upsert(
    {
      'id': solicitud.id,
      'solicitud_id': solicitud.id,
      'usuario_id': solicitud.usuarioId,
      'numero_transaccion': null,
      'monto': (solicitud.precioBase ?? solicitud.precio) +
          (solicitud.precioAdicionales ?? 0.0),
      'moneda': 'COP',
      'proveedor_pago': 'QR',
      'metodo_pago': 'QR',
      'fecha_pago': supaSerialize<DateTime>(getCurrentTimestamp),
      'fecha_registro': supaSerialize<DateTime>(getCurrentTimestamp),
    },
    onConflict: 'id',
    ignoreDuplicates: true,
  );

  await SolicitudesServicioTable().update(
    data: {'estado_pago': 'pagado'},
    matchingRows: (rows) => rows.eqOrNull('id', solicitudId),
  );

  final confirmedRows = await VwSolicitudesServiciosCompletaTable().queryRows(
    queryFn: (query) => query.eq('solicitud_id', solicitudId),
    limit: 1,
  );
  if (confirmedRows.isEmpty ||
      !isPaymentReceived(confirmedRows.first.estadoPago)) {
    throw StateError('No se actualizó el estado del pago.');
  }
}
