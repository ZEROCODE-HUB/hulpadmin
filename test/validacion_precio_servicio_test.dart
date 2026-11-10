import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/flutter_flow/validacion_precio_servicio.dart';

void main() {
  test('exige un precio numérico de al menos 1500 COP', () {
    expect(validarPrecioNuevoServicio(''), 'Ingresa el precio base');
    for (final valor in ['abc', '1500abc', '1e5', 'NaN', '-1500']) {
      expect(validarPrecioNuevoServicio(valor),
          'Ingresa un precio numérico válido');
    }
    for (final valor in ['0', '1499', '1499.99']) {
      expect(
          validarPrecioNuevoServicio(valor), r'El precio mínimo es $1.500 COP');
    }
    for (final valor in ['1500', ' 1500.50 ', '10000']) {
      expect(validarPrecioNuevoServicio(valor), isNull);
    }
  });
}
