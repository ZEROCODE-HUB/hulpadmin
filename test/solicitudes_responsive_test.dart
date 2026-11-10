import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hulp_admin/app_state.dart';
import 'package:hulp_admin/environment_values.dart';
import 'package:hulp_admin/components/selector_ubicacion_widget.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_widgets.dart';
import 'package:hulp_admin/components/crear_solicitud_widget.dart';
import 'package:hulp_admin/components/fecha_hora_solicitud_widget.dart';
import 'package:hulp_admin/components/detalle_solicitud_widget.dart';
import 'package:hulp_admin/components/detalle_solicitud_datos_widget.dart';
import 'package:hulp_admin/components/edicion_solicitud_widget.dart';
import 'package:hulp_admin/components/hulp_date_range_picker_widget.dart';
import 'package:hulp_admin/components/solicitud_status_badge_widget.dart';
import 'package:hulp_admin/components/dropdown_solicitud_estado_widget.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_data_table.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_filter_bar.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _solicitud = {
  'solicitud_id': 'solicitud-1',
  'ticket': 1234,
  'estado_solicitud': 'entrantes',
  'estado_pago': 'pendiente',
  'categoria_nombre': 'Plomería y mantenimiento especializado',
  'servicio_nombre': 'Servicio de mantenimiento',
  'cliente_nombre_completo': 'Cliente con nombres y apellidos largos',
  'solicitud_ciudad': 'Bogotá',
  'ubicacion': 'Calle 123, apartamento 456, torre 7',
  'precio_solicitud': 100000.0,
  'precio_total': 100000.0,
  'fecha': '2026-10-26',
  'hora': '10:00:00',
};

// Realtime stays disconnected; the HTTP fixture supplies the initial stream data.
class _CanalSinRed implements WebSocketChannel {
  @override
  final WebSocketSink sink = _SumideroSinRed();
  @override
  Future<void> get ready async {}
  @override
  String? get closeReason => null;
  @override
  int? get closeCode => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SumideroSinRed implements WebSocketSink {
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
  @override
  void add(dynamic data) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FuentesPrueba implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Inter', 'InterTight'])
          for (final weight in [
            'Thin',
            'ExtraLight',
            'Light',
            'Regular',
            'Medium',
            'SemiBold',
            'Bold',
            'ExtraBold',
            'Black'
          ])
            for (final italic in ['', 'Italic'])
              'test_fonts/$family-$weight$italic.ttf',
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var fallarSolicitudes = false;
  var usarFinanzas = false;
  var usarMapa = false;
  var solicitudVersionada = false;
  var datosFinanzasDetalle = false;
  double? precioBaseSolicitud = 100000;
  late ByteData fontBytes;
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter = (config['packages'] as List)
        .firstWhere((package) => package['name'] == 'flutter') as Map;
    final root = Uri.parse('${flutter['rootUri']}/');
    fontBytes = ByteData.sublistView(
        await File.fromUri(root.resolve('../flutter_tools/static/Ahem.ttf'))
            .readAsBytes());
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = _FuentesPrueba();
    SharedPreferences.setMockInitialValues({});
    await FFAppState().initializePersistedState();
    await Supabase.initialize(
      url: 'https://solicitudes.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/functions/v1/solicitudes-finanzas')) {
          expect(request.method.toUpperCase(), 'POST');
          final accion = jsonDecode(request.body)['accion'];
          if (accion == 'leer') {
            return http.Response(
                jsonEncode({
                  'solicitud': {
                    'finanzas_revision': 2,
                    'precio_base': datosFinanzasDetalle ? 10000 : 119900,
                    'precio': datosFinanzasDetalle ? 10000 : 109900,
                    'motivo_precio_pagado': '',
                    'adelanto_proveedor': datosFinanzasDetalle ? 2000 : 0,
                    'adelanto_motivo':
                        datosFinanzasDetalle ? 'Para su pasaje' : '',
                    'notas_cliente': 'Nota del cliente',
                    if (datosFinanzasDetalle) ...{
                      'materiales_total': 6000,
                      'pago_proveedor': 7200,
                      'saldo_transferir': 5200,
                      'comision_hulp_iva': 3332,
                      'comision_neta_hulp': 2800,
                      'iva_valor': 532,
                      'comision_efectiva': 28,
                      'ajuste_iva_valor': 532,
                      'wompi_valor': 826.6,
                      'total_cliente': 17358.6,
                      'aplica_wompi': true,
                      'aplica_ajuste_iva': true,
                      'requiere_fe': false,
                    },
                  },
                  'items': datosFinanzasDetalle
                      ? [
                          {
                            'descripcion': 'Cintas para grifos',
                            'tipo_item': 'material',
                            'cantidad': 2,
                            'precio_unitario': 1500,
                            'recibo_item_id': 'recibo-1',
                          },
                          {
                            'descripcion': 'Grifos para reemplazo',
                            'tipo_item': 'material',
                            'cantidad': 3,
                            'precio_unitario': 1000,
                          },
                        ]
                      : [],
                }),
                200,
                headers: {'content-type': 'application/json'});
          }
          expect(accion, 'preview');
          return http.Response(
              jsonEncode({
                'materiales_total': 0,
                'pago_proveedor': 86328,
                'saldo_transferir': 86328,
                'total_cliente': 119900,
              }),
              200,
              headers: {'content-type': 'application/json'});
        }
        expect(request.method,
            'GET'); // Rendering must never change payments or requests.
        if (fallarSolicitudes &&
            (request.url.path.endsWith('/solicitudes_servicio') ||
                request.url.path
                    .endsWith('/vw_solicitudes_servicios_completa'))) {
          return http.Response('{"message":"Servicio no disponible"}', 503,
              headers: {'content-type': 'application/json'});
        }
        final solicitud = {
          ..._solicitud,
          'precio_base': precioBaseSolicitud,
          if (solicitudVersionada) 'finanzas_version': 1,
        };
        final Object data =
            request.url.path.endsWith('/vw_solicitudes_servicios_completa')
                ? (request.url.queryParameters['limit'] == '1'
                    ? solicitud
                    : [solicitud])
                : [];
        return http.Response(jsonEncode(data), 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
    Supabase.instance.client.realtime.conn = _CanalSinRed();
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() {
    solicitudVersionada = false;
    datosFinanzasDetalle = false;
    precioBaseSolicitud = 100000;
    fallarSolicitudes = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name == 'assets/environment_values/environment_test.json') {
        final configuration = jsonEncode({
          'supabaseUrl': usarFinanzas
              ? 'https://ptafsiwlhxomgqmdmidf.supabase.co'
              : 'https://solicitudes.test',
          'supabaseAnonKey': 'test-key',
          'googleMapsApiKey': usarMapa ? 'clave-ficticia' : '',
        });
        return Future.value(ByteData.sublistView(
            Uint8List.fromList(utf8.encode(configuration))));
      }
      if (name.startsWith('test_fonts/')) return Future.value(fontBytes);
      return messenger.delegate.send('flutter/assets', message);
    });
  });

  Future<void> cargar(
      WidgetTester tester, Widget child, double width, double height,
      {double scale = 1, double keyboard = 0}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    FFAppState().MenuAbierto = true;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: child,
      ),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> abrirTabFinanzasDetalle(
    WidgetTester tester,
    double width,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await cargar(
      tester,
      const Scaffold(
        body: DetalleSolicitudWidget(solicitudId: 'solicitud-1'),
      ),
      width,
      950,
    );

    final tabFinanzas = find.widgetWithText(TextButton, 'Desglose financiero');
    await tester.ensureVisible(tabFinanzas);
    await tester.tap(tabFinanzas);
    await tester.pumpAndSettle();
  }

  for (final versionada in [false, true]) {
    testWidgets(
        'editar conserva datos al cambiar pestañas; versión 1: $versionada',
        (tester) async {
      solicitudVersionada = versionada;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(
          tester,
          const Scaffold(
              body: EdicionSolicitudWidget(solicitudId: 'solicitud-1')),
          1200,
          950);
      final datos = find.widgetWithText(TextButton, 'Datos');
      final finanzas = find.widgetWithText(TextButton, 'Desglose financiero');
      final historial = find.widgetWithText(TextButton, 'Historial');
      final descripcion = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText == 'Describe la solicitud...');
      await tester.ensureVisible(descripcion);
      await tester.enterText(descripcion, 'Descripción conservada');
      await tester.tap(finanzas);
      await tester.pumpAndSettle();
      expect(find.byType(FechaHoraSolicitudWidget), findsNothing);
      if (versionada) {
        final precio =
            find.byKey(const ValueKey('finanzas-entrada-Precio pagado'));
        expect(tester.widget<TextFormField>(precio).controller!.text, '109900',
            reason: tester
                .widgetList<Text>(find.byType(Text))
                .map((w) => w.data)
                .join(' | '));
        await tester.enterText(precio, '105000');
      } else {
        expect(find.text('Precios Adicionales'), findsOneWidget);
      }
      await tester.tap(historial);
      await tester.pumpAndSettle();
      expect(find.text('Sin información de historial para mostrar.'),
          findsOneWidget);
      await tester.tap(datos);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(descripcion).controller!.text,
          'Descripción conservada');
      expect(find.text('Información actual de contacto'), findsOneWidget);
      await tester.tap(finanzas);
      await tester.pumpAndSettle();
      if (versionada) {
        expect(
            tester
                .widget<TextFormField>(find
                    .byKey(const ValueKey('finanzas-entrada-Precio pagado')))
                .controller!
                .text,
            '105000');
        expect(
            find.byWidgetPredicate((w) =>
                w is SelectableText &&
                w.data == 'Notas del cliente: Nota del cliente'),
            findsOneWidget);
      }
      final guardar = find.widgetWithText(FFButtonWidget, 'Guardar cambios');
      expect(
          find.ancestor(
              of: guardar, matching: find.byType(SingleChildScrollView)),
          findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('selector separa estado plegable del scroll al reconstruirse',
      (tester) async {
    usarMapa = true;
    rootBundle.evict('assets/environment_values/environment_test.json');
    await tester.runAsync(() => FFDevEnvironmentValues().initialize());
    addTearDown(() async {
      usarMapa = false;
      rootBundle.evict('assets/environment_values/environment_test.json');
      await tester.runAsync(() => FFDevEnvironmentValues().initialize());
    });
    final bucket = PageStorageBucket();
    Future<void> montarSelector(int revision) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: PageStorage(
        bucket: bucket,
        child: SingleChildScrollView(
          key: const PageStorageKey('crear-solicitud-datos'),
          child: Builder(builder: (context) {
            // Valor que guarda el scroll, nunca un estado abierto/cerrado.
            bucket.writeState(context, 0.0);
            return SelectorUbicacionWidget(
              key: ValueKey('direccion_$revision'),
              onCambio: (_) {},
            );
          }),
        ),
      ))));
      await tester.pumpAndSettle();
    }

    await montarSelector(0);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('O pegar un enlace de Maps o unas coordenadas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pegar'), findsOneWidget);
    await montarSelector(1);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('O pegar un enlace de Maps o unas coordenadas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('crear conserva datos y finanzas al cambiar de pestaña',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    usarFinanzas = true;
    rootBundle.evict('assets/environment_values/environment_test.json');
    await tester.runAsync(() => FFDevEnvironmentValues().initialize());
    addTearDown(() async {
      usarFinanzas = false;
      rootBundle.evict('assets/environment_values/environment_test.json');
      await tester.runAsync(() => FFDevEnvironmentValues().initialize());
    });
    await cargar(
        tester, const Scaffold(body: CrearSolicitudWidget()), 1200, 950);
    final datos = find.widgetWithText(TextButton, 'Datos');
    final finanzas = find.widgetWithText(TextButton, 'Desglose financiero');
    final historial = find.widgetWithText(TextButton, 'Historial');
    expect(tester.widget<TextButton>(historial).onPressed, isNull);
    final descripcion = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'Describe la solicitud...');
    await tester.ensureVisible(descripcion);
    await tester.enterText(descripcion, 'Conservar esta descripción');
    await tester.tap(finanzas);
    await tester.pumpAndSettle();
    expect(find.byType(FechaHoraSolicitudWidget), findsNothing);
    final precio = find.byKey(const ValueKey('finanzas-entrada-Precio pagado'));
    await tester.enterText(precio, '109900');
    await tester.tap(datos);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(descripcion).controller!.text,
        'Conservar esta descripción');
    expect(find.byType(FechaHoraSolicitudWidget), findsOneWidget);
    await tester.tap(finanzas);
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(precio).controller!.text, '109900');
    final guardar = find.widgetWithText(FFButtonWidget, 'Crear solicitud');
    expect(
        find.ancestor(
            of: guardar, matching: find.byType(SingleChildScrollView)),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un fallo de carga muestra Reintentar y luego recupera la tabla',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    fallarSolicitudes = true;
    await cargar(tester, const SolicitudesWidget(), 1366, 900);
    expect(find.text('No se pudieron cargar las solicitudes.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    fallarSolicitudes = false;
    await tester.tap(find.text('Reintentar'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byType(SolicitudesDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final (width, height, scale, keyboard) in [
    (320.0, 640.0, 1.0, 0.0),
    (390.0, 844.0, 1.0, 0.0),
    (700.0, 390.0, 1.0, 0.0),
    (768.0, 600.0, 1.0, 0.0),
    (1024.0, 768.0, 1.0, 0.0),
    (1366.0, 900.0, 1.0, 0.0),
    (390.0, 844.0, 1.5, 300.0),
  ]) {
    testWidgets('Solicitudes $width x $height, texto $scale, teclado $keyboard',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(tester, const SolicitudesWidget(), width, height,
          scale: scale, keyboard: keyboard);
      expect(find.text('Filtrar:'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitudesDataTable), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets(
      'menú de estado se abre junto al botón de la fila y cierra al desplazar',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await cargar(tester, const SolicitudesWidget(), 1600, 900);
    final boton = find.byType(SolicitudStatusBadgeWidget).first;
    final rect = tester.getRect(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    final menu = find.byType(DropdownSolicitudEstadoWidget);
    expect(menu, findsOneWidget);
    final posicion = tester.getRect(menu);
    expect(posicion.left, closeTo(rect.left, 1));
    expect(posicion.top, closeTo(rect.bottom, 1));
    final horizontales = find.descendant(
        of: find.byType(SolicitudesDataTable),
        matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right));
    final scroll = tester.state<ScrollableState>(horizontales.first).position;
    expect(scroll.maxScrollExtent, greaterThan(0));
    scroll.jumpTo(60);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final (width, selected) in [
    (700.0, false),
    (900.0, false),
    (1100.0, false),
    (1280.0, false),
    (1600.0, false),
    (800.0, true),
    (1100.0, true),
  ]) {
    testWidgets('filtros alineados a $width px, seleccionados: $selected',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(
          tester,
          Scaffold(
              body: Padding(
            padding: const EdgeInsets.all(12),
            child: SolicitudesFilterBar(
              estadoOptions: const ['entrantes'],
              servicioOptions: const ['Servicio de mantenimiento'],
              ciudadOptions: const ['Bogotá D.C.'],
              dropDownValue1: selected ? 'entrantes' : null,
              dropDownValue2:
                  selected ? 'Servicio de mantenimiento' : null,
              dropDownValue3: selected ? 'Bogotá D.C.' : null,
              dateStart: selected ? DateTime(2026, 10, 1) : null,
              dateEnd: selected ? DateTime(2026, 10, 31) : null,
              resultCount: 31,
              onEstadoChanged: (_) {},
              onServicioChanged: (_) {},
              onCiudadChanged: (_) {},
              onDateRangeSelected: (_, __) {},
              onDateReset: () {},
            ),
          )),
          width,
          900);
      final controls = find.byType(DropdownButton<String>);
      expect(controls, findsNWidgets(3));
      final estado = tester.getRect(controls.at(0));
      final servicio = tester.getRect(controls.at(1));
      final ciudad = tester.getRect(controls.at(2));
      expect(estado.center.dy, closeTo(servicio.center.dy, 1));
      final counter = tester
          .getRect(find.textContaining('solicitudes', findRichText: true));
      if (width < 750) {
        expect(counter.bottom, lessThan(estado.top));
        expect(
            tester.getRect(find.text('Filtrar:')).bottom, lessThan(estado.top));
        expect(estado.width, greaterThan(250));
      } else {
        expect(estado.width, lessThanOrEqualTo(260));
        expect(servicio.width, lessThanOrEqualTo(260));
        expect(ciudad.center.dy, closeTo(estado.center.dy, 1));
        expect(tester.getCenter(find.byIcon(Icons.calendar_today_rounded)).dy,
            closeTo(estado.center.dy, 1));
        if (width >= 720) {
          expect(counter.center.dy, closeTo(estado.center.dy, 1));
          expect(tester.getRect(find.text('Filtrar:')).center.dy,
              closeTo(estado.center.dy, 1));
        }
        if (width >= 1600) {
          expect(counter.left, greaterThan(servicio.right));
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  for (final width in [320.0, 760.0, 1200.0]) {
    testWidgets(
        'detalle financiero agrupa importes y despliega materiales a $width px',
        (tester) async {
      solicitudVersionada = true;
      datosFinanzasDetalle = true;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(
        tester,
        const Scaffold(
          body: DetalleSolicitudWidget(solicitudId: 'solicitud-1'),
        ),
        width,
        950,
      );

      final tabFinanzas =
          find.widgetWithText(TextButton, 'Desglose financiero');
      await tester.ensureVisible(tabFinanzas);
      await tester.tap(tabFinanzas);
      await tester.pumpAndSettle();

      expect(find.text('Resumen financiero'), findsNothing);
      expect(
        find.text('Pagado + materiales + Wompi + ajuste'),
        findsOneWidget,
      );
      expect(find.text('Precio lista × 72 %'), findsOneWidget);
      expect(find.text('Pago − adelanto'), findsOneWidget);
      expect(find.text(r'$17.358,60'), findsOneWidget);
      expect(find.text(r'$7.200,00'), findsOneWidget);
      expect(find.text('Saldo a transferir'), findsAtLeastNWidgets(2));
      expect(find.text('28 %'), findsOneWidget);
      expect(find.text(r'$826,60'), findsOneWidget);
      expect(find.text('Valores del servicio'), findsOneWidget);
      expect(find.text('Pago al proveedor'), findsOneWidget);
      expect(find.text('Comisión e impuestos'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Cintas para grifos'), findsNothing);

      final materialsDisclosure =
          find.byTooltip('Ver materiales y adicionales');
      await tester.ensureVisible(materialsDisclosure);
      await tester.tap(materialsDisclosure);
      await tester.pumpAndSettle();
      expect(find.text('Cintas para grifos'), findsOneWidget);
      expect(find.text('Grifos para reemplazo'), findsOneWidget);
      expect(find.textContaining(r'Material · 2 × $1.500'), findsOneWidget);
      expect(find.textContaining(r'Material · 3 × $1.000'), findsOneWidget);
      expect(find.text('Desde chat'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      final hideMaterials = find.byTooltip('Ocultar materiales y adicionales');
      await tester.ensureVisible(hideMaterials);
      await tester.tap(hideMaterials);
      await tester.pumpAndSettle();
      expect(find.text('Cintas para grifos'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final width in [320.0, 760.0, 1200.0]) {
    testWidgets('detalle sin desglose muestra el precio base a $width px',
        (tester) async {
      solicitudVersionada = false;
      precioBaseSolicitud = 42500;
      await abrirTabFinanzasDetalle(tester, width);

      expect(find.text('Sin desglose financiero'), findsOneWidget);
      expect(
        find.text('Esta solicitud conserva el Precio lista del servicio.'),
        findsOneWidget,
      );
      expect(find.text('Precio base · Precio lista'), findsOneWidget);
      expect(find.text(r'$42.500'), findsOneWidget);
      expect(find.text('Precio base no disponible'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('detalle sin precio base no muestra cero a $width px',
        (tester) async {
      solicitudVersionada = false;
      precioBaseSolicitud = null;
      await abrirTabFinanzasDetalle(tester, width);

      expect(find.text('Precio base · Precio lista'), findsOneWidget);
      expect(find.text('Precio base no disponible'), findsOneWidget);
      expect(find.text(r'$0'), findsNothing);
      expect(find.text(r'$ 0'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final (name, form) in <(String, Widget)>[
    ('crear', const CrearSolicitudWidget()),
    ('editar', const EdicionSolicitudWidget(solicitudId: 'solicitud-1')),
    ('detalles', const DetalleSolicitudWidget(solicitudId: 'solicitud-1')),
  ]) {
    testWidgets('modal $name a 320 px', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(tester, Scaffold(body: form), 320, 640);
      if (name == 'detalles') {
        final datos = find.byType(DetalleSolicitudDatosWidget);
        expect(datos, findsOneWidget);
        expect(
          find.descendant(of: datos, matching: find.byType(TextFormField)),
          findsNothing,
        );
        expect(find.text('Editar solicitud'), findsOneWidget);
      } else {
        expect(find.byType(TextFormField), findsWidgets);
      }
      if (name == 'crear') {
        final calendario = find.byType(FechaHoraSolicitudWidget);
        final hoy = DateUtils.dateOnly(DateTime.now());
        expect(
          DateUtils.dateOnly(
              tester.widget<FechaHoraSolicitudWidget>(calendario).firstDate!),
          hoy,
        );
        final anterior = find.descendant(
            of: calendario,
            matching: find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Mes anterior'));
        expect(tester.widget<IconButton>(anterior).onPressed, isNull);
        if (hoy.day > 1) {
          final ayer = find.descendant(
              of: calendario, matching: find.text('${hoy.day - 1}'));
          final botonAyer =
              find.ancestor(of: ayer, matching: find.byType(InkWell));
          expect(tester.widget<InkWell>(botonAyer).onTap, isNull);
        }
        final diaHoy =
            find.descendant(of: calendario, matching: find.text('${hoy.day}'));
        final botonHoy =
            find.ancestor(of: diaHoy, matching: find.byType(InkWell));
        expect(tester.widget<InkWell>(botonHoy).onTap, isNotNull);
      }
      if (name == 'editar') {
        final icon = find.byIcon(Icons.keyboard_arrow_down).first;
        final scroll = Scrollable.of(tester.element(icon)).position;
        await tester.tap(icon);
        await tester.pumpAndSettle();
        final menu = find.byType(DropdownSolicitudEstadoWidget);
        expect(menu, findsOneWidget);
        final rect = tester.getRect(menu);
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.bottom, lessThanOrEqualTo(640));
        expect(scroll.maxScrollExtent, greaterThan(0));
        scroll.jumpTo(100);
        await tester.pumpAndSettle();
        expect(menu, findsNothing);
      } else if (name == 'detalles') {
        expect(find.byType(DropdownSolicitudEstadoWidget), findsNothing);
        expect(find.text('Pendiente'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'crear solicitud mantiene el cierre fuera del scroll a $width px',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(tester, Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: CrearSolicitudWidget(),
            ),
          ),
          child: const Text('Abrir crear solicitud'),
        );
      })), width, 480, scale: width < 600 ? 1 : 1.3);
      await tester.tap(find.text('Abrir crear solicitud'));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final cierre = find.byTooltip('Cerrar');
      expect(cierre, findsOneWidget);
      expect(tester.getSize(cierre).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(cierre).height, greaterThanOrEqualTo(48));
      expect(
          find.ancestor(
              of: cierre, matching: find.byType(SingleChildScrollView)),
          findsNothing);
      final posicion = tester.getRect(cierre);
      final cuerpo = find
          .descendant(
              of: find.byType(CrearSolicitudWidget),
              matching: find.byType(SingleChildScrollView))
          .first;
      expect(tester.getRect(cuerpo).top, greaterThanOrEqualTo(posicion.bottom));
      await tester.drag(cuerpo, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getRect(cierre), posicion);
      // También cierra pulsando el margen del botón, fuera del icono de 24 px.
      await tester.tapAt(Offset(posicion.right - 2, posicion.center.dy));
      await tester.pumpAndSettle();
      expect(find.byType(CrearSolicitudWidget), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets(
      'calendario móvil permite seleccionar, aplicar y limpiar un rango',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    DateTime? inicio;
    DateTime? fin;
    var limpio = false;
    await cargar(
        tester,
        Scaffold(
            body: Center(
                child: HulpDateRangePickerWidget(
          expandido: true,
          dateStart: DateTime(2026, 10, 1),
          dateEnd: DateTime(2026, 10, 2),
          onDateRangeSelected: (a, b) {
            inicio = a;
            fin = b;
          },
          onReset: () => limpio = true,
        ))),
        320,
        480,
        scale: 1.5);
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.ensureVisible(find.text('Aplicar'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(inicio, DateTime(2026, 10, 1));
    expect(fin, DateTime(2026, 10, 2, 23, 59, 59));
    await tester.tap(find.byTooltip('Limpiar fechas'));
    expect(limpio, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
