import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '/backend/supabase/supabase.dart';

/// Puente con la Edge Function `wompi`.
///
/// Las operaciones que necesitan la clave privada de Wompi ya no se hacen
/// desde aqui: las hace la funcion, que es la unica que la conoce. Este
/// archivo solo traduce la llamada y normaliza la respuesta.
///
/// En admin, los tokens de aceptación también se solicitan por esta función
/// mediante obtener_tokens_aceptacion, para evitar CORS en el navegador.
/// La consulta del estado pasa por consultar_transaccion.
///
/// La respuesta conserva la forma que devolvian las acciones de FlutterFlow
/// —`success`, `transactionId`, `status`...— para que los widgets no cambien.
Future<Map<String, dynamic>> llamarWompi(Map<String, dynamic> cuerpo) async {
  try {
    final respuesta = await SupaFlow.client.functions.invoke(
      'wompi',
      body: cuerpo,
    );
    final datos = respuesta.data;
    if (datos is Map) return Map<String, dynamic>.from(datos);
    return {
      'success': false,
      'error': 'El servidor devolvio algo inesperado',
      'details': datos,
    };
  } on FunctionException catch (e) {
    // La funcion responde con el detalle en el cuerpo tambien cuando el
    // codigo no es 2xx, y ahi viene el motivo legible del rechazo.
    final detalle = e.details;
    if (detalle is Map) {
      final datos = Map<String, dynamic>.from(detalle);
      return {
        ...datos,
        'success': false,
        'statusCode': datos['statusCode'] ?? e.status,
      };
    }
    return {
      'success': false,
      'error': 'Error del servidor de pagos',
      'statusCode': e.status,
      'details': detalle,
    };
  } catch (e) {
    // Sin conexion, timeout, o la funcion caida.
    return {
      'success': false,
      'error': 'No se pudo contactar con el servidor de pagos',
      'details': e.toString(),
    };
  }
}
