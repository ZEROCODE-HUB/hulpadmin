// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/backend/wompi_servidor.dart';

/// Obtiene los tokens mediante el backend para evitar CORS en el navegador.
/// Los parámetros se conservan para las llamadas existentes; el servidor
/// determina el ambiente y la clave pública desde su configuración.
Future<dynamic> getAcceptanceToken(
  String publicKey,
  bool isProduction,
) async {
  final respuesta = await llamarWompi({
    'accion': 'obtener_tokens_aceptacion',
  });

  if (respuesta['success'] != true) {
    return {
      ...respuesta,
      'success': false,
    };
  }

  final acceptanceToken = respuesta['acceptanceToken'];
  final personalDataAuthToken = respuesta['personalDataAuthToken'];
  if (acceptanceToken is! String ||
      acceptanceToken.trim().isEmpty ||
      personalDataAuthToken is! String ||
      personalDataAuthToken.trim().isEmpty) {
    return {
      'success': false,
      'error': 'El servidor no devolvió ambos tokens de aceptación válidos',
      'statusCode': 502,
    };
  }

  return {
    ...respuesta,
    'acceptanceToken': acceptanceToken.trim(),
    'personalDataAuthToken': personalDataAuthToken.trim(),
    'permalink': respuesta['permalink'],
  };
}
