import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hulp_admin/web/ciudades/ciudad_formulario_dialog.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('crear y editar sobreviven a cierres durante las animaciones',
      (tester) async {
    late BuildContext contexto;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, state) {
            contexto = context;
            return const Scaffold(body: Text('Ciudades'));
          })
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (var i = 0; i < 20; i++) {
      var completo = false;
      final resultado = mostrarFormularioCiudad(
        context: contexto,
        nombreInicial: i.isEven ? null : 'Medellín',
        validarNombre: (_) => null,
        onGuardar: (nombre, activo) async {},
      ).then((value) {
        completo = true;
        return value;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final campo = find.byType(TextField);
      await tester.enterText(campo, 'Ciudad $i');
      final contextoDialogo =
          tester.element(find.byType(CiudadFormularioDialog));
      if (i.isEven) {
        // Cancelar antes de que termine incluso la animación de entrada.
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed!();
      } else {
        Navigator.of(contextoDialogo).pop();
      }
      await tester.pump();
      expect(completo, isFalse); // El Future también espera la salida.
      // Fuerza cambios de foco/layout mientras el TextField sigue saliendo.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(await resultado, isFalse);
      expect(find.byType(CiudadFormularioDialog), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('valida y conserva el formulario tras un error de guardado',
      (tester) async {
    late BuildContext contexto;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      contexto = context;
      return const Scaffold();
    })));
    var intentos = 0;
    final resultado = mostrarFormularioCiudad(
      context: contexto,
      nombreInicial: 'Medellín',
      activoInicial: false,
      validarNombre: (nombre) => nombre.isEmpty ? 'Nombre requerido' : null,
      onGuardar: (nombre, activo) async {
        expect(nombre, 'Cali');
        expect(activo, isFalse);
        if (++intentos == 1) throw StateError('Sin conexión');
      },
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre requerido'), findsOneWidget);
    expect(intentos, 0);
    await tester.enterText(find.byType(TextField), ' Cali ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(await resultado, isTrue);
    expect(intentos, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('descarta un fallo tardío si la ruta se retiró al guardar',
      (tester) async {
    final pendiente = Completer<void>();
    late BuildContext contexto;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      contexto = context;
      return const Scaffold();
    })));
    final resultado = mostrarFormularioCiudad(
      context: contexto,
      nombreInicial: 'Cali',
      validarNombre: (_) => null,
      onGuardar: (nombre, activo) => pendiente.future,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed,
        isNull);
    // Simula que una navegación externa retira el modal.
    Navigator.of(tester.element(find.byType(CiudadFormularioDialog))).pop();
    await tester.pumpAndSettle();
    pendiente.completeError(StateError('Respuesta tardía'));
    await tester.pump();
    expect(await resultado, isFalse);
    expect(tester.takeException(), isNull);
  });
}
