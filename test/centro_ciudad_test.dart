import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp_admin/flutter_flow/centro_ciudad_controller.dart';
import 'package:hulp_admin/flutter_flow/places_service.dart';
import 'package:hulp_admin/flutter_flow/ubicacion_helpers.dart';

Map<String, dynamic> resultadoCiudad({
  String ciudad = 'Medellín',
  String departamento = 'Antioquia',
  String pais = 'CO',
  double latitud = 6.24,
  double longitud = -75.58,
}) =>
    {
      'types': ['locality', 'political'],
      'address_components': [
        {
          'long_name': ciudad,
          'types': ['locality']
        },
        {
          'long_name': departamento,
          'types': ['administrative_area_level_1']
        },
        {
          'short_name': pais,
          'types': ['country']
        },
      ],
      'geometry': {
        'location': {'lat': latitud, 'lng': longitud}
      },
    };

http.Response respuesta(List<dynamic> resultados) => http.Response(
      jsonEncode({'status': 'OK', 'results': resultados}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('valida ciudad/departamento/país y comparte peticiones concurrentes',
      () async {
    var consultas = 0;
    final pendiente = Completer<http.Response>();
    await http.runWithClient(() async {
      final servicio = PlacesService('test');
      final primero =
          servicio.resolverCentroCiudad('Medellín', departamento: 'Antioquia');
      final segundo =
          servicio.resolverCentroCiudad('Medellín', departamento: 'Antioquia');
      pendiente.complete(respuesta([
        resultadoCiudad(ciudad: 'Cali'),
        resultadoCiudad(pais: 'US'),
        resultadoCiudad(departamento: 'Otro'),
        resultadoCiudad(),
      ]));
      expect(await primero, const Coordenadas(6.24, -75.58));
      expect(await segundo, const Coordenadas(6.24, -75.58));
      expect(
          await servicio.resolverCentroCiudad('medellin',
              departamento: 'Antioquia'),
          const Coordenadas(6.24, -75.58));
      expect(consultas, 1);
    },
        () => MockClient((request) {
              consultas++;
              expect(request.url.queryParameters['address'],
                  'Medellín, Antioquia, Colombia');
              expect(request.url.queryParameters['components'], 'country:CO');
              return pendiente.future;
            }));
  });

  test('no guarda fallos en caché y rechaza resultados parciales o ambiguos',
      () async {
    var consultas = 0;
    await http.runWithClient(() async {
      final servicio = PlacesService('test');
      expect(await servicio.resolverCentroCiudad('Medellín'), isNull);
      expect(await servicio.resolverCentroCiudad('Medellín'), isNull);
      expect(await servicio.resolverCentroCiudad('Medellín'),
          const Coordenadas(6.24, -75.58));
      expect(consultas, 3);
    },
        () => MockClient((_) async {
              consultas++;
              if (consultas == 1) {
                return respuesta([
                  {...resultadoCiudad(), 'partial_match': true}
                ]);
              }
              if (consultas == 2) {
                return respuesta(
                    [resultadoCiudad(), resultadoCiudad(latitud: 7)]);
              }
              return respuesta([resultadoCiudad()]);
            }));
  });

  test('reconoce Bogotá D.C. y no acepta direcciones como centro de ciudad',
      () async {
    await http.runWithClient(() async {
      expect(await PlacesService('test').resolverCentroCiudad('Bogotá D.C.'),
          const Coordenadas(4.71, -74.07));
    },
        () => MockClient((_) async => respuesta([
              {
                ...resultadoCiudad(ciudad: 'Bogotá'),
                'types': ['street_address']
              },
              resultadoCiudad(
                  ciudad: 'Bogotá',
                  departamento: 'Bogotá D.C.',
                  latitud: 4.71,
                  longitud: -74.07),
            ])));
  });

  test('error de Google o coordenadas inválidas no producen centro ficticio',
      () async {
    var consultas = 0;
    await http.runWithClient(() async {
      final servicio = PlacesService('test');
      expect(await servicio.resolverCentroCiudad('Medellín'), isNull);
      expect(await servicio.resolverCentroCiudad('Medellín'), isNull);
      expect(await servicio.resolverCentroCiudad(''), isNull);
    },
        () => MockClient((_) async => ++consultas == 1
            ? http.Response('error', 403)
            : respuesta([resultadoCiudad(latitud: 100)])));
  });

  test('un resultado antiguo no sustituye el centro de la ciudad nueva',
      () async {
    final medellin = Completer<Coordenadas?>();
    final cali = Completer<Coordenadas?>();
    var consultas = 0;
    final controlador = CentroCiudadController((id, nombre) {
      consultas++;
      return id == 'med' ? medellin.future : cali.future;
    });
    addTearDown(controlador.dispose);
    final anterior = controlador.actualizar('med', null);
    final actual = controlador.actualizar('cali', null);
    cali.complete(const Coordenadas(3.45, -76.53));
    await actual;
    medellin.complete(null);
    await anterior;
    expect(controlador.centro, const Coordenadas(3.45, -76.53));
    expect(controlador.fallo, isFalse);
    await controlador.actualizar('cali', null);
    expect(consultas, 2);
  });

  test('quitar ciudad o cerrar el formulario descarta resoluciones pendientes',
      () async {
    final pendiente = Completer<Coordenadas?>();
    final controlador =
        CentroCiudadController((id, nombre) => pendiente.future);
    final tarea = controlador.actualizar('med', null);
    await controlador.actualizar(null, null);
    expect(controlador.centro, isNull);
    expect(controlador.fallo, isFalse);
    controlador.dispose();
    pendiente.complete(const Coordenadas(6.24, -75.58));
    await tarea;
    expect(controlador.centro, isNull);
  });
}
