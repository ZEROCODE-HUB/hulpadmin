import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hulp_admin/app_state.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_theme.dart';
import 'package:hulp_admin/web/menu/menu_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'ff_MenuAbierto': false});
    FFAppState.reset();
    await FFAppState().initializePersistedState();
  });

  testWidgets(
      'menú móvil se abre y cierra sin cambiar la preferencia de escritorio',
      (tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          appBar: MenuWidget.barraMovil(context),
          drawer: MenuWidget.menuMovil(context),
          body: const Row(
              children: [MenuWidget(), Expanded(child: Text('Contenido'))]),
        ),
      ),
      GoRoute(
        name: 'Solicitudes',
        path: '/solicitudes',
        builder: (context, state) => const Scaffold(body: Text('Destino')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Abrir menú'), findsOneWidget);
    expect(find.text('Solicitudes'), findsNothing);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(FFAppState().MenuAbierto, isFalse);
    await tester.tapAt(const Offset(370, 300));
    await tester.pumpAndSettle();
    expect(find.text('Solicitudes'), findsNothing);
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, 450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solicitudes'));
    await tester.pumpAndSettle();
    expect(find.text('Destino'), findsOneWidget);
    expect(FFAppState().MenuAbierto, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla grande conserva el menú lateral contraído',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    appBar: MenuWidget.barraMovil(context),
                    drawer: MenuWidget.menuMovil(context),
                    body: const Row(children: [
                      MenuWidget(),
                      Expanded(child: Text('Contenido'))
                    ]),
                  ))),
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Abrir menú'), findsNothing);
    expect(tester.getSize(find.byType(MenuWidget)).width, 112);
    expect(FFAppState().MenuAbierto, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el fondo del menú móvil cubre también el espacio libre',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    appBar: MenuWidget.barraMovil(context),
                    drawer: MenuWidget.menuMovil(context),
                    body: const MenuWidget(),
                  ))),
    ));
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    final context = tester.element(find.byType(Drawer));
    expect(drawer.backgroundColor, FlutterFlowTheme.of(context).primary);
    expect(tester.getSize(find.byType(Drawer)).height, 1200);
    expect(tester.takeException(), isNull);
  });
}
