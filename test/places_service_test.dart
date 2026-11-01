import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp_admin/flutter_flow/places_service.dart';

Map<String, dynamic> componente(String texto, String tipo,
        {bool nuevo = false}) =>
    {
      nuevo ? 'longText' : 'long_name': texto,
      'types': [tipo]
    };

void main() {
  // Fixtures de ambos contratos de Google; no hacen llamadas a la API real.
  List<Map<String, dynamic>> componentes({bool nuevo = false}) => [
        componente('43A-50', 'street_number', nuevo: nuevo),
        componente('Calle Medellín', 'route', nuevo: nuevo),
        componente('Edificio Colombia', 'premise', nuevo: nuevo),
        componente('Apto 712', 'subpremise', nuevo: nuevo),
        componente('El Poblado', 'neighborhood', nuevo: nuevo),
        componente('Medellín', 'locality', nuevo: nuevo),
        componente('Medellín', 'administrative_area_level_2', nuevo: nuevo),
        componente('Antioquia', 'administrative_area_level_1', nuevo: nuevo),
        componente('Colombia', 'country', nuevo: nuevo),
        componente('050021', 'postal_code', nuevo: nuevo),
      ];

  Map<String, dynamic> resultado(List<String> tipos, String texto) => {
        'types': tipos,
        'address_components': [
          componente(
              texto, tipos.contains('plus_code') ? 'plus_code' : 'route'),
          componente('Bogotá', 'locality'),
          componente('Colombia', 'country'),
        ],
      };

  test('Places y Geocoding omiten solo ciudad/país y conservan los demás datos',
      () {
    for (final nuevo in [true, false]) {
      expect(
        direccionDesdeComponentesGoogle(componentes(nuevo: nuevo)),
        'Calle Medellín 43A-50, Edificio Colombia, Apto 712, El Poblado, Antioquia, 050021',
      );
    }
  });

  test('no elimina un departamento o provincia aunque tengan nombre de ciudad',
      () {
    expect(
      direccionDesdeComponentesGoogle([
        componente('Calle 1', 'route'),
        componente('Bogotá', 'locality'),
        componente('Bogotá', 'administrative_area_level_1'),
        componente('Provincia distinta', 'administrative_area_level_2'),
        componente('Colombia', 'country'),
      ]),
      'Calle 1, Bogotá, Provincia distinta',
    );
  });

  test('sin componentes suficientes no inventa una dirección ni devuelve vacío',
      () {
    for (final entrada in [
      null,
      [],
      [componente('Medellín', 'locality'), componente('Colombia', 'country')],
      [
        {'longText': 'Cali'}
      ],
    ]) {
      expect(direccionDesdeComponentesGoogle(entrada), isNull);
    }
  });

  group('elegirMejorDireccion', () {
    test('salta el plus code y prefiere el portal a la vía', () {
      expect(
          elegirMejorDireccion([
            resultado(['plus_code'], '67P7PVQJ+X2'),
            resultado(['route'], 'Calle sin portal'),
            resultado(['street_address'], 'Calle 129c #152-89'),
          ]),
          'Calle 129c #152-89');
    });

    test('sin portal, sirve la vía antes que un plus code', () {
      expect(
          elegirMejorDireccion([
            resultado(['plus_code'], '67P7MW54+6Q'),
            resultado(['route'], 'Unnamed Road'),
          ]),
          'Unnamed Road');
    });

    test('si solo hay plus code lo conserva sin ciudad/país', () {
      expect(
          elegirMejorDireccion([
            resultado(['plus_code'], '67P7MW54+6Q'),
          ]),
          '67P7MW54+6Q');
    });

    test('ignora resultados sin componentes, sin reutilizar texto sin filtrar',
        () {
      expect(
          elegirMejorDireccion([
            {
              'types': ['street_address'],
              'formatted_address': 'Calle, Cali, Colombia'
            },
            resultado(['route'], 'Calle 1'),
          ]),
          'Calle 1');
      expect(elegirMejorDireccion([]), isNull);
    });
  });

  test(
      'detalle solicita componentes y devuelve dirección filtrada y el mismo punto',
      () async {
    await http.runWithClient(() async {
      final lugar = await PlacesService('test-key').detalle('test-place');
      expect(lugar!.coordenadas.latitud, 6.2);
      expect(lugar.coordenadas.longitud, -75.5);
      expect(lugar.direccion, contains('Edificio Colombia'));
      expect(lugar.direccion, isNot(contains(', Medellín')));
      expect(lugar.direccion, endsWith('Antioquia, 050021'));
    },
        () => MockClient((request) async {
              expect(request.headers['X-Goog-FieldMask'],
                  'location,addressComponents');
              return http.Response(
                  jsonEncode({
                    'location': {'latitude': 6.2, 'longitude': -75.5},
                    'addressComponents': componentes(nuevo: true),
                  }),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
  });

  test('geocodificación inversa también devuelve el texto filtrado', () async {
    await http.runWithClient(() async {
      final direccion = await PlacesService('test-key').direccionDe(6.2, -75.5);
      expect(direccion, startsWith('Calle Medellín 43A-50'));
      expect(direccion, contains('Apto 712'));
      expect(direccion, isNot(contains(', Medellín')));
      expect(direccion, endsWith('Antioquia, 050021'));
    },
        () => MockClient((request) async => http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'types': ['street_address'],
                  'address_components': componentes()
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
  });
}
