import 'package:flutter/material.dart';
import '/environment_values.dart';

bool get usaEstadosSprint3 =>
    Uri.tryParse(FFDevEnvironmentValues().supabaseUrl)?.host ==
    'ptafsiwlhxomgqmdmidf.supabase.co';

String? estadoSolicitudParaFiltro(String? estado) {
  if (!usaEstadosSprint3) return estado;
  return switch (estado) {
    'iniciadas' => 'aceptadas',
    'cancelada' => 'canceladas',
    'reagendada' => 'reagendadas',
    _ => estado,
  };
}

String etiquetaEstadoSprint3(String? estado) => switch (estado) {
      'entrantes' => 'Pendiente',
      'aceptadas' || 'iniciadas' => 'Aceptado',
      'en camino' => 'Activo',
      'en proceso' => 'En curso',
      'finalizadas' => 'Finalizado',
      'cancelada' || 'canceladas' => 'Cancelado',
      'reagendada' || 'reagendadas' => 'Reagendada',
      _ => 'Estado desconocido',
    };

Color solicitudStatusBackgroundColor(String? estado) {
  switch (estadoSolicitudParaFiltro(estado)) {
    case 'entrantes':
      return const Color(0xFFE9EBEC);
    case 'en camino' when usaEstadosSprint3:
    case 'aceptadas':
      return const Color(0xFFD6EAFF);
    case 'finalizadas':
      return const Color(0xFFDFF9D2);
    case 'canceladas':
    case 'reagendadas':
      return const Color(0xFFF9DCDF);
    default:
      return const Color(0xFFFFF5D6);
  }
}

Color solicitudStatusForegroundColor(String? estado) {
  switch (estadoSolicitudParaFiltro(estado)) {
    case 'entrantes':
      return const Color(0xFF6C757D);
    case 'en camino' when usaEstadosSprint3:
    case 'aceptadas':
      return const Color(0xFF007BFF);
    case 'finalizadas':
      return const Color(0xFF388212);
    case 'canceladas':
    case 'reagendadas':
      return const Color(0xFFDC3545);
    default:
      return const Color(0xFFD6A100);
  }
}

String solicitudStatusLabel(String? estado) {
  if (usaEstadosSprint3) return etiquetaEstadoSprint3(estado);
  switch (estado) {
    case 'entrantes':
      return 'Pendiente';
    case 'aceptadas':
      return 'Activo';
    case 'canceladas':
      return 'Cancelado';
    case 'finalizadas':
      return 'Finalizado';
    case 'reagendadas':
      return 'Reagendada';
    default:
      return 'En curso';
  }
}
