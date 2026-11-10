import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp_admin/backend/solicitudes_http_client.dart';

void main() {
  test('Test conserva filtros, sesión y selección a través del backend',
      () async {
    final client = SolicitudesHttpClient(client: MockClient((request) async {
      expect(request.url.path, '/functions/v1/solicitudes-finanzas');
      final body = jsonDecode(request.body);
      expect(body['query'], 'select=id&estado=eq.entrantes&limit=10');
      expect(body['metodo'], 'GET');
      expect(request.headers['authorization'], 'Bearer sesion-prueba');
      return http.Response('[{"id":"solicitud"}]', 200);
    }));
    final response = await client.get(
        Uri.parse(
            'https://ptafsiwlhxomgqmdmidf.supabase.co/rest/v1/solicitudes_servicio?select=id&estado=eq.entrantes&limit=10'),
        headers: {'Authorization': 'Bearer sesion-prueba'});
    expect(jsonDecode(response.body).single['id'], 'solicitud');
    client.close();
  });

  test('otros proyectos y otras tablas conservan su conexión original',
      () async {
    final client = SolicitudesHttpClient(client: MockClient((request) async {
      expect(request.url.path, startsWith('/rest/v1/'));
      return http.Response('[]', 200);
    }));
    await client.get(Uri.parse(
        'https://zexegravzidwloxeimxx.supabase.co/rest/v1/solicitudes_servicio'));
    await client.get(
        Uri.parse('https://ptafsiwlhxomgqmdmidf.supabase.co/rest/v1/ciudades'));
    client.close();
  });

  test('CORS: solo envía cabeceras de la función y conserva PostgREST en JSON',
      () async {
    final client = SolicitudesHttpClient(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers.keys.map((key) => key.toLowerCase()).toSet(), {
        'authorization',
        'apikey',
        'x-client-info',
        'content-type',
      });
      expect(request.headers['apikey'], 'clave-publica-prueba');
      final body = jsonDecode(request.body);
      final headers = Map<String, dynamic>.from(body['headers']);
      expect(headers['accept-profile'], 'public');
      expect(headers['content-profile'], 'public');
      expect(headers['accept'], 'application/vnd.pgrst.object+json');
      expect(headers['range'], '0-9');
      expect(headers['prefer'], 'return=representation');
      expect(body['query'], 'select=%2A');
      return http.Response('[]', 200);
    }));
    await client.get(
      Uri.parse(
          'https://ptafsiwlhxomgqmdmidf.supabase.co/rest/v1/solicitudes_servicio?select=%2A'),
      headers: {
        'Authorization': 'Bearer sesion-prueba',
        'apikey': 'clave-publica-prueba',
        'X-Client-Info': 'flutterflow',
        'Accept-Profile': 'public',
        'Content-Profile': 'public',
        'Accept': 'application/vnd.pgrst.object+json',
        'Range': '0-9',
        'Prefer': 'nullreturn=representation',
      },
    );
    client.close();
  });
}
