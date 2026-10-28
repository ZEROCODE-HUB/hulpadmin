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
import 'package:hulp_admin/components/crear_solicitud_widget.dart';
import 'package:hulp_admin/components/detalle_solicitud_widget.dart';
import 'package:hulp_admin/components/edicion_solicitud_widget.dart';
import 'package:hulp_admin/components/hulp_date_range_picker_widget.dart';
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
        expect(request.method,
            'GET'); // Rendering must never change payments or requests.
        final Object data =
            request.url.path.endsWith('/vw_solicitudes_servicios_completa')
                ? (request.url.queryParameters['limit'] == '1'
                    ? _solicitud
                    : [_solicitud])
                : [];
        return http.Response(jsonEncode(data), 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
    Supabase.instance.client.realtime.conn = _CanalSinRed();
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final name = utf8.decode(message!.buffer.asUint8List());
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
      expect(find.text('Filtrar por:'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitudesDataTable), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

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
              categoriaOptions: const ['Plomería'],
              dropDownValue1: selected ? 'entrantes' : null,
              dropDownValue2: selected ? 'Plomería' : null,
              dateStart: selected ? DateTime(2026, 10, 1) : null,
              dateEnd: selected ? DateTime(2026, 10, 31) : null,
              resultCount: 31,
              onEstadoChanged: (_) {},
              onCategoriaChanged: (_) {},
              onEstadoReset: () {},
              onCategoriaReset: () {},
              onDateRangeSelected: (_, __) {},
              onDateReset: () {},
            ),
          )),
          width,
          900);
      final controls = find.byType(DropdownButton<String>);
      expect(controls, findsNWidgets(2));
      final estado = tester.getRect(controls.at(0));
      final categoria = tester.getRect(controls.at(1));
      expect(estado.center.dy, closeTo(categoria.center.dy, 1));
      if (width < 750) {
        expect(tester.getCenter(find.text('Filtrar por:')).dx,
            closeTo(width / 2, 1));
        expect(estado.width, greaterThan(250));
      } else {
        expect(estado.width, lessThanOrEqualTo(200));
        expect(categoria.width, lessThanOrEqualTo(200));
        expect(tester.getCenter(find.byIcon(Icons.calendar_today_rounded)).dy,
            closeTo(estado.center.dy, 1));
        final counter = tester.getRect(
            find.textContaining('Numero de solicitudes:', findRichText: true));
        if (width >= 1600) {
          expect(counter.left, greaterThan(categoria.right));
          expect(tester.getCenter(find.text('Filtrar por:')).dy,
              closeTo(estado.center.dy, 1));
        } else if (width < 1200) {
          expect(counter.bottom, lessThan(estado.top));
          expect(tester.getRect(find.text('Filtrar por:')).bottom,
              lessThan(estado.top));
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
      expect(find.byType(TextFormField), findsWidgets);
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
