import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/supabase/database/database.dart';
import 'package:hulp_admin/backend/exportar_solicitudes.dart';

void main() {
  test('histórico conserva su fórmula y v1 usa pago guardado', () {
    final legacy = SolicitudesServicioRow({'precio': 180000});
    expect(legacy.importeProveedor(() => 180000 * .72), 129600);
    final nuevo = SolicitudesServicioRow({
      'finanzas_version': 1,
      'pago_proveedor': 86400,
      'precio': 120000,
      'materiales_total': 60000
    });
    expect(nuevo.importeProveedor(() => throw StateError('No recalcular v1')),
        86400);
    expect(
        () => SolicitudesServicioRow({'finanzas_version': 2})
            .importeProveedor(() => 0),
        throwsStateError);
    expect(
        () => SolicitudesServicioRow({'finanzas_version': 1})
            .importeProveedor(() => 0),
        throwsStateError);
  });

  test('Excel exporta valores guardados y texto escapado, sin fórmulas nuevas',
      () {
    final xml = solicitudesExcelXml([
      VwSolicitudesServiciosCompletaRow({
        'finanzas_version': 1,
        'precio_solicitud': 120000,
        'precio_base': 120000,
        'materiales_total': 60000,
        'total_cliente': 189000,
        'pago_proveedor': 86400,
        'adelanto_proveedor': 2000,
        'adelanto_motivo': 'Para su pasaje',
        'cliente_nombre_completo': 'Ana & Luis <Casa>',
        'informacion_adicional': '=1+1',
        'notas_cliente': 'Portería norte'
      }),
    ]);
    expect(xml, contains('189000'));
    expect(xml, contains('86400'));
    expect(xml, contains('Ana &amp; Luis &lt;Casa&gt;'));
    expect(xml, contains('ss:Type="String">=1+1'));
    expect(xml, isNot(contains('ss:Formula')));
    expect(xml, isNot(contains('Concepto adelanto')));
    expect(xml, contains('Motivo adelanto'));
    expect(xml, contains('Para su pasaje'));
    final rows = RegExp(r'<Row>(.*?)</Row>').allMatches(xml).toList();
    final headerCells = RegExp(r'<Cell>').allMatches(rows.first[1]!).length;
    expect(RegExp(r'<Cell>').allMatches(rows.last[1]!).length, headerCells);
  });
}
