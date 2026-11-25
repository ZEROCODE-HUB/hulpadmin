import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hulp_admin/components/solicitud_finanzas_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ByteData fontBytes;
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List)
        .firstWhere((p) => p['name'] == 'flutter') as Map;
    fontBytes = ByteData.sublistView(await File.fromUri(
            Uri.parse('${flutter['rootUri']}/')
                .resolve('../flutter_tools/static/Ahem.ttf'))
        .readAsBytes());
    fonts.assetManifest = _FuentesPrueba();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name.startsWith('test_fonts/')) return Future.value(fontBytes);
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  testWidgets(
      'el precio acordado requiere motivo al cambiar; cálculos son solo lectura',
      (tester) async {
    final key = GlobalKey<SolicitudFinanzasFormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: SolicitudFinanzasForm(
          key: key,
          precioLista: 119900,
          previsualizar: (entradas, items) async => {
                'pago_proveedor': 86328,
                'saldo_transferir': 86328,
                'total_cliente': 119900
              }),
    ))));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.textContaining('86328'), findsNWidgets(2),
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '));
    final field = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.labelText == 'Precio pagado (acordado)');
    await tester.enterText(field, '109900');
    expect(key.currentState!.validar(), isFalse);
    expect(await key.currentState!.guardarCambios(), isFalse);
    await tester.pump();
    expect(find.text('Indica el motivo del cambio de precio.'), findsOneWidget);
    final motive = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.labelText == 'Motivo del cambio');
    await tester.enterText(motive, 'Descuento cliente recurrente');
    expect(key.currentState!.validar(), isTrue);
    expect(key.currentState!.entradas['precio'], 109900);
    expect(key.currentState!.entradas['precio_base'], 119900);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  for (final width in [1200.0, 760.0, 320.0]) {
    testWidgets('crear: desglose en rejilla conserva campos a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<SolicitudFinanzasFormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SolicitudFinanzasForm(
              key: key,
              precioLista: 119900,
              disposicionCrear: true,
              previsualizar: (entradas, items) async => {
                'materiales_total': 0,
                'pago_proveedor': 86328,
                'saldo_transferir': 86328,
                'total_cliente': 119900,
              },
            ),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Guardar desglose'), findsNothing);
      if (width == 1200) {
        final labels = [
          'Precio lista (mano de obra)',
          'Precio pagado',
          'Motivo del cambio',
          'Materiales'
        ];
        final rects =
            labels.map((label) => tester.getRect(find.text(label))).toList();
        for (var i = 1; i < rects.length; i++) {
          expect(rects[i].top, closeTo(rects.first.top, 1));
          expect(rects[i].left, greaterThan(rects[i - 1].right));
        }
        final second = [
          'Adelanto al proveedor',
          'Motivo del adelanto',
          'Paga por Wompi (+5 %)',
          'Ajuste IVA',
          'Requiere FE',
        ];
        final secondRects = second
            .map((label) => tester.getRect(find.text(label).first))
            .toList();
        for (var i = 0; i < secondRects.length; i++) {
          expect(secondRects[i].top, closeTo(secondRects.first.top, 1));
          if (i > 0) {
            expect(secondRects[i].left, greaterThan(secondRects[i - 1].right));
          }
        }
        final adelantoHeight = tester
            .getSize(find.byKey(
                const ValueKey('finanzas-entrada-Adelanto al proveedor')))
            .height;
        for (final opcion in second.skip(2)) {
          final control = find.byKey(ValueKey('finanzas-opcion-$opcion'));
          expect(tester.getSize(control).height, closeTo(adelantoHeight, 1));
          final decoration = find.byKey(
            ValueKey('finanzas-opcion-decorator-$opcion'),
          );
          expect(
            tester.getSize(decoration).height,
            closeTo(adelantoHeight, 1),
          );
        }

        final calculados = [
          'Pago proveedor',
          'Saldo a transferir',
          'Comisión Hulp + IVA',
          'Comisión neta Hulp',
          'Comisión efectiva',
          'IVA',
          'Wompi',
          'Ajuste IVA',
          'Total cliente',
        ];
        final calculatedRects = calculados
            .map((label) => tester.getRect(find.text(label).last))
            .toList();
        expect(calculatedRects[0].top, closeTo(calculatedRects[1].top, 1));
        expect(calculatedRects[1].top, closeTo(calculatedRects[2].top, 1));
        expect(calculatedRects[3].top, closeTo(calculatedRects[4].top, 1));
        expect(calculatedRects[4].top, closeTo(calculatedRects[5].top, 1));
        expect(calculatedRects[6].top, closeTo(calculatedRects[7].top, 1));
        expect(calculatedRects[7].top, closeTo(calculatedRects[8].top, 1));
        expect(calculatedRects[8].left, greaterThan(calculatedRects[7].right));

        final pago = find.byKey(const ValueKey('finanzas-resultado-pago_proveedor'));
        final formula = find.text('Precio lista × 72 %');
        expect(
          tester.getTopLeft(formula).dy - tester.getBottomRight(pago).dy,
          lessThan(8),
        );

        for (final field in [
          'pago_proveedor',
          'saldo_transferir',
          'total_cliente',
        ]) {
          final decorator = tester.widget<InputDecorator>(
            find.byKey(ValueKey('finanzas-resultado-$field')),
          );
          final border = decorator.decoration.border! as OutlineInputBorder;
          expect(border.borderSide.width, greaterThan(1));
        }
      }
      final paid = find.byKey(const ValueKey('finanzas-entrada-Precio pagado'));
      await tester.ensureVisible(paid);
      await tester.enterText(paid, '109900');
      expect(key.currentState!.validar(), isFalse);
      final motive =
          find.byKey(const ValueKey('finanzas-entrada-Motivo del cambio'));
      await tester.ensureVisible(motive);
      await tester.enterText(motive, 'Descuento cliente recurrente');
      expect(key.currentState!.validar(), isTrue);
      expect(key.currentState!.entradas['precio'], 109900);
      final materials = find.byTooltip('Ver materiales y adicionales');
      await tester.ensureVisible(materials);
      await tester.tap(materials);
      await tester.pumpAndSettle();
      expect(find.text('Agregar ítem'), findsOneWidget);
      expect(find.text('Aún no hay materiales agregados'), findsOneWidget);
      expect(find.text('Agrega un ítem si aplica.'), findsOneWidget);
      expect(find.text('Motivo del adelanto'), findsOneWidget);
      expect(find.text('Concepto del adelanto'), findsNothing);
      expect(
          key.currentState!.entradas.containsKey('adelanto_concepto'), isFalse);
      expect(find.text('Requiere FE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final referencia in [false, true]) {
    testWidgets('adelanto requiere solo importe y motivo ($referencia)',
        (tester) async {
      final key = GlobalKey<SolicitudFinanzasFormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SolicitudFinanzasForm(
              key: key,
              precioLista: 10000,
              disposicionCrear: referencia,
              previsualizar: (entradas, items) async => {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      Finder campo(String label) => referencia
          ? find.byKey(ValueKey('finanzas-entrada-$label'))
          : find.byWidgetPredicate(
              (w) => w is TextField && w.decoration?.labelText == label);
      final adelanto = campo('Adelanto al proveedor');
      await tester.ensureVisible(adelanto);
      await tester.enterText(adelanto, '2000');
      expect(key.currentState!.validar(), isFalse);
      await tester.pump();
      expect(find.text('Indica el motivo del adelanto.'), findsOneWidget);
      final motivo = campo('Motivo del adelanto');
      await tester.ensureVisible(motivo);
      await tester.enterText(motivo, 'Para su pasaje');
      expect(key.currentState!.validar(), isTrue);
      expect(key.currentState!.entradas['adelanto_proveedor'], 2000);
      expect(key.currentState!.entradas['adelanto_motivo'], 'Para su pasaje');
      expect(
          key.currentState!.entradas.containsKey('adelanto_concepto'), isFalse);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [600.0, 320.0]) {
    testWidgets('Agregar Cobro conserva validación, datos y cierre a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final key = GlobalKey<SolicitudFinanzasFormState>();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: SingleChildScrollView(
            child: SolicitudFinanzasForm(
          key: key,
          precioLista: 119900,
          disposicionCrear: true,
          previsualizar: (entradas, items) async => {'materiales_total': 0},
        )),
      )));
      await tester.pumpAndSettle();
      final detalle = find.byTooltip('Ver materiales y adicionales');
      await tester.ensureVisible(detalle);
      await tester.tap(detalle);
      await tester.pumpAndSettle();
      final agregarItem = find.text('Agregar ítem');
      await tester.ensureVisible(agregarItem);
      await tester.tap(agregarItem);
      await tester.pumpAndSettle();
      expect(find.text('Agregar Cobro'), findsOneWidget);
      final dialogo = find.byType(Dialog);
      expect(
          find.descendant(
              of: dialogo,
              matching: find.byType(DropdownButtonFormField<String>)),
          findsNothing);
      final cantidad = find.byKey(const ValueKey('solicitud-item-Cantidad'));
      final precio =
          find.byKey(const ValueKey('solicitud-item-Precio por Unidad'));
      if (width == 600) {
        expect(tester.getRect(find.text('Cantidad').first).top,
            closeTo(tester.getRect(find.text('Precio por Unidad')).top, 1));
      }
      await tester.ensureVisible(find.text('Agregar'));
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe una descripción'), findsOneWidget);
      expect(key.currentState!.itemsGuardado, isEmpty);
      await tester.ensureVisible(
          find.byKey(const ValueKey('solicitud-item-Descripción')));
      await tester.enterText(
          find.byKey(const ValueKey('solicitud-item-Descripción')), 'Tubos');
      await tester.ensureVisible(cantidad);
      await tester.enterText(cantidad, '2');
      await tester.ensureVisible(precio);
      await tester.enterText(precio, '5000');
      await tester.pumpAndSettle();
      expect(find.text('10000.00'), findsOneWidget);
      await tester.ensureVisible(find.text('Mano de Obra'));
      await tester.tap(find.text('Mano de Obra'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Agregar'));
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      expect(dialogo, findsNothing);
      expect(key.currentState!.itemsGuardado, [
        {
          'tipo_item': 'mano_obra',
          'descripcion': 'Tubos',
          'cantidad': 2.0,
          'precio_unitario': 5000.0,
        }
      ]);
      expect(find.text('Tubos'), findsOneWidget);
      expect(find.text('Mano de obra'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.textContaining(r'$10.000'), findsOneWidget);
      expect(find.byTooltip('Editar ítem'), findsOneWidget);
      expect(find.byTooltip('Eliminar ítem'), findsOneWidget);
      // La edición mantiene los valores y actualiza el mismo renglón.
      final editar = find.byIcon(Icons.edit_outlined).last;
      await tester.ensureVisible(editar);
      await tester.tap(editar);
      await tester.pumpAndSettle();
      expect(find.text('Editar Cobro'), findsOneWidget);
      expect(
          tester
              .widget<ChoiceChip>(
                  find.widgetWithText(ChoiceChip, 'Mano de Obra'))
              .selected,
          isTrue);
      expect(tester.widget<TextFormField>(cantidad).controller!.text, '2.0');
      await tester.ensureVisible(cantidad);
      await tester.enterText(cantidad, '3');
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(key.currentState!.itemsGuardado.single['cantidad'], 3.0);
      // El teclado y el scroll no cubren la X, y cancelar no agrega otro ítem.
      await tester.ensureVisible(agregarItem);
      await tester.tap(agregarItem);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      final cierre = find.byTooltip('Cerrar');
      expect(
          find.ancestor(
              of: cierre, matching: find.byType(SingleChildScrollView)),
          findsNothing);
      expect(tester.getRect(cierre).bottom, lessThanOrEqualTo(600));
      await tester.tap(cierre);
      await tester.pumpAndSettle();
      expect(key.currentState!.itemsGuardado.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _FuentesPrueba implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Inter', 'InterTight'])
          for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            'test_fonts/$family-$weight.ttf',
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
