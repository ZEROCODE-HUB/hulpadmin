import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/web/solicitudes/menu_estado_solicitud.dart';

void main() {
  for (final eje in [Axis.horizontal, Axis.vertical]) {
    testWidgets('cierra al desplazar un ancestro en $eje y permite reabrir',
        (tester) async {
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
        controller: vertical,
        child: SingleChildScrollView(
          controller: horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: 1400,
              height: 1200,
              child: Align(
                alignment: Alignment.topLeft,
                child: Builder(
                    builder: (anchor) => TextButton(
                          onPressed: () => mostrarMenuEstadoSolicitud(
                              anchorContext: anchor,
                              builder: (_) => const Material(
                                  child: SizedBox(
                                      width: 160,
                                      height: 200,
                                      child: Text('Opciones')))),
                          child: const Text('Estado'),
                        )),
              )),
        ),
      ))));
      await tester.tap(find.text('Estado'));
      await tester.pumpAndSettle();
      expect(find.text('Opciones'), findsOneWidget);
      (eje == Axis.horizontal ? horizontal : vertical).jumpTo(5);
      await tester.pumpAndSettle();
      expect(find.text('Opciones'), findsNothing);
      await tester.tap(find.text('Estado'));
      await tester.pumpAndSettle();
      expect(find.text('Opciones'), findsOneWidget);
      await tester.tapAt(const Offset(500, 300));
      await tester.pumpAndSettle();
      expect(find.text('Opciones'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'ajusta el menú en el borde inferior y conserva la acción elegida',
      (tester) async {
    var elegido = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
      alignment: Alignment.bottomRight,
      child: Builder(
          builder: (anchor) => TextButton(
                onPressed: () => mostrarMenuEstadoSolicitud(
                    anchorContext: anchor,
                    builder: (context) => Material(
                        child: SizedBox(
                            width: 160,
                            height: 200,
                            child: TextButton(
                              onPressed: () {
                                elegido = true;
                                Navigator.of(context).pop();
                              },
                              child: const Text('Opción'),
                            )))),
                child: const Text('Estado'),
              )),
    ))));
    await tester.tap(find.text('Estado'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find
        .ancestor(of: find.text('Opción'), matching: find.byType(SizedBox))
        .first);
    expect(rect.right, lessThanOrEqualTo(800));
    expect(rect.bottom, lessThanOrEqualTo(600));
    expect(rect.top, greaterThanOrEqualTo(0));
    await tester.tap(find.text('Opción'));
    await tester.pumpAndSettle();
    expect(elegido, isTrue);
    expect(find.text('Opción'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
