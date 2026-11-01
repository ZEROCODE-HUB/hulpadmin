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

/// Cobra una solicitud y espera a que Wompi resuelva la transaccion.
///
/// El cobro lo hace la Edge Function `wompi`, que es la unica que tiene la
/// clave privada y la de integridad. Aqui ya no se manda ninguna de las dos:
/// `privateKey` e `integrityKey` siguen en la firma porque los widgets
/// generados por FlutterFlow los pasan, pero **se ignoran**.
///
/// El importe tampoco se manda: lo calcula el servidor desde la solicitud.
/// Antes llegaba desde la pantalla, asi que bastaba con manipular la peticion
/// para cobrar una cifra distinta de la que vale el servicio.
///
/// El sondeo consulta la accion consultar_transaccion de la Edge Function.
/// La consulta a Wompi y su clave privada permanecen en el servidor.
Future<dynamic> createTransaction(
  String privateKey, // ignorado: la clave vive en el servidor
  String publicKey,
  int paymentSourceId,
  String acceptanceToken,
  int amountInCents, // ignorado: el importe lo calcula el servidor
  String currency,
  String customerEmail, // ignorado: sale de la ficha del cliente
  String referenceId,
  String integrityKey, // ignorado: la firma se hace en el servidor
  bool isProduction, {
  required String personalDataAuthToken,
}) async {
  try {
    if (publicKey.trim().isEmpty || !publicKey.startsWith('pub_')) {
      return {
        'success': false,
        'error': 'Public key invalida. Debe empezar con "pub_"',
        'field': 'publicKey'
      };
    }
    if (acceptanceToken.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Acceptance token requerido',
        'field': 'acceptanceToken'
      };
    }
    if (personalDataAuthToken.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Token de autorizacion de datos personales requerido',
        'field': 'personalDataAuthToken'
      };
    }
    if (referenceId.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Referencia requerida',
        'field': 'referenceId'
      };
    }

    // La referencia viene como "{id de la solicitud}-{marca de tiempo}", y el
    // id es un uuid que lleva guiones dentro: hay que cortar por el ULTIMO.
    final referencia = referenceId.trim();
    final corte = referencia.lastIndexOf('-');
    final solicitudId = corte > 0 ? referencia.substring(0, corte) : referencia;

    final creacion = await llamarWompi({
      'accion': 'crear_cobro',
      'solicitud_id': solicitudId,
      'acceptance_token': acceptanceToken.trim(),
      'accept_personal_auth': personalDataAuthToken.trim(),
      if (paymentSourceId > 0) 'payment_source_id': paymentSourceId,
    });

    if (creacion['success'] != true) return creacion;

    final transactionId = creacion['transactionId'];
    final estadoInicial = creacion['status'];

    const estadosFinales = ['APPROVED', 'DECLINED', 'VOIDED', 'ERROR'];
    if (estadosFinales.contains(estadoInicial)) {
      return {
        ...creacion,
        'attempts': 0,
        'totalTime': '0 segundos',
        'message': 'Transaccion finalizada inmediatamente: $estadoInicial',
      };
    }

    // Conserva el sondeo; el backend consulta a Wompi con su clave privada.
    final inicio = DateTime.now();
    Map<String, dynamic>? ultimoErrorConsulta;

    for (int intento = 1; intento <= 20; intento++) {
      await Future.delayed(Duration(seconds: 3));

      try {
        final consulta = await llamarWompi({
          'accion': 'consultar_transaccion',
          'transaction_id': transactionId,
        });

        if (consulta['success'] != true) {
          ultimoErrorConsulta = consulta;
          continue;
        }
        ultimoErrorConsulta = null;

        final estado = consulta['status'];
        final segundos = DateTime.now().difference(inicio).inSeconds;

        if (estadosFinales.contains(estado)) {
          return {
            ...consulta,
            'attempts': intento,
            'totalTime': '$segundos segundos',
            'message': 'Transaccion finalizada: $estado',
          };
        }
      } catch (e) {
        // Un fallo de red suelto no aborta el sondeo: se reintenta.
        print('Error consultando el estado, intento $intento: $e');
      }
    }

    final total = DateTime.now().difference(inicio).inSeconds;
    if (ultimoErrorConsulta != null) {
      return {
        ...ultimoErrorConsulta,
        'transactionId': transactionId,
        'attempts': 20,
        'totalTime': '$total segundos',
        'phase': 'POLLING',
      };
    }
    return {
      'success': false,
      'error':
          'TIMEOUT: La transaccion sigue procesandose despues de 60 segundos',
      'transactionId': transactionId,
      'status': 'TIMEOUT',
      'attempts': 20,
      'totalTime': '$total segundos',
      'message':
          'Timeout despues de 60 segundos. La transaccion puede completarse mas tarde.',
      'phase': 'POLLING'
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Error inesperado: ${e.toString()}',
      'phase': 'GENERAL'
    };
  }
}
