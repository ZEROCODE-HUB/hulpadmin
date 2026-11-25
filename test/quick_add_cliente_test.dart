import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/quick_add_cliente.dart';
import 'package:hulp_admin/backend/direcciones_cliente.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/buscador_cliente_direcciones.dart';

class CiudadesPrueba extends DireccionesClienteRepository {
  @override
  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) async => [
        CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true}),
      ];
}

class AltaPrueba extends QuickAddClienteRepository {
  int llamadas = 0;
  bool fallar = false;
  bool existente = false;
  Completer<ResultadoQuickAdd>? pendiente;
  final requests = <String>[];
  Map<String, dynamic>? direccion;
  String? nombre;
  String? apellido;
  String? telefono;
  final cliente = UsuariosRow({
    'id': 'nuevo',
    'nombres': 'Paola Andrea',
    'apellidos': 'Ochoa',
    'rol': 'usuario',
    'telefono': '3001234567',
    'correo_electronico': null
  });
  ResultadoQuickAdd get resultado => ResultadoQuickAdd(
      cliente,
      DireccionCliente({
        'id': 'dir',
        'usuario_id': 'nuevo',
        'tipo': 'casa',
        'direccion': 'Calle 1 #2',
        'ciudad_id': 'cali'
      }),
      existente: existente);
  @override
  Future<ResultadoQuickAdd> crear(
      {required String requestId,
      required String nombre,
      required String apellido,
      required String telefono,
      required Map<String, dynamic> direccion}) async {
    llamadas++;
    requests.add(requestId);
    this.nombre = nombre;
    this.apellido = apellido;
    this.telefono = telefono;
    this.direccion = direccion;
    if (fallar) {
      throw const QuickAddException(
          'No se pudo completar el alta. Vuelve a guardar.');
    }
    return pendiente?.future ?? Future.value(resultado);
  }
}

void main() {
  Future<void> abrir(WidgetTester tester, AltaPrueba repo,
      {ValueChanged<SeleccionClienteDireccion>? elegir,
      String busqueda = 'Paola Andrea Ochoa'}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BuscadorClienteDirecciones(
                clientes: const [],
                repository: CiudadesPrueba(),
                quickAdd: repo,
                ciudadInicial: 'cali',
                onSeleccion: elegir ?? (_) {}))));
    await tester.tap(find.byKey(const ValueKey('abrir_buscador_clientes')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), busqueda);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick_add_cliente')));
    await tester.pumpAndSettle();
  }

  Finder campo(String hint) => find.ancestor(
      of: find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == hint),
      matching: find.byType(TextFormField));
  Future<void> completar(WidgetTester t) async {
    await t.ensureVisible(campo('Nombre del cliente'));
    await t.enterText(campo('Nombre del cliente'), 'Paola Andrea');
    await t.ensureVisible(campo('Apellido del cliente'));
    await t.enterText(campo('Apellido del cliente'), 'Ochoa');
    await t.enterText(campo('300 123 4567'), '3001234567');
    await t.ensureVisible(campo('Calle y número'));
    await t.enterText(campo('Calle y número'), 'Calle 1 #2');
  }

  final guardar = find.text('Crear y seleccionar cliente');

  test('normaliza celular local y con prefijo', () {
    expect(normalizarCelularCliente('300 123-4567'), '573001234567');
    expect(normalizarCelularCliente('+57 (300) 1234567'), '573001234567');
  });
  testWidgets('valida mínimos y no exige correo ni documento', (t) async {
    final r = AltaPrueba();
    await abrir(t, r);
    expect(find.text('Correo electrónico'), findsNothing);
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(r.llamadas, 0);
    expect(find.text('Escribe el apellido'), findsOneWidget);
    expect(find.text('Ingresa un celular colombiano de 10 dígitos'),
        findsOneWidget);
    await completar(t);
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(r.llamadas, 1);
    expect(r.nombre, 'Paola Andrea');
    expect(r.apellido, 'Ochoa');
    expect(r.direccion?['ciudad_id'], 'cali');
  });
  testWidgets('selecciona cliente nuevo y dirección cerrando ambos modales',
      (t) async {
    SeleccionClienteDireccion? elegido;
    await abrir(t, AltaPrueba(), elegir: (v) => elegido = v);
    await completar(t);
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(elegido?.cliente.id, 'nuevo');
    expect(elegido?.direccion?.id, 'dir');
    expect(find.byType(Dialog), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('conserva datos e identificador al reintentar un error',
      (t) async {
    final r = AltaPrueba()..fallar = true;
    await abrir(t, r);
    await completar(t);
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(find.textContaining('No se pudo completar el alta'), findsOneWidget);
    expect(t.widget<TextFormField>(campo('Calle y número')).controller?.text,
        'Calle 1 #2');
    r.fallar = false;
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(r.requests.length, 2);
    expect(r.requests.toSet().length, 1);
  });
  testWidgets('bloquea doble envío y cierre durante el guardado', (t) async {
    final r = AltaPrueba()..pendiente = Completer();
    await abrir(t, r);
    await completar(t);
    await t.tap(guardar);
    await t.pump();
    await t.tap(find.byType(ElevatedButton).last);
    await t.tap(find.byTooltip('Cerrar'));
    await t.pump();
    expect(r.llamadas, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    r.pendiente!.complete(r.resultado);
    await t.pumpAndSettle();
  });
  testWidgets('permite usar duplicado sin crear otro ni sobrescribirlo',
      (t) async {
    final r = AltaPrueba()..existente = true;
    SeleccionClienteDireccion? elegido;
    await abrir(t, r, elegir: (v) => elegido = v);
    await completar(t);
    await t.tap(guardar);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Cliente existente'), findsOneWidget);
    expect(elegido, isNull);
    await t.tap(find.text('Usar cliente existente'));
    await t.pumpAndSettle();
    expect(elegido?.cliente.id, 'nuevo');
    expect(r.llamadas, 1);
  });
  testWidgets(
      'cancelar vuelve al buscador conservando búsqueda y no crea datos',
      (t) async {
    final r = AltaPrueba();
    await abrir(t, r, busqueda: '3001234567');
    expect(t.widget<TextFormField>(campo('300 123 4567')).controller?.text,
        '3001234567');
    await t.tap(find.byTooltip('Cerrar'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(find.byType(TextField)).controller?.text,
        '3001234567');
    expect(r.llamadas, 0);
    expect(t.takeException(), isNull);
  });
}
