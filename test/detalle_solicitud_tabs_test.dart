import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/detalle_solicitud_tabs.dart';
import 'package:hulp_admin/components/solicitud_historial_widget.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_theme.dart';

void main() {
  testWidgets('los filtros de Historial muestran su color en Material 2',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: const Scaffold(
        body: SolicitudHistorialWidget(solicitudId: null, visible: true),
      ),
    ));
    await tester.pumpAndSettle();

    Color? fondo(String etiqueta) {
      final tinta = tester.widget<Ink>(find.descendant(
        of: find.widgetWithText(ChoiceChip, etiqueta),
        matching: find.byType(Ink),
      ));
      return (tinta.decoration as ShapeDecoration).color;
    }

    expect(fondo('Todo'), hulpPrimaryGreen);
    expect(fondo('Operación'), Colors.white);
    expect(fondo('Cambios'), Colors.white);

    await tester.tap(find.text('Cambios'));
    await tester.pumpAndSettle();
    expect(fondo('Todo'), Colors.white);
    expect(fondo('Cambios'), hulpPrimaryGreen);
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'Detalles conserva campos, acciones y cierre al cambiar pestañas a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var guardados = 0;
      final controller = TextEditingController(text: 'Valor guardado');
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DetalleSolicitudTabs(
                      encabezado: const Text('Detalles de la solicitud'),
                      datos: Column(children: [
                        const Text('Notas del cliente'),
                        TextField(controller: controller),
                        const Text('Mostrar chat')
                      ]),
                      finanzas: Column(children: [
                        const Text('Precio lista'),
                        TextButton(
                            onPressed: () => guardados++,
                            child: const Text('Guardar desglose'))
                      ]),
                      acciones: const Text('Cerrar'))))));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar chat'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Edición conservada');
      await tester.tap(find.text('Desglose financiero'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar chat'), findsNothing);
      expect(find.text('Precio lista'), findsOneWidget);
      expect(find.text('Cerrar').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Guardar desglose'));
      expect(guardados, 1);
      await tester.ensureVisible(find.text('Historial'));
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Sin información de historial para mostrar.'),
          findsOneWidget);
      await tester.ensureVisible(find.text('Datos'));
      await tester.tap(find.text('Datos'));
      await tester.pumpAndSettle();
      expect(controller.text, 'Edición conservada');
      expect(find.text('Notas del cliente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
