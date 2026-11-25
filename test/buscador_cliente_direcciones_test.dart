import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/direcciones_cliente.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/buscador_cliente_direcciones.dart';
import 'package:hulp_admin/components/agregar_direccion_cliente_widget.dart';

class RepoBusqueda extends DireccionesClienteRepository {
  final llamadas = <List<String>>[];
  final pendientes = <Completer<List<DireccionCliente>>>[];
  bool inmediato = true;
  bool fallar = false;
  @override
  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) async => [
        CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true})
      ];
  @override
  Future<List<DireccionCliente>> cargarClientes(List<String> ids) async {
    llamadas.add(ids);
    if (fallar) throw Exception('red');
    if (!inmediato) {
      final c = Completer<List<DireccionCliente>>();
      pendientes.add(c);
      return c.future;
    }
    return [
      for (final id in ids)
        DireccionCliente({
          'id': 'dir_$id',
          'usuario_id': id,
          'tipo': 'casa',
          'direccion': 'Calle de $id',
          'ciudad_id': 'cali'
        })
    ];
  }
}

void main() {
  final clientes = [
    UsuariosRow({
      'id': 'a',
      'nombres': 'Paola',
      'apellidos': 'Ochoa',
      'rol': 'usuario',
      'ciudad': 'Cali',
      'telefono': '+57 300-111-2233',
      'correo_electronico': 'paola@test.co'
    }),
    UsuariosRow({
      'id': 'b',
      'nombres': 'Pedro',
      'apellidos': 'Rojas',
      'rol': 'usuario',
      'ciudad': 'Cali',
      'telefono': '3012223344',
      'correo_electronico': 'pedro@test.co'
    }),
  ];
  Future<void> montar(WidgetTester tester, RepoBusqueda repo,
      ValueChanged<SeleccionClienteDireccion> elegir) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 600,
                child: BuscadorClienteDirecciones(
                    clientes: clientes,
                    repository: repo,
                    onSeleccion: elegir)))));
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('abrir_buscador_clientes')));
    await tester.pump();
  }

  testWidgets(
      'carga las direcciones por lote y selecciona cliente con dirección',
      (tester) async {
    final repo = RepoBusqueda();
    SeleccionClienteDireccion? elegido;
    await montar(tester, repo, (v) => elegido = v);
    await tester.pumpAndSettle();
    expect(repo.llamadas, [
      ['a', 'b']
    ]);
    expect(find.text('Paola Ochoa · Cali'), findsOneWidget);
    expect(find.byKey(const ValueKey('resultado_direccion_dir_a')),
        findsOneWidget);
    expect(find.textContaining('Última vez'), findsNothing);
    expect(find.byKey(const ValueKey('quick_add_cliente')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resultado_direccion_dir_a')));
    await tester.pumpAndSettle();
    expect(elegido?.cliente.id, 'a');
    expect(elegido?.direccion?.id, 'dir_a');
    expect(
        find.byKey(const ValueKey('resultado_direccion_dir_a')), findsNothing);
  });

  testWidgets('busca por teléfono sin formato y descarta consultas anteriores',
      (tester) async {
    final repo = RepoBusqueda()..inmediato = false;
    await montar(tester, repo, (_) {});
    await tester.pump();
    await tester.enterText(find.byType(TextField), '3001112233');
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.llamadas.last, ['a']);
    repo.pendientes.last.complete([
      DireccionCliente({
        'id': 'actual',
        'usuario_id': 'a',
        'tipo': 'oficina',
        'direccion': 'Resultado actual'
      })
    ]);
    await tester.pumpAndSettle();
    repo.pendientes.first.complete([
      DireccionCliente({
        'id': 'viejo',
        'usuario_id': 'b',
        'tipo': 'casa',
        'direccion': 'Resultado obsoleto'
      })
    ]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resultado_direccion_actual')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('resultado_direccion_viejo')), findsNothing);
    expect(find.text('Pedro Rojas · Cali'), findsNothing);
  });

  testWidgets('busca por correo y permite elegir solo al cliente',
      (tester) async {
    SeleccionClienteDireccion? elegido;
    await montar(tester, RepoBusqueda(), (v) => elegido = v);
    await tester.enterText(find.byType(TextField), 'pedro@test.co');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cliente_b')));
    await tester.pumpAndSettle();
    expect(elegido?.cliente.id, 'b');
    expect(elegido?.direccion, isNull);
  });

  testWidgets('agregar otra abre el modal para el cliente de ese resultado',
      (tester) async {
    await montar(tester, RepoBusqueda(), (_) {});
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('agregar_direccion_b')));
    await tester.tap(find.byKey(const ValueKey('agregar_direccion_b')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AgregarDireccionClienteWidget>(
                find.byType(AgregarDireccionClienteWidget))
            .usuarioId,
        'b');
    expect(find.text('Cliente: Pedro Rojas'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cliente_b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reintenta cuando falla la carga de direcciones', (tester) async {
    final repo = RepoBusqueda()..fallar = true;
    await montar(tester, repo, (_) {});
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar las direcciones.'), findsOneWidget);
    repo.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resultado_direccion_dir_a')),
        findsOneWidget);
  });
}
