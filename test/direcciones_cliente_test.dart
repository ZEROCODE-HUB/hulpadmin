import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/direcciones_cliente.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/agregar_direccion_cliente_widget.dart';
import 'package:hulp_admin/components/direcciones_cliente_selector.dart';
import 'package:hulp_admin/flutter_flow/ubicacion_helpers.dart';

class RepositorioPrueba extends DireccionesClienteRepository {
  Map<String, dynamic>? guardado;
  bool fallar = false;
  final pendientes = <String, Completer<List<DireccionCliente>>>{};
  @override
  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) async => [
        CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true})
      ];
  @override
  Future<List<DireccionCliente>> cargar(String id) =>
      pendientes.putIfAbsent(id, () => Completer()).future;
  @override
  Future<DireccionCliente> guardar(Map<String, dynamic> data) async {
    if (fallar) throw Exception('sin conexión');
    guardado = data;
    return DireccionCliente({...data, 'id': 'nueva'});
  }
}

void main() {
  for (final size in [const Size(320, 640), const Size(1200, 900)]) {
    testWidgets('modal adaptable con encabezado fijo a ${size.width}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: AgregarDireccionClienteWidget(
                  usuarioId: 'u',
                  nombreCliente: 'Paola Andrea Ochoa',
                  repository: RepositorioPrueba()))));
      await tester.pumpAndSettle();
      final campos = find.byKey(const ValueKey('campos_direccion'));
      final mapa = find.byKey(const ValueKey('mapa_direccion'));
      final titulo = find.text('Agregar dirección');
      final cerrar = find.byTooltip('Cerrar');
      expect(tester.getCenter(titulo).dx,
          closeTo(tester.getCenter(find.byType(Dialog)).dx, 1));
      if (size.width > 650) {
        expect(tester.getTopLeft(mapa).dx,
            greaterThan(tester.getTopRight(campos).dx));
        expect(tester.getTopLeft(mapa).dy,
            closeTo(tester.getTopLeft(campos).dy, 1));
      } else {
        final posicionCerrar = tester.getCenter(cerrar);
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.getCenter(cerrar), posicionCerrar);
        expect(cerrar.hitTestable(), findsOneWidget);
        expect(find.text('Guardar dirección').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test(
      'compone dirección completa sin separadores vacíos y conserva coordenadas',
      () {
    final d = DireccionCliente({
      'id': 'a',
      'usuario_id': 'u',
      'tipo': 'otra',
      'nombre': 'Casa de la mamá',
      'direccion': ' Calle 1 #2 ',
      'complemento': ' Apto 3 ',
      'referencia': '',
      'latitud': 3,
      'longitud': -76
    });
    expect(d.completa, 'Calle 1 #2, Apto 3');
    expect(d.etiqueta, 'Casa de la mamá');
    expect(d.punto, const Coordenadas(3, -76));
  });

  testWidgets('descarta la carga del cliente anterior', (tester) async {
    final repo = RepositorioPrueba();
    DireccionCliente? seleccion;
    Widget montar(String usuario) => MaterialApp(
        home: Scaffold(
            body: DireccionesClienteSelector(
                usuarioId: usuario,
                nombreCliente: usuario,
                repository: repo,
                onSeleccion: (d) => seleccion = d)));
    await tester.pumpWidget(montar('a'));
    await tester.pumpWidget(montar('b'));
    repo.pendientes['b']!.complete([
      DireccionCliente({
        'id': 'b1',
        'usuario_id': 'b',
        'tipo': 'casa',
        'direccion': 'Calle B'
      })
    ]);
    await tester.pumpAndSettle();
    repo.pendientes['a']!.complete([
      DireccionCliente({
        'id': 'a1',
        'usuario_id': 'a',
        'tipo': 'oficina',
        'direccion': 'Calle A'
      })
    ]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Calle A'), findsNothing);
    expect(find.byTooltip('Casa · Calle B'), findsOneWidget);
    expect(seleccion, isNull);
    await tester.tap(find.byKey(const ValueKey('direccion_b1')));
    expect(seleccion?.id, 'b1');
  });

  testWidgets(
      'dirección larga ocupa una línea y mantiene el detalle en el tooltip',
      (tester) async {
    final repo = RepositorioPrueba();
    const direccion =
        'Calle 31 #11B-46, apartamento 712, Torre A, conjunto Benjamín Herrera';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 300,
                child: DireccionesClienteSelector(
                    usuarioId: 'a',
                    nombreCliente: 'Paola',
                    seleccionada: 'casa',
                    repository: repo,
                    onSeleccion: (_) {})))));
    repo.pendientes['a']!.complete([
      DireccionCliente({
        'id': 'casa',
        'usuario_id': 'a',
        'tipo': 'casa',
        'direccion': direccion,
      })
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Casa · $direccion'), findsOneWidget);
    final opcion = find.byKey(const ValueKey('direccion_casa'));
    expect(tester.widget<Material>(opcion).elevation, 0);
    expect(tester.getSize(opcion).width, lessThanOrEqualTo(300));
    final texto = tester.widget<Text>(find.text('Casa · $direccion'));
    expect(texto.maxLines, 1);
    expect(texto.overflow, TextOverflow.ellipsis);
    expect(find.byTooltip('Casa · $direccion'), findsOneWidget);
    expect(find.text('Otra').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Otra comparte fila con las direcciones cuando hay espacio',
      (tester) async {
    final repo = RepositorioPrueba();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 650,
                child: DireccionesClienteSelector(
                    usuarioId: 'a',
                    nombreCliente: 'Paola',
                    seleccionada: 'casa',
                    repository: repo,
                    onSeleccion: (_) {})))));
    repo.pendientes['a']!.complete([
      DireccionCliente({
        'id': 'casa',
        'usuario_id': 'a',
        'tipo': 'casa',
        'direccion': 'Calle 1'
      }),
      DireccionCliente({
        'id': 'oficina',
        'usuario_id': 'a',
        'tipo': 'oficina',
        'direccion': 'Calle 2'
      }),
    ]);
    await tester.pumpAndSettle();
    final casa = find.byKey(const ValueKey('direccion_casa'));
    final oficina = find.byKey(const ValueKey('direccion_oficina'));
    final otra = find.widgetWithText(TextButton, 'Otra');
    expect(tester.getCenter(casa).dy, closeTo(tester.getCenter(oficina).dy, 1));
    expect(tester.getCenter(casa).dy, closeTo(tester.getCenter(otra).dy, 1));
    expect(tester.takeException(), isNull);
  });

  for (final fallar in [false, true]) {
    testWidgets(
        'Otra valida nombre y ${fallar ? 'conserva datos al fallar' : 'guarda datos completos'}',
        (tester) async {
      final repo = RepositorioPrueba()..fallar = fallar;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => AgregarDireccionClienteWidget(
                              usuarioId: 'u',
                              nombreCliente: 'Paola',
                              repository: repo)),
                      child: const Text('Abrir'))))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Otra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar dirección'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un nombre'), findsOneWidget);
      expect(repo.guardado, isNull);
      await tester.enterText(
          find.byType(TextFormField).at(0), 'Casa de la mamá');
      await tester.enterText(find.byType(TextFormField).at(1), 'Calle 1 #2');
      await tester.enterText(
          find.byType(TextFormField).at(2), 'Apto 3, Torre A');
      await tester.enterText(
          find.byType(TextFormField).at(3), 'Portería norte');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cali').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar dirección'));
      await tester.pumpAndSettle();
      if (fallar) {
        expect(find.textContaining('No se pudo guardar la dirección'),
            findsOneWidget);
        expect(find.text('Casa de la mamá'), findsOneWidget);
        expect(find.byType(AgregarDireccionClienteWidget), findsOneWidget);
      } else {
        expect(repo.guardado?['usuario_id'], 'u');
        expect(repo.guardado?['tipo'], 'otra');
        expect(repo.guardado?['ciudad_id'], 'cali');
        expect(repo.guardado?['complemento'], 'Apto 3, Torre A');
        expect(repo.guardado?['referencia'], 'Portería norte');
        expect(repo.guardado?['latitud'], isNull);
        expect(find.byType(AgregarDireccionClienteWidget), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
