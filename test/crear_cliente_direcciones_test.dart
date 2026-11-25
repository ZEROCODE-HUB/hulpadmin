import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/backend/direcciones_cliente.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/crear_usuario_widget.dart';

class Repo extends DireccionesClienteRepository {
  @override
  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) async => [
        CiudadesRow({'id': 'cali', 'nombre': 'Cali', 'activo': true})
      ];
}

void main() {
  Future<void> llenar(WidgetTester t, String label, String value) async {
    final f = find.byKey(ValueKey(label));
    await t.ensureVisible(f);
    await t.enterText(f, value);
    await t.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester t, String hint, String value) async {
    final f = find.text(hint).first;
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
    await t.tap(find.text(value).last);
    await t.pumpAndSettle();
  }

  Future<void> datos(WidgetTester t) async {
    await llenar(t, 'Nombres *', 'Messi');
    await llenar(t, 'Apellidos *', 'Chavez');
    await elegir(t, 'Seleccionar...', 'Pasaporte');
    await llenar(t, 'Número de documento *', '12345');
    await elegir(t, 'Seleccionar...', '+57');
    await llenar(t, 'Número de teléfono *', '3001234567');
    await llenar(t, 'Correo electrónico *', 'm@example.com');
    await llenar(t, 'Confirmar correo electrónico *', 'm@example.com');
    await t.tap(find.text('Continuar a direcciones'));
    await t.pumpAndSettle();
  }

  Future<void> direccion(WidgetTester t, String calle) async {
    final f = find.widgetWithText(TextFormField, 'Calle y número');
    await t.ensureVisible(f);
    await t.enterText(f, calle);
    await elegir(t, 'Seleccionar ciudad...', 'Cali');
    await t.ensureVisible(find.text('Agregar a la lista'));
    await t.pumpAndSettle();
    await t.tap(find.text('Agregar a la lista'));
    await t.pumpAndSettle();
  }

  for (final width in [600.0, 1440.0]) {
    testWidgets(
        'prepara dos direcciones y registra; reintento sin duplicar identidad a $width',
        (t) async {
      t.view.physicalSize = Size(width, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var identidades = 0, perfiles = 0, intentos = 0;
      List<Map<String, dynamic>>? guardadas;
      Map<String, dynamic>? perfil;
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showDialog(
                          context: context,
                          builder: (_) => CrearUsuarioWidget(
                                repository: Repo(),
                                mapaBuilder: (_) => const SizedBox(
                                    height: 150, child: Text('Mapa')),
                                crearIdentidad: (correo, clave) async {
                                  identidades++;
                                  return 'cliente';
                                },
                                guardarPerfil: (p) async {
                                  perfiles++;
                                  perfil = p;
                                },
                                guardarDirecciones: (rows) async {
                                  intentos++;
                                  if (intentos == 1) {
                                    throw StateError('Sin red');
                                  }
                                  guardadas = rows;
                                },
                              )),
                      child: const Text('Abrir'))))));
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continuar a direcciones'));
      await t.pumpAndSettle();
      expect(find.text('Completa este campo.'), findsWidgets);
      expect(identidades, 0);
      await datos(t);
      await direccion(t, 'Calle 1');
      expect(identidades, 0);
      expect(perfiles, 0);
      expect(find.text('Direcciones (1)'), findsOneWidget);
      await t.tap(find.text('Agregar dirección'));
      await t.pumpAndSettle();
      await t.tap(find.text('Oficina'));
      await direccion(t, 'Calle 2');
      expect(find.text('Direcciones (2)'), findsOneWidget);
      await t.tap(find.text('Registrar cliente').last);
      await t.pumpAndSettle();
      expect(find.textContaining('alta quedó incompleta'), findsOneWidget);
      expect(identidades, 1);
      expect(perfiles, 1);
      await t.tap(find.text('Registrar cliente').last);
      await t.pumpAndSettle();
      expect(identidades, 1);
      expect(perfiles, 1);
      expect(intentos, 2);
      expect(guardadas!.length, 2);
      expect(guardadas!.map((d) => d['id']).toSet().length, 2);
      expect(
          guardadas!.every(
              (d) => d['usuario_id'] == 'cliente' && d['activo'] == true),
          isTrue);
      expect(perfil!['direccion'], 'Calle 1');
      expect(perfil!['ciudad'], 'Cali');
      expect(find.text('Registrar cliente'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
      'monta el mapa al abrir Direcciones y conserva el borrador al volver',
      (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CrearUsuarioWidget(
      repository: Repo(),
      mapaBuilder: (_) =>
          const SizedBox(height: 100, child: Text('Mapa visible')),
    ))));
    await t.pumpAndSettle();
    expect(find.text('Mapa visible', skipOffstage: false), findsNothing);
    await t.tap(find.text('Direcciones (0)'));
    await t.pumpAndSettle();
    expect(find.text('Mapa visible'), findsOneWidget);
    final calle = find.widgetWithText(TextFormField, 'Calle y número');
    await t.ensureVisible(calle);
    await t.enterText(calle, 'Calle del borrador');
    await t.tap(find.text('Datos del cliente'));
    await t.pumpAndSettle();
    expect(find.text('Mapa visible', skipOffstage: false), findsNothing);
    await t.tap(find.text('Direcciones (0)'));
    await t.pumpAndSettle();
    expect(find.text('Mapa visible'), findsOneWidget);
    expect(find.text('Calle del borrador'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('cancelar descarta borradores sin crear usuario', (t) async {
    var llamadas = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => CrearUsuarioWidget(
                            repository: Repo(),
                            mapaBuilder: (_) => const SizedBox(),
                            crearIdentidad: (_, __) async {
                              llamadas++;
                              return 'id';
                            })),
                    child: const Text('Abrir'))))));
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await datos(t);
    await direccion(t, 'Calle 3');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(llamadas, 0);
    expect(find.text('Registrar cliente'), findsNothing);
  });
}
