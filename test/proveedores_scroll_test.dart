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
import 'package:hulp_admin/components/solicitud_status_badge_widget.dart';
import 'package:hulp_admin/components/dropdown_solicitud_estado_widget.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_data_table.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_filter_bar.dart';
import 'package:hulp_admin/web/solicitudes/solicitudes_widget.dart';
import 'package:hulp_admin/web/proveedores2/proveedores2_widget.dart';
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

  testWidgets('barra horizontal visible permite llegar a Acciones',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await cargar(
        tester,
        const Proveedores2Widget(
            categoriaid: 'categoria-1', categorianombre: 'Plomería'),
        1000,
        700);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final barra = find.byWidgetPredicate((w) =>
        w is Scrollbar &&
        w.thumbVisibility == true &&
        w.trackVisibility == true);
    expect(barra, findsOneWidget);
    final controller = tester.widget<Scrollbar>(barra).controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
    final inicial = tester.getRect(find.text('Acciones')).left;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Acciones')).left, lessThan(inicial));
    expect(
        find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
