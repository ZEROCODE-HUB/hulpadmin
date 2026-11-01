import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/flutter_flow/direccion_solicitud_helpers.dart';

void main() {
  test('oculta Colombia como país y conserva complementos y nombres propios',
      () {
    expect(
      direccionSolicitudVisible(
          'Yumbo\nCra. 4 #5-57, Yumbo, Valle del Cauca, Colombia', 'Yumbo'),
      'Cra. 4 #5-57, Yumbo, Valle del Cauca',
    );
    expect(
      direccionSolicitudVisible(
          'Cali\r\nCalle 1, COLOMBIA\r\nTorre B, apto 302', 'Cali'),
      'Calle 1\nTorre B, apto 302',
    );
    expect(
        direccionSolicitudVisible('Avenida Colombia, Edificio Colombia', null),
        'Avenida Colombia, Edificio Colombia');
    expect(direccionSolicitudVisible('Colombia', null),
        'Sin dirección registrada');
  });

  test('oculta solo prefijos delimitados y conserva todo el complemento', () {
    expect(
      direccionSolicitudVisible(
        'Medellín\r\nCalle 48C sur #43A-50\napto 712, Ciudadela Real / referencia',
        'Medellín',
      ),
      'Calle 48C sur #43A-50\napto 712, Ciudadela Real / referencia',
    );
    expect(direccionSolicitudVisible(' cali, CALI\nCalle 1, torre B', ' Cali '),
        'Calle 1, torre B');
  });

  test('conserva nombres de calles, edificios y ciudades sin identificar', () {
    for (final direccion in [
      'Calle Medellín #12-34, Edificio Medellín',
      'Medellín del Norte, Calle 1',
      'Calle 1, Medellín, Antioquia',
      'Conjunto Ciudad de Cali, apto 3',
    ]) {
      expect(direccionSolicitudVisible(direccion, 'Medellín'), direccion);
    }
    expect(direccionSolicitudVisible('Medellín\nCalle 1', null),
        'Medellín\nCalle 1');
  });

  test('maneja ciudad con caracteres de regex y ausencia de dirección', () {
    expect(direccionSolicitudVisible('Bogotá D.C., Calle 1', 'Bogotá D.C.'),
        'Calle 1');
    expect(direccionSolicitudVisible('Bogotá DxCx, Calle 1', 'Bogotá D.C.'),
        'Bogotá DxCx, Calle 1');
    expect(direccionSolicitudVisible(null, 'Cali'), 'Sin dirección registrada');
    expect(
        direccionSolicitudVisible('Cali', 'Cali'), 'Sin dirección registrada');
  });
}
