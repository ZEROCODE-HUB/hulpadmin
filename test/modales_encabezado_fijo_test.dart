import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hulp_admin/app_state.dart';
import 'package:hulp_admin/backend/supabase/supabase.dart';
import 'package:hulp_admin/components/modal_con_encabezado_fijo.dart';
import 'package:hulp_admin/components/aceptar_proveedor_widget.dart';
import 'package:hulp_admin/components/agregar_soporte_widget.dart';
import 'package:hulp_admin/components/crear_categoria_widget.dart';
import 'package:hulp_admin/components/crear_proveedor_widget.dart';
import 'package:hulp_admin/components/crear_servicio_widget.dart';
import 'package:hulp_admin/components/crear_subcategoria_widget.dart';
import 'package:hulp_admin/components/crear_usuario_widget.dart';
import 'package:hulp_admin/components/detalle_soporte_widget.dart';
import 'package:hulp_admin/components/detalle_solicitud_widget.dart';
import 'package:hulp_admin/components/edicion_solicitud_widget.dart';
import 'package:hulp_admin/components/editar_categoria_widget.dart';
import 'package:hulp_admin/components/editar_proveedor_widget.dart';
import 'package:hulp_admin/components/editar_servicio_widget.dart';
import 'package:hulp_admin/components/editar_subcategoria_widget.dart';
import 'package:hulp_admin/components/historial_servicios_widget.dart';
import 'package:hulp_admin/components/informacion_proveedor_widget.dart';
import 'package:hulp_admin/components/item_widget.dart';
import 'package:hulp_admin/components/notificacion2_widget.dart';
import 'package:hulp_admin/components/notificacioneliminar_widget.dart';
import 'package:hulp_admin/components/rechazar_proveedor_widget.dart';
import 'package:hulp_admin/components/ver_servicio_widget.dart';
import 'package:hulp_admin/components/finalizar_servicio2_widget.dart';
import 'package:hulp_admin/components/recibo_widget.dart';

class _Fuentes extends AssetManifest {
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
        .firstWhere((p) => p['name'] == 'flutter') as Map;
    fontBytes = ByteData.sublistView(await File.fromUri(
            Uri.parse('${flutter['rootUri']}/')
                .resolve('../flutter_tools/static/Ahem.ttf'))
        .readAsBytes());
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = _Fuentes();
    SharedPreferences.setMockInitialValues({});
    await FFAppState().initializePersistedState();
    await Supabase.initialize(
      url: 'https://modales.test',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET'); // Abrir/cerrar nunca escribe datos.
        final tabla = request.url.pathSegments.last;
        final rows = <String, List<Map<String, dynamic>>>{
          'usuarios': [
            {
              'id': 'usuario-1',
              'id_usuario': 1,
              'nombres': 'Nombre',
              'apellidos': 'Apellido'
            }
          ],
          'servicios': [
            {
              'id': 'servicio-1',
              'subcategoria_id': 'sub-1',
              'nombre': 'Servicio',
              'descripcion': 'Descripción',
              'precio': 10000.0,
              'estado': 'activo',
              'destacado': false,
              'fotos': List.filled(3, 'https://imagenes.test/modal.png'),
            }
          ],
          'soporte': [
            {
              'id': 'soporte-1',
              'nro': 1,
              'asunto': 'Consulta',
              'fecha_hora': null,
              'estado': null
            }
          ],
          'vw_solicitudes_servicios_completa': [
            {
              'solicitud_id': 'solicitud-1',
              'ticket': 1,
              'estado_solicitud': 'entrantes',
              'estado_pago': 'pendiente',
              'cliente_nombre_completo': 'Cliente',
              'servicio_nombre': 'Servicio',
              'categoria_nombre': 'Categoría',
              'precio_total': 10000.0,
              'fecha': '2026-10-27',
              'hora': '10:00:00'
            }
          ],
        };
        final datos = rows[tabla] ?? [];
        final single = request.url.queryParameters['limit'] == '1';
        return http.Response(
            jsonEncode(single && datos.isNotEmpty ? datos.first : datos), 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
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

  Future<void> esperar(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final categoria = VwResumenCategoriasRow({
    'id': 'cat-1',
    'nombre': 'Categoría',
    'imagen_url': 'https://imagenes.test/modal.png'
  });
  final subcategoria = VwResumenSubcategoriasRow({
    'id': 'sub-1',
    'nombre': 'Subcategoría',
    'imagen_url': 'https://imagenes.test/modal.png'
  });
  final casos = <String, Widget>{
    'aceptar proveedor':
        const AceptarProveedorWidget(idproveedor: 'proveedor-1'),
    'agregar soporte': const AgregarSoporteWidget(),
    'crear categoría': const CrearCategoriaWidget(),
    'crear proveedor': const CrearProveedorWidget(),
    'crear servicio':
        CrearServicioWidget(categoria: categoria, subcategoria: subcategoria),
    'crear subcategoría': CrearSubcategoriaWidget(categoriaid: categoria),
    'crear usuario': const CrearUsuarioWidget(),
    'detalle soporte': const DetalleSoporteWidget(idSoporte: 'soporte-1'),
    'detalle solicitud':
        const DetalleSolicitudWidget(solicitudId: 'solicitud-1'),
    'editar solicitud':
        const EdicionSolicitudWidget(solicitudId: 'solicitud-1'),
    'editar categoría': EditarCategoriaWidget(categoriarow: categoria),
    'editar proveedor': EditarProveedorWidget(
        idproveedor: VwProfesionalesCompletoRow({
      'profesional_id': 'proveedor-1',
      'nombres': 'Nombre',
      'apellidos': 'Apellido'
    })),
    'editar servicio': EditarServicioWidget(
        servicioId: 'servicio-1',
        categria: categoria,
        subcategria: subcategoria),
    'editar subcategoría': EditarSubcategoriaWidget(
        subcategoriaid: subcategoria, categoriaId: categoria),
    'ver subcategoría': EditarSubcategoriaWidget(
        subcategoriaid: subcategoria, categoriaId: categoria, ver: true),
    'historial de servicios':
        const HistorialServiciosWidget(userId: 'usuario-1'),
    'información proveedor':
        const InformacionProveedorWidget(proveedorId: 'usuario-1'),
    'agregar ítem': const ItemWidget(action: null),
    'notificación': const Notificacion2Widget(
        titulo: 'Resultado de la operación',
        texto: 'Mensaje',
        boton: 'Continuar',
        succes: false),
    'eliminar': const NotificacioneliminarWidget(
        titulo: 'Confirmar eliminación', texto: 'Mensaje', succes: false),
    'rechazar proveedor':
        const RechazarProveedorWidget(proveedorId: 'proveedor-1'),
    'ver servicio': const VerServicioWidget(servicioId: 'servicio-1'),
  };
  final cierresSimples = <String, Widget>{
    'finalizar servicio':
        const FinalizarServicio2Widget(servicioId: 'solicitud-1'),
    'recibo del chat': ReciboWidget(
        recibo: RecibosRow({
      'id': 'recibo-1',
      'estado': 'aceptado',
      'titulo': 'Recibo',
      'total': 10000.0
    })),
  };
  for (final caso in {...casos, ...cierresSimples}.entries) {
    testWidgets('${caso.key}: cierre fijo y accesible al desplazar',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final image = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.white, BlendMode.src);
        return recorder.endRecording().toImage(1, 1);
      });
      for (final url in [
        'https://imagenes.test/modal.png',
        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
        'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/g9fip9i3wzih/plomeria.png'
      ]) {
        PaintingBinding.instance.imageCache.putIfAbsent(
            NetworkImage(url),
            () => OneFrameImageStreamCompleter(
                Future.value(ImageInfo(image: image!.clone()))));
      }
      image!.dispose();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: FFAppState(),
        child: MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => Dialog(
                                  insetPadding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  child: caso.value)),
                          child: const Text('Abrir'),
                        )))),
      ));
      await tester.tap(find.text('Abrir'));
      await esperar(tester);
      final cierre = find.byTooltip('Cerrar').first;
      if (!cierresSimples.containsKey(caso.key)) {
        expect(find.byType(ModalConEncabezadoFijo), findsOneWidget);
      }
      expect(
          find.ancestor(
              of: cierre, matching: find.byType(SingleChildScrollView)),
          findsNothing);
      final rect = tester.getRect(cierre);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      if (!cierresSimples.containsKey(caso.key)) {
        final scroll = find
            .descendant(
                of: find.byType(ModalConEncabezadoFijo),
                matching: find.byType(SingleChildScrollView))
            .first;
        expect(tester.getRect(scroll).top, greaterThanOrEqualTo(rect.bottom));
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pump();
        expect(tester.getRect(cierre), rect);
      }
      await tester.tapAt(Offset(rect.right - 2, rect.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ModalConEncabezadoFijo), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  testWidgets(
      'título largo con texto ampliado mantiene el cierre en pantalla estrecha',
      (tester) async {
    tester.view.physicalSize = const Size(320, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: ModalConEncabezadoFijo(
        encabezado: const EncabezadoModal(
            titulo: Text('Aceptar inscripción de proveedores',
                textAlign: TextAlign.center)),
        cuerpo: Column(
            children: List.generate(
                30, (i) => SizedBox(height: 48, child: Text('Campo $i')))),
      ),
    ))));
    await tester.pump();
    final cierre = find.byTooltip('Cerrar');
    final rect = tester.getRect(cierre);
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.top, greaterThanOrEqualTo(0));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.getRect(cierre), rect);
    expect(tester.takeException(), isNull);
  });
}
