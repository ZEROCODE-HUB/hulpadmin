import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/encabezado_solicitud_widget.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('ticket y estado visibles en encabezado a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var aperturas = 0, cierres = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EncabezadoSolicitudWidget(
                      titulo: 'Editar solicitud',
                      ticket: 1060,
                      estado: 'finalizadas',
                      onEstado: (_) => aperturas++,
                      onCerrar: () => cierres++)))));
      expect(find.textContaining('#1060', findRichText: true), findsOneWidget);
      expect(find.text('Finalizado'), findsOneWidget);
      await tester.tap(find.text('Finalizado'));
      expect(aperturas, 1);
      await tester.tap(find.byTooltip('Cerrar'));
      expect(cierres, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
