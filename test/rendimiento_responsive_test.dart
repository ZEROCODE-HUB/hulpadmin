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

import 'package:hulp_admin/web/rendimiento/rendimiento_widget.dart';
import 'package:hulp_admin/web/rendimiento/rendimiento_responsive_layout.dart';
import 'package:fl_chart/fl_chart.dart';

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
      url: 'https://rendimiento.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        expect(request.method,
            'GET'); // Rendering must never change payments or requests.
        final now = DateTime.now().toIso8601String();
        final servicio = {
          'id': 'servicio-1',
          'nombre': 'Mantenimiento',
          'subcategorias': {
            'id': 'sub-1',
            'categorias': {
              'id': 'cat-1',
              'nombre': 'Categoría de mantenimiento especializada'
            }
          }
        };
        Object data;
        switch (request.url.path.split('/').last) {
          case 'vw_resenas_recientes':
            data = [
              for (var i = 0; i < 3; i++)
                {
                  'id': 'resena-$i',
                  'calificacion': 5,
                  'creado_en': now,
                  'nombre_usuario':
                      'Cliente con todos sus nombres y apellidos $i',
                  'comentario':
                      'Un comentario largo con la descripción completa del servicio y su atención.',
                }
            ];
          case 'usuarios':
            data = [
              {
                'id': 'usuario-1',
                'nombres': 'Prueba',
                'apellidos': 'Prueba',
                'rol': 'proveedor',
                'fecha_registro': now,
                'profesional_servicios': [
                  {'servicios': servicio}
                ]
              }
            ];
          case 'solicitudes_servicio':
            data = [
              for (final estado in [
                'entrantes',
                'finalizadas',
                'canceladas',
                'reagendadas'
              ])
                {
                  'id': estado,
                  'estado': estado,
                  'fecha': now,
                  'creado_en': now,
                  'estado_pago': 'pagado',
                  'precio': 100000.0,
                  'servicios': servicio,
                }
            ];
          case 'soporte':
            data = [
              {
                'id': 'soporte-1',
                'asunto': 'Una consulta de soporte con descripción extensa',
                'fecha_hora': now,
                'estado': 'pendiente'
              }
            ];
          default:
            data = [];
        }
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

  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (768.0, 1.0),
    (1024.0, 1.0),
    (1366.0, 1.0),
    (1920.0, 1.0),
    (390.0, 1.5)
  ]) {
    testWidgets('Rendimiento completo a $width px, texto $scale',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await cargar(tester, const RendimientoWidget(), width, 900, scale: scale);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(RendimientoChartViewport), findsNWidgets(18));
      expect(find.byType(LineChart), findsNWidgets(6));
      expect(find.byType(BarChart), findsNWidgets(6));
      expect(find.byType(PieChart), findsNWidgets(3));
      final grids = find.byType(RendimientoGrid).evaluate();
      for (final grid in grids) {
        final rect = tester.getRect(find.byWidget(grid.widget));
        expect(rect.right, lessThanOrEqualTo(width + 1));
      }
      // Titles and review text can wrap without ellipses or overflowing the page.
      expect(find.text('Cliente con todos sus nombres y apellidos 0'),
          findsOneWidget);
      expect(find.text('Solicitudes finalizadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
