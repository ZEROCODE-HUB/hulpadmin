import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp_admin/app_state.dart';
import 'package:hulp_admin/web/dashboard/dashboard_widget.dart';
import 'package:hulp_admin/web/dashboard/dashboard_responsive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const cliente =
      'Cliente con nombres y apellidos largos para comprobar toda la información';
  const proveedor =
      'Profesional con nombres y apellidos extensos para la prueba';
  const asunto =
      'Solicitud de soporte con una descripción extensa que debe verse completa';
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await FFAppState().initializePersistedState();
    await Supabase.initialize(
      url: 'https://dashboard.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        Object data;
        switch (request.url.path.split('/').last) {
          case 'vw_dashboard_metricas':
            data = {
              'servicios_pendientes': 1234,
              'servicios_activos': 123,
              'solicitudes_hoy_entrantes': 1234,
              'solicitudes_hoy_activas': 1234,
              'solicitudes_hoy_finalizadas': 1234,
              'solicitudes_proximas_entrantes': 1234,
              'solicitudes_proximas_activas': 1234,
              'ingresos_totales_anuales': 123456789.0
            };
          case 'vw_solicitudes_servicios_completa':
            data = [
              {
                'solicitud_id': 'solicitud-1',
                'ticket': 12345,
                'estado_solicitud': 'entrantes',
                'servicio_nombre': 'Servicio con nombre largo',
                'cliente_nombre_completo': cliente
              }
            ];
          case 'vw_profesionales_completo':
            data = [
              {
                'profesional_id': 'profesional-1',
                'nombre_completo': proveedor,
                'categoria_nombre':
                    'Categoría extensa de servicios profesionales',
                'verificado': 'pendiente'
              }
            ];
          case 'soporte':
            data = [
              {
                'id': 'soporte-1',
                'nro': 12345,
                'estado': 'pendiente',
                'asunto': asunto,
                'nombre_usuario': cliente
              }
            ];
          default:
            data = [];
        }
        return http.Response(jsonEncode(data), 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final (width, textScale, menuOpen) in [
    (320.0, 1.0, true),
    (390.0, 1.0, true),
    (768.0, 1.0, true),
    (1024.0, 1.0, true),
    (1366.0, 1.0, true),
    (1920.0, 1.0, true),
    (390.0, 1.5, true),
    (1024.0, 1.5, false),
  ]) {
    testWidgets('panel completo a $width px y escala $textScale',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FFAppState().MenuAbierto = menuOpen;
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: FFAppState(),
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
            home: const DashboardWidget()),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Solicitudes pendientes'), findsOneWidget);
      expect(find.text(asunto), findsOneWidget);
      expect(
          find.byType(SingleChildScrollView).evaluate().where((element) =>
              (element.widget as SingleChildScrollView).scrollDirection ==
              Axis.horizontal),
          hasLength(3));
      expect(find.text('Ticket'), findsNWidgets(2));
      expect(find.text('Estado'), findsNWidgets(3));
      for (final table in find.byType(DashboardTablaScroll).evaluate()) {
        final scroll = tester.widget<SingleChildScrollView>(find.descendant(
          of: find.byWidget(table.widget),
          matching: find.byWidgetPredicate((widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal),
        ));
        final availableWidth =
            tester.getSize(find.byWidget(table.widget)).width;
        final minimumWidth = 700 * textScale;
        expect(
            scroll.controller!.position.maxScrollExtent,
            closeTo(
                (minimumWidth - availableWidth).clamp(0, double.infinity), 1));
        if (availableWidth < minimumWidth) {
          scroll.controller!
              .jumpTo(scroll.controller!.position.maxScrollExtent);
          await tester.pump();
          expect(scroll.controller!.offset, greaterThan(0));
        }
      }
      for (final element in find.byType(RenderObjectWidget).evaluate()) {
        final render = element.renderObject;
        if (render is RenderParagraph)
          expect(render.didExceedMaxLines, isFalse);
        if (render is RenderBox &&
            render.hasSize &&
            render.attached &&
            element.findAncestorWidgetOfExactType<DashboardTablaScroll>() ==
                null) {
          final rect = render.localToGlobal(Offset.zero) & render.size;
          expect(rect.right, lessThanOrEqualTo(width + 1),
              reason: '${element.widget.runtimeType}');
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
