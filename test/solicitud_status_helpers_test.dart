import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/flutter_flow/solicitud_status_helpers.dart';

void main() {
  test('muestra las etapas operativas de Sprint 3 por separado', () {
    expect(etiquetaEstadoSprint3('entrantes'), 'Pendiente');
    expect(etiquetaEstadoSprint3('aceptadas'), 'Aceptado');
    expect(etiquetaEstadoSprint3('iniciadas'), 'Aceptado');
    expect(etiquetaEstadoSprint3('en camino'), 'Activo');
    expect(etiquetaEstadoSprint3('en proceso'), 'En curso');
    expect(etiquetaEstadoSprint3('finalizadas'), 'Finalizado');
    expect(etiquetaEstadoSprint3('valor inesperado'), 'Estado desconocido');
  });
}
