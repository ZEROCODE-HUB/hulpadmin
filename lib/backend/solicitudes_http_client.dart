import 'dart:convert';
import 'package:http/http.dart' as http;

/// Conserva filtros y paginación PostgREST; el backend proyecta por rol.
/// Solo Test tiene activado el contrato financiero de esta entrega.
class SolicitudesHttpClient extends http.BaseClient {
  SolicitudesHttpClient({http.Client? client})
      : _inner = client ?? http.Client();
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final table = path.split('/').last;
    const protected = {
      'solicitudes_servicio',
      'vw_solicitudes_servicios_completa',
      'transacciones',
    };
    if (request.url.host != 'ptafsiwlhxomgqmdmidf.supabase.co' ||
        !path.startsWith('/rest/v1/') ||
        !protected.contains(table) ||
        (table == 'transacciones' && request.method != 'POST')) {
      return _inner.send(request);
    }
    final bytes = await request.finalize().toBytes();
    final proxy = http.Request(
      'POST',
      request.url
          .replace(path: '/functions/v1/solicitudes-finanzas', query: ''),
    );
    // Las cabeceras PostgREST viajan dentro del JSON. La petición externa
    // solo necesita autenticación: copiar Accept-Profile/Prefer exige CORS extra.
    for (final header in ['authorization', 'apikey', 'x-client-info']) {
      final value = request.headers[header];
      if (value != null) proxy.headers[header] = value;
    }
    proxy.headers['Content-Type'] = 'application/json';
    final queryHeaders =
        request.headers.map((key, value) => MapEntry(key.toLowerCase(), value));
    final prefer = queryHeaders['prefer'];
    if (prefer != null) {
      final normalized = prefer
          .replaceFirst(RegExp(r'^(?:null)+', caseSensitive: false), '')
          .trim();
      if (normalized.isEmpty) {
        queryHeaders.remove('prefer');
      } else {
        queryHeaders['prefer'] = normalized;
      }
    }
    proxy.body = jsonEncode({
      'accion': 'rest',
      'tabla': table,
      'metodo': request.method,
      'query': request.url.query,
      'headers': queryHeaders,
      'body': bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
    });
    return _inner.send(proxy);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
