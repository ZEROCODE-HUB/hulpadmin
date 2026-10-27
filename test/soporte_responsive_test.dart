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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_data_table.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_drop_down.dart';
import 'package:hulp_admin/web/soporte/soporte_widget.dart';
import 'package:hulp_admin/web/soporte/soporte_responsive_layout.dart';
import 'package:hulp_admin/components/agregar_soporte_widget.dart';
import 'package:hulp_admin/components/detalle_soporte_widget.dart';

const _soporte = {
  'id': 'soporte-1',
  'nro': 1234,
  'estado': 'pendiente',
  'asunto': 'Mantenimiento con seguimiento',
  'fecha_hora': '2026-10-26T10:00:00-05:00',
  'nombre_usuario': 'Cliente con nombres y apellidos largos',
  'id_proveedor': 'Proveedor con identificador largo',
  'notas':
      'Notas extensas de la solicitud de soporte que deben verse completas.',
};

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
      url: 'https://soporte.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        expect(request.method,
            'GET'); // Rendering must never change payments or requests.
        var rows = <Map<String, dynamic>>[
          _soporte,
          {
            ..._soporte,
            'id': 'soporte-2',
            'nro': 1235,
            'estado': 'en proceso',
            'asunto': 'Consulta general',
          }
        ];
        for (final field in ['estado', 'asunto', 'nombre_usuario']) {
          final value = request.url.queryParameters[field];
          if (value != null) {
            final search = value
                .replaceFirst(RegExp(r'^i?like\.'), '')
                .replaceAll('%', '')
                .toLowerCase();
            rows = rows
                .where((row) =>
                    (row[field] as String).toLowerCase().contains(search))
                .toList();
          }
        }
        final Object data = request.url.path.endsWith('/soporte')
            ? (request.url.queryParameters['limit'] == '1' ? _soporte : rows)
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
    (1280.0, 800.0, 1.0, 0.0),
    (1600.0, 900.0, 1.0, 0.0),
    (390.0, 844.0, 1.5, 300.0),
  ]) {
    testWidgets('Soporte $width x $height, texto $scale, teclado $keyboard',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(tester, const SoporteWidget(), width, height,
          scale: scale, keyboard: keyboard);
      // The original page has four sequential data queries.
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final title = find.byType(SoporteResponsiveTitle);
      expect(title, findsOneWidget);
      expect(find.text('Agregar nuevo'), findsOneWidget);
      expect(find.byType(FlutterFlowDropDown<String>), findsNWidgets(2));
      final titleRect = tester.getRect(title);
      if (titleRect.width < 750) {
        final heading =
            find.descendant(of: title, matching: find.text('Soporte'));
        expect(tester.getCenter(heading).dx, closeTo(titleRect.center.dx, 1));
        final button = find
            .ancestor(
                of: find.text('Agregar nuevo'), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(button).width, closeTo(titleRect.width, 1));
        expect(tester.getRect(button).top,
            greaterThan(tester.getRect(heading).bottom));
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      final table = tester.widget<FlutterFlowDataTable<SoporteRow>>(
          find.byType(FlutterFlowDataTable<SoporteRow>));
      expect(table.minWidth, 1400);
      expect(table.data, hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  for (final (name, form) in <(String, Widget)>[
    ('nuevo', const AgregarSoporteWidget()),
    ('detalle', const DetalleSoporteWidget(idSoporte: 'soporte-1')),
  ]) {
    testWidgets('formulario de soporte $name a 320 px', (tester) async {
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
}
