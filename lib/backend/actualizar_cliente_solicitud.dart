import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '/backend/supabase/supabase.dart';

class ActualizarClienteSolicitudException implements Exception {
  const ActualizarClienteSolicitudException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Actualiza el perfil del cliente a través de la Edge Function protegida.
///
/// La URL se resuelve con la configuración activa de Supabase. En producción
/// corresponde a `https://ptafsiwlhxomgqmdmidf.supabase.co/functions/v1/`
/// seguida del nombre de la función, sin fijar el entorno en el código.
Future<void> actualizarClienteSolicitud({
  required String usuarioId,
  required String telefono,
  required String correoElectronico,
  required String direccion,
  required String ciudad,
}) async {
  try {
    final response = await SupaFlow.client.functions.invoke(
      'actualizar-cliente-solicitud',
      body: {
        'usuarioId': usuarioId,
        'telefono': telefono,
        'correoElectronico': correoElectronico,
        'direccion': direccion,
        'ciudad': ciudad,
      },
    );

    final data = response.data;
    if (data is Map && data['ok'] == true) return;

    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'El servidor devolvió una respuesta inesperada.';
    throw ActualizarClienteSolicitudException(message);
  } on FunctionException catch (error) {
    final details = error.details;
    final message = details is Map && details['error'] is String
        ? details['error'] as String
        : 'No se pudieron actualizar los datos del cliente.';
    throw ActualizarClienteSolicitudException(message);
  }
}
