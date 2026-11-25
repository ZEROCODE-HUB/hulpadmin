import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/editar_contacto_cliente_modal.dart';

void main() {
  Future<void> montar(WidgetTester tester,
      {double width = 850,
      Future<void> Function(String, String)? guardar}) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showDialog<ContactoClienteEditado>(
                        context: context,
                        builder: (_) => EditarContactoClienteModal(
                            usuarioId: 'u',
                            nombreCliente: 'Cliente de prueba',
                            telefono: '69452102',
                            correo: 'cliente@example.com',
                            guardar: guardar)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 850.0]) {
    testWidgets('modal de contacto adaptable a $width px', (tester) async {
      await montar(tester, width: width, guardar: (t, c) async {});
      expect(find.text('Editar contacto del cliente'), findsOneWidget);
      expect(find.text('Cliente de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 850) {
        expect(
            tester.getTopLeft(find.text('Teléfono *')).dy,
            closeTo(
                tester.getTopLeft(find.text('Correo electrónico *')).dy, 1));
      }
    });
  }
  testWidgets('valida, guarda una vez y cierra solo al terminar',
      (tester) async {
    var llamadas = 0;
    final completar = Completer<void>();
    await montar(tester, guardar: (t, c) async {
      llamadas++;
      expect(t, '3001234567');
      expect(c, 'nuevo@example.com');
      await completar.future;
    });
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.enterText(
        find.byType(TextFormField).last, 'correo incorrecto');
    await tester.tap(find.text('Guardar contacto'));
    await tester.pumpAndSettle();
    expect(llamadas, 0);
    expect(find.text('Ingresa el teléfono.'), findsOneWidget);
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '3001234567');
    await tester.enterText(
        find.byType(TextFormField).last, 'nuevo@example.com');
    await tester.tap(find.text('Guardar contacto'));
    await tester.pump();
    expect(llamadas, 1);
    expect(find.text('Guardando...'), findsOneWidget);
    completar.complete();
    await tester.pumpAndSettle();
    expect(find.text('Editar contacto del cliente'), findsNothing);
  });
  testWidgets('conserva datos al fallar y permite cancelar sin guardar',
      (tester) async {
    var llamadas = 0;
    await montar(tester, guardar: (t, c) async {
      llamadas++;
      throw StateError('sin red');
    });
    await tester.enterText(find.byType(TextFormField).first, '7777777');
    await tester.tap(find.text('Guardar contacto'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo guardar el contacto. Inténtalo de nuevo.'),
        findsOneWidget);
    expect(find.text('7777777'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(llamadas, 1);
    expect(find.text('Editar contacto del cliente'), findsNothing);
  });
}
