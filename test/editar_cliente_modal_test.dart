import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/direcciones_cliente.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/editar_cliente_modal.dart';

class Repo extends DireccionesClienteRepository {
  final rows = <Map<String, dynamic>>[
    {
      'id': 'a',
      'usuario_id': 'u',
      'tipo': 'casa',
      'direccion': 'Calle 1',
      'ciudad_id': 'cali',
      'latitud': 3.4,
      'longitud': -76.5
    },
    {
      'id': 'b',
      'usuario_id': 'u',
      'tipo': 'oficina',
      'direccion': 'Calle 2',
      'ciudad_id': 'cali'
    },
  ];
  Map<String, dynamic>? ultimo;
  @override
  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) async => [
        CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true})
      ];
  @override
  Future<List<DireccionCliente>> cargarTodas(String usuarioId) async =>
      rows.map((r) => DireccionCliente(Map.of(r))).toList();
  @override
  Future<DireccionCliente> actualizar(
      String usuarioId, String id, Map<String, dynamic> data,
      {bool activa = true}) async {
    expect(usuarioId, 'u');
    ultimo = Map.of(data);
    final i = rows.indexWhere((r) => r['id'] == id);
    rows[i] = {...rows[i], ...data};
    return DireccionCliente(Map.of(rows[i]));
  }

  @override
  Future<DireccionCliente> guardar(Map<String, dynamic> data) async {
    ultimo = Map.of(data);
    rows.add({...data, 'id': 'nueva'});
    return DireccionCliente(Map.of(rows.last));
  }

  @override
  Future<void> archivar(String usuarioId, String id) async {
    expect(usuarioId, 'u');
    rows.firstWhere((r) => r['id'] == id)['activo'] = false;
  }

  @override
  Future<void> desarchivar(String usuarioId, String id) async {
    expect(usuarioId, 'u');
    rows.firstWhere((r) => r['id'] == id)['activo'] = true;
  }
}

void main() {
  final perfil = UsuariosRow({
    'id': 'u',
    'nombres': 'Messi',
    'apellidos': 'Chavez',
    'telefono': '123',
    'correo_electronico': 'm@test.co',
    'ciudad': 'Cali'
  });
  Future<void> montar(WidgetTester tester, Repo repo,
      {Future<void> Function(String, String)? guardar}) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EditarClienteModal(
                perfil: perfil,
                repository: repo,
                guardarContacto: guardar,
                mapaBuilder: (_) => const SizedBox(
                    height: 30, child: Text('Mapa de prueba'))))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'guarda contacto de forma independiente y protege cambios sin guardar',
      (tester) async {
    final repo = Repo();
    var llamadas = 0;
    await montar(tester, repo, guardar: (t, c) async {
      llamadas++;
      expect(t, '456');
    });
    await tester.enterText(find.byType(TextFormField).first, '456');
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Cambios sin guardar'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(llamadas, 1);
    expect(repo.ultimo, isNull);
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Calle 1'), findsWidgets);
  });
  testWidgets('edita una dirección sin perder coordenadas y permite archivarla',
      (tester) async {
    final repo = Repo();
    await montar(tester, repo);
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Calle nueva');
    await tester.tap(find.text('Oficina').first);
    await tester.pumpAndSettle();
    expect(find.text('Cambios sin guardar'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar dirección'));
    await tester.pumpAndSettle();
    expect(repo.ultimo!['direccion'], 'Calle nueva');
    expect(repo.ultimo!['latitud'], 3.4);
    expect(repo.ultimo!['longitud'], -76.5);
    await tester.tap(find.text('Archivar dirección'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivar').last);
    await tester.pumpAndSettle();
    expect(repo.rows.length, 2);
    expect(repo.rows.first['activo'], false);
    expect(find.text('Archivada'), findsOneWidget);
    await tester.tap(find.text('Desarchivar dirección'));
    await tester.pumpAndSettle();
    expect(repo.rows.first['activo'], true);
    expect(find.text('Desarchivar dirección'), findsNothing);
  });
  testWidgets('agrega Otra con nombre, ciudad y datos completos',
      (tester) async {
    final repo = Repo();
    await montar(tester, repo);
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar dirección'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otra'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Casa de mamá');
    await tester.enterText(find.byType(TextFormField).at(1), 'Calle 3');
    await tester.enterText(find.byType(TextFormField).at(2), 'Torre A');
    await tester.tap(find.text('Seleccionar ciudad...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cali').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar dirección'));
    await tester.pumpAndSettle();
    expect(repo.rows.length, 3);
    expect(repo.ultimo!['nombre'], 'Casa de mamá');
    expect(repo.ultimo!['complemento'], 'Torre A');
    expect(repo.ultimo!['ciudad_id'], 'cali');
    expect(find.text('Direcciones (3)'), findsOneWidget);
  });
  testWidgets('complemento y referencia comparten fila en escritorio',
      (tester) async {
    await montar(tester, Repo());
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    final complemento = tester.getTopLeft(find.text('Complemento (opcional)'));
    final referencia = tester.getTopLeft(find.text('Referencia (opcional)'));
    expect(complemento.dy, closeTo(referencia.dy, 1));
    expect(referencia.dx, greaterThan(complemento.dx));
    expect(tester.takeException(), isNull);
  });
  testWidgets('en pantalla estrecha conserva acceso a los campos',
      (tester) async {
    await montar(tester, Repo());
    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Complemento (opcional)'), findsOneWidget);
    expect(find.text('Referencia (opcional)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'dirección archivada sin ciudad exige guardar una ciudad activa antes de desarchivar',
      (tester) async {
    final repo = Repo();
    repo.rows.first['activo'] = false;
    repo.rows.first['ciudad_id'] = null;
    await montar(tester, repo);
    await tester.tap(find.text('Direcciones (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desarchivar dirección'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Selecciona una ciudad activa y guarda la dirección antes de desarchivarla.'),
        findsOneWidget);
    expect(repo.rows.first['activo'], false);
    await tester.tap(find.text('Seleccionar ciudad...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cali').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar dirección'));
    await tester.pumpAndSettle();
    expect(repo.rows.first['activo'], false);
    expect(repo.rows.first['ciudad_id'], 'cali');
    await tester.tap(find.text('Desarchivar dirección'));
    await tester.pumpAndSettle();
    expect(repo.rows.first['activo'], true);
  });
}
