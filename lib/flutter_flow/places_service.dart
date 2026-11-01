import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'ubicacion_helpers.dart';

/// Admite los componentes de Places (New) y de Geocoding. Nunca recorta nombres
/// dentro de una dirección libre: una calle puede llamarse igual que la ciudad.
String? direccionDesdeComponentesGoogle(dynamic componentes) {
  if (componentes is! List || componentes.isEmpty) return null;
  final partes = <({String texto, Set<String> tipos})>[];
  final ciudades = <String>{};
  const tiposCiudad = {'locality', 'postal_town'};

  for (final componente in componentes) {
    if (componente is! Map) return null;
    final texto = componente['longText'] ?? componente['long_name'];
    final tipos = componente['types'];
    if (texto is! String || texto.trim().isEmpty || tipos is! List) return null;
    final tiposParte = tipos.whereType<String>().toSet();
    if (tiposParte.isEmpty) return null;
    partes.add((texto: texto.trim(), tipos: tiposParte));
    if (tiposParte.intersection(tiposCiudad).isNotEmpty) {
      ciudades.add(texto.trim().toLowerCase());
      final corto = componente['shortText'] ?? componente['short_name'];
      if (corto is String) ciudades.add(corto.trim().toLowerCase());
    }
  }

  final conservadas = partes.where((parte) {
    if (parte.tipos.contains('country') ||
        parte.tipos.intersection(tiposCiudad).isNotEmpty) {
      return false;
    }
    // Google puede repetir el municipio como nivel 2. No se elimina ese nivel
    // por defecto: también representa provincias que deben conservarse.
    return !(parte.tipos.contains('administrative_area_level_2') &&
        ciudades.contains(parte.texto.toLowerCase()));
  }).toList();
  if (conservadas.isEmpty) return null;

  final calle = conservadas.indexWhere((p) => p.tipos.contains('route'));
  final numero =
      conservadas.indexWhere((p) => p.tipos.contains('street_number'));
  final textos = <String>[];
  for (var i = 0; i < conservadas.length; i++) {
    if (calle >= 0 && numero >= 0 && (i == calle || i == numero)) {
      if (i == min(calle, numero)) {
        textos.add('${conservadas[calle].texto} ${conservadas[numero].texto}');
      }
    } else {
      textos.add(conservadas[i].texto);
    }
  }
  return textos.join(', ');
}

/// Búsqueda de direcciones y geocodificación inversa contra las APIs de Google.
///
/// Todo por REST desde Dart, sin interoperabilidad: tanto Places (New) como
/// Geocoding responden con cabeceras CORS, así que el navegador las deja pasar.
/// La API antigua de Places NO las trae — si algún día alguien la sustituye
/// «porque es la que sale en los tutoriales», el autocompletado deja de
/// funcionar solo en el navegador y en local puede que no se note.

/// Una fila del desplegable de sugerencias.
class SugerenciaLugar {
  const SugerenciaLugar({
    required this.placeId,
    required this.principal,
    required this.secundario,
  });

  final String placeId;

  /// Lo que se resalta: normalmente la calle y el número.
  final String principal;

  /// El contexto: barrio, ciudad, país.
  final String secundario;

  String get completo =>
      secundario.isEmpty ? principal : '$principal, $secundario';
}

/// Un lugar ya resuelto, con su punto.
class LugarResuelto {
  const LugarResuelto({required this.coordenadas, required this.direccion});
  final Coordenadas coordenadas;
  final String direccion;
}

/// Elige la dirección más útil de una respuesta de geocodificación inversa.
///
/// **No vale con quedarse con el primer resultado.** Google ordena por
/// precisión geométrica, no por utilidad, y para muchos puntos el primero es un
/// *plus code* como `67P7PVQJ+X2` mientras el segundo es una calle con número.
/// Un plus code es una dirección válida y Google Maps la resuelve, pero al
/// proveedor le llega al teléfono un código que no le dice nada del sitio.
///
/// Orden de preferencia:
///   1. Algo con portal: `street_address`, `premise`, `subpremise`.
///   2. Cualquier cosa que no sea un plus code (una vía, un comercio).
///   3. Como último recurso, el primero que haya. Un plus code es mejor que
///      dejar la dirección vacía.
///
/// Público para poder probarlo: es la clase de lógica que se rompe en silencio.
String? elegirMejorDireccion(List<dynamic> resultados) {
  const conPortal = {'street_address', 'premise', 'subpremise'};

  String? texto(dynamic r) {
    if (r is! Map) return null;
    return direccionDesdeComponentesGoogle(r['address_components']);
  }

  Set<String> tipos(dynamic r) =>
      (r is Map ? r['types'] as List? : null)?.whereType<String>().toSet() ??
      const {};

  for (final r in resultados) {
    if (tipos(r).intersection(conPortal).isNotEmpty) {
      final t = texto(r);
      if (t != null) return t;
    }
  }
  for (final r in resultados) {
    if (tipos(r).contains('plus_code')) continue;
    final t = texto(r);
    if (t != null) return t;
  }
  for (final r in resultados) {
    final t = texto(r);
    if (t != null) return t;
  }
  return null;
}

class PlacesService {
  PlacesService(this.claveApi);

  final String claveApi;

  final _centrosCiudad = <String, Coordenadas>{};
  final _consultasCiudad = <String, Future<Coordenadas?>>{};

  /// Resuelve solo el encuadre de una ciudad. No crea una dirección ni un punto
  /// seleccionado; conserva en memoria éxitos y peticiones simultáneas.
  Future<Coordenadas?> resolverCentroCiudad(
    String ciudad, {
    String? departamento,
  }) async {
    final nombre = ciudad.trim();
    final region = departamento?.trim() ?? '';
    if (claveApi.isEmpty || nombre.isEmpty) return null;
    final identidad =
        '${_normalizarLugar(nombre)}|${_normalizarLugar(region)}|CO';
    final guardado = _centrosCiudad[identidad];
    if (guardado != null) return guardado;
    final pendiente = _consultasCiudad[identidad];
    if (pendiente != null) return pendiente;

    final consulta = _consultarCentroCiudad(nombre, region);
    _consultasCiudad[identidad] = consulta;
    try {
      final centro = await consulta;
      if (centro != null) _centrosCiudad[identidad] = centro;
      return centro;
    } finally {
      _consultasCiudad.remove(identidad);
    }
  }

  static String _normalizarLugar(String texto) {
    var normalizado = texto.toLowerCase();
    for (final par in const [
      ['á', 'a'],
      ['é', 'e'],
      ['í', 'i'],
      ['ó', 'o'],
      ['ú', 'u'],
      ['ü', 'u'],
    ]) {
      normalizado = normalizado.replaceAll(par[0], par[1]);
    }
    normalizado = normalizado.replaceAll(RegExp('[^a-z0-9ñ]'), '');
    return normalizado == 'bogotadc' ? 'bogota' : normalizado;
  }

  Future<Coordenadas?> _consultarCentroCiudad(
      String ciudad, String region) async {
    try {
      final respuesta = await http
          .get(Uri.https(
            'maps.googleapis.com',
            '/maps/api/geocode/json',
            {
              'address': [ciudad, if (region.isNotEmpty) region, 'Colombia']
                  .join(', '),
              'components': 'country:CO',
              'language': 'es',
              'key': claveApi,
            },
          ))
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) return null;
      final cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (cuerpo is! Map || cuerpo['status'] != 'OK') return null;
      final resultados = cuerpo['results'];
      if (resultados is! List) return null;
      final centros = <Coordenadas>{};
      for (final resultado in resultados.whereType<Map>()) {
        if (resultado['partial_match'] == true) continue;
        final tipos = (resultado['types'] as List?)?.whereType<String>() ?? [];
        if (!tipos.any(const {
          'locality',
          'postal_town',
          'administrative_area_level_2'
        }.contains)) {
          continue;
        }
        final componentes = resultado['address_components'];
        if (componentes is! List) continue;
        bool coincide(String tipo, String valor) =>
            componentes.whereType<Map>().any((c) {
              final tipos = c['types'];
              return tipos is List &&
                  tipos.contains(tipo) &&
                  [c['long_name'], c['short_name']].whereType<String>().any(
                        (nombre) =>
                            _normalizarLugar(nombre) == _normalizarLugar(valor),
                      );
            });
        if (!coincide('country', 'CO') ||
            !(coincide('locality', ciudad) ||
                coincide('postal_town', ciudad) ||
                coincide('administrative_area_level_2', ciudad)) ||
            (region.isNotEmpty &&
                !coincide('administrative_area_level_1', region))) {
          continue;
        }
        final ubicacion = resultado['geometry']?['location'];
        final lat = (ubicacion?['lat'] as num?)?.toDouble();
        final lng = (ubicacion?['lng'] as num?)?.toDouble();
        if (lat == null ||
            lng == null ||
            !lat.isFinite ||
            !lng.isFinite ||
            lat.abs() > 90 ||
            lng.abs() > 180) {
          continue;
        }
        centros.add(Coordenadas(lat, lng));
      }
      return centros.length == 1 ? centros.single : null;
    } catch (_) {
      return null;
    }
  }

  /// Identificador de sesión de facturación. Google cobra el autocompletado
  /// por sesión —muchas pulsaciones de tecla, un cobro— siempre que todas las
  /// peticiones lleven el mismo token y se cierre con un detalle de lugar.
  /// Sin él, cada tecla se factura por separado.
  String _sesion = _nuevaSesion();

  static String _nuevaSesion() {
    final r = Random();
    return List.generate(4, (_) => r.nextInt(0xFFFFFFFF).toRadixString(16))
        .join();
  }

  /// Sugerencias para lo que se va escribiendo.
  ///
  /// Sesgado a Colombia (`regionCode`), que es donde opera Hulp: sin eso, una
  /// «Carrera 70» devuelve resultados de medio mundo.
  Future<List<SugerenciaLugar>> sugerencias(String texto) async {
    final consulta = texto.trim();
    // Con menos de tres letras las sugerencias son ruido y cada llamada cuesta.
    if (claveApi.isEmpty || consulta.length < 3) return const [];

    try {
      final respuesta = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': claveApi,
        },
        body: jsonEncode({
          'input': consulta,
          'regionCode': 'CO',
          'languageCode': 'es',
          'sessionToken': _sesion,
        }),
      );
      if (respuesta.statusCode != 200) return const [];

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final lista = (cuerpo['suggestions'] as List?) ?? const [];

      return lista
          .map((e) => (e as Map<String, dynamic>)['placePrediction'])
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final formato = p['structuredFormat'] as Map<String, dynamic>?;
            final principal = (formato?['mainText']
                    as Map<String, dynamic>?)?['text'] as String? ??
                (p['text'] as Map<String, dynamic>?)?['text'] as String? ??
                '';
            final secundario = (formato?['secondaryText']
                    as Map<String, dynamic>?)?['text'] as String? ??
                '';
            return SugerenciaLugar(
              placeId: p['placeId'] as String? ?? '',
              principal: principal,
              secundario: secundario,
            );
          })
          .where((s) => s.placeId.isNotEmpty && s.principal.isNotEmpty)
          .toList();
    } catch (_) {
      // Sin red o clave inválida: se devuelve vacío y el campo de pegar sigue
      // estando ahí. El autocompletado es un atajo, no el único camino.
      return const [];
    }
  }

  /// Resuelve una sugerencia a punto y dirección. Cierra la sesión de cobro.
  Future<LugarResuelto?> detalle(String placeId) async {
    if (claveApi.isEmpty || placeId.isEmpty) return null;
    try {
      final respuesta = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'
            '?languageCode=es&sessionToken=$_sesion'),
        headers: {
          'X-Goog-Api-Key': claveApi,
          'X-Goog-FieldMask': 'location,addressComponents',
        },
      );
      // La sesión se cierra con el detalle, pase lo que pase: reutilizarla
      // después de cobrarla es lo que dispara la factura por pulsación.
      _sesion = _nuevaSesion();
      if (respuesta.statusCode != 200) return null;

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final punto = cuerpo['location'] as Map<String, dynamic>?;
      final lat = (punto?['latitude'] as num?)?.toDouble();
      final lng = (punto?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return LugarResuelto(
        coordenadas: Coordenadas(lat, lng),
        direccion:
            direccionDesdeComponentesGoogle(cuerpo['addressComponents']) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Del punto a la dirección legible, para cuando se marca en el mapa.
  ///
  /// Devuelve null si no hay resultado; quien llame debe dejar la dirección
  /// como esté, nunca vaciarla.
  Future<String?> direccionDe(double latitud, double longitud) async {
    if (claveApi.isEmpty) return null;
    try {
      final respuesta = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$latitud,$longitud&language=es&key=$claveApi',
      ));
      if (respuesta.statusCode != 200) return null;

      final cuerpo =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      if (cuerpo['status'] != 'OK') return null;

      return elegirMejorDireccion((cuerpo['results'] as List?) ?? const []);
    } catch (_) {
      return null;
    }
  }
}
