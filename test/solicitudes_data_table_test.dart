import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_data_table.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_data_table.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('permite leer los textos completos y conserva copiar dirección',
      (tester) async {
    tester.view.physicalSize = const Size(2400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const nombre = 'María del Carmen De la Hoz Pérez con todos sus apellidos';
    const direccion = 'Calle 48C sur #43A-50, apto 712, Ciudadela Real / '
        'semáforo de la clínica de la policía y portería del conjunto';
    final item = VwSolicitudesServiciosCompletaRow({
      'ticket': 1488,
      'cliente_nombre_completo': nombre,
      'ubicacion': direccion,
      'solicitud_ciudad': 'Medellín',
      'categoria_nombre': 'Plomería y mantenimiento especializado',
      'estado_solicitud': 'finalizado',
      'estado_pago': 'recibido',
      'proveedor_id_usuario': 1000000022,
    });
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final controller =
        FlutterFlowDataTableController<VwSolicitudesServiciosCompletaRow>();
    addTearDown(controller.dispose);
    var ediciones = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SolicitudesDataTable(
          data: [item],
          controller: controller,
          onStatusTap: (_, index) {},
          onDelete: (_) {},
          onViewDetails: (_) {},
          onEdit: (_) => ediciones++,
          onMarkPaymentReceived: (_) {},
          updatingPaymentIds: const {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final textoDireccion = tester.widget<Text>(find.text(direccion));
    expect(textoDireccion.maxLines, isNull);
    expect(textoDireccion.overflow, TextOverflow.visible);
    final parrafo = tester.renderObject<RenderParagraph>(find.text(direccion));
    final medicion = TextPainter(
      text: parrafo.text,
      textDirection: parrafo.textDirection,
      textScaler: parrafo.textScaler,
    )..layout(maxWidth: parrafo.size.width);
    expect(parrafo.didExceedMaxLines, isFalse);
    expect(parrafo.size.height, greaterThanOrEqualTo(medicion.height));
    medicion.dispose();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    for (final texto in [nombre, direccion]) {
      await mouse.moveTo(tester.getCenter(find.text(texto).first));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      // Uno en la fila y el otro completo en la capa del tooltip.
      expect(find.text(texto), findsNWidgets(2));
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(direccion));
    await tester.pumpAndSettle();
    expect(copiado, direccion);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final horizontal = find.byWidgetPredicate((widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.right);
    expect(horizontal, findsWidgets);
    await tester.drag(horizontal.first, const Offset(-1800, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(ediciones, 1);
    expect(tester.takeException(), isNull);
  });
}
