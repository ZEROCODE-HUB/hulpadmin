import '/flutter_flow/solicitud_status_helpers.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

List<String>? convertirlista(
  String? foto1,
  String? foto2,
  String? foto3,
) {
  // Convertir los parámetros en una lista
  List<String> fotos = [];
  if (foto1 != null) fotos.add(foto1);
  if (foto2 != null) fotos.add(foto2);
  if (foto3 != null) fotos.add(foto3);
  return fotos.isNotEmpty ? fotos : null;
}

String obtenerNroLiteral(int numero) {
  switch (numero) {
    case 1:
      return 'Primera';
    case 2:
      return 'Segunda';
    case 3:
      return 'Tercera';
    case 4:
      return 'Cuarta';
    case 5:
      return 'Quinta';
    case 6:
      return 'Sexta';
    case 7:
      return 'Séptima';
    case 8:
      return 'Octava';
    case 9:
      return 'Novena';
    case 10:
      return 'Décima';
    case 11:
      return 'Undécima';
    case 12:
      return 'Duodécima';
    case 13:
      return 'Decimotercera';
    case 14:
      return 'Decimocuarta';
    case 15:
      return 'Decimoquinta';
    case 16:
      return 'Decimosexta';
    case 17:
      return 'Decimoséptima';
    case 18:
      return 'Decimoctava';
    case 19:
      return 'Decimonovena';
    case 20:
      return 'Vigésima';
    case 21:
      return 'Vigésima primera';
    case 22:
      return 'Vigésima segunda';
    case 23:
      return 'Vigésima tercera';
    case 24:
      return 'Vigésima cuarta';
    case 25:
      return 'Vigésima quinta';
    case 26:
      return 'Vigésima sexta';
    case 27:
      return 'Vigésima séptima';
    case 28:
      return 'Vigésima octava';
    case 29:
      return 'Vigésima novena';
    case 30:
      return 'Trigésima';
    default:
      return numero.toString();
  }
}

List<String> getStatus(List<String> statuses) {
  if (usaEstadosSprint3) return statuses.map(etiquetaEstadoSprint3).toList();
  return statuses.map((status) {
    switch (status) {
      case 'entrantes':
        return 'Pendientes';
      case 'canceladas':
        return 'Cancelado';
      case 'finalizadas':
        return 'Finalizado';
      case 'aceptadas':
        return 'Activo';
      case 'en proceso':
        return 'En curso';
      case 'reagendadas':
        return 'Reagendada';
      case 'en camino':
        return 'En curso(Camino)';
      default:
        return status;
    }
  }).toList();
}

int stringToIngete(String texto) {
  return int.tryParse(texto) ?? 0;
}

List<String> getFullNames(List<UsuariosRow> usuarios) {
  if (usuarios.isEmpty) return [];

  // Generar lista de nombres completos manteniendo el orden original
  final nombresCompletos = usuarios.map((UsuariosRow user) {
    final nombre = user.nombres ?? '';
    final apellido = user.apellidos ?? '';
    return '$nombre $apellido'.trim();
  }).toList();

  return nombresCompletos;
}

List<String> getIdsOrderedByName(List<UsuariosRow> usuarios) {
  if (usuarios.isEmpty) return [];

  // Solo devolvemos los IDs en el mismo orden que vienen
  return usuarios.map((u) => u.id!).toList();
}

DateTime formatTimestamp(
  DateTime timestamp,
  bool date,
) {
  if (date) {
    // Para columna 'date': año-mes-día, hora = 00:00:00
    return DateTime(timestamp.year, timestamp.month, timestamp.day);
  } else {
    // Para columna 'time': fecha fija, hora = real
    return DateTime(
        1970, 1, 1, timestamp.hour, timestamp.minute, timestamp.second);
  }
}

String generateUUIDv4() {
  final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();

  String hex(String input) {
    return input.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  final String h = hex(timestamp).padRight(32, '0').substring(0, 32);

  return '${h.substring(0, 8)}-${h.substring(8, 12)}-4${h.substring(13, 16)}-8${h.substring(17, 20)}-${h.substring(20, 32)}';
}

String formatPrices(double valor) {
  final NumberFormat formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(valor);
}
