import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/web/login_web/login_web_widget.dart';
import 'package:provider/provider.dart';

void main() {
  for (final viewport in [
    const Size(1440, 900),
    const Size(768, 900),
    const Size(390, 844),
    const Size(320, 568),
  ]) {
    testWidgets('login conserva campos y adapta el diseño a $viewport',
        (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Provider<LoginWebModel?>.value(
          value: null,
          child: const MaterialApp(home: LoginWebWidget()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);

      if (viewport.width >= 768) {
        expect(find.byKey(const ValueKey('login-services-illustration')),
            findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('login-services-illustration')),
            findsNothing);
      }

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('la visibilidad de la contraseña sigue funcionando',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Provider<LoginWebModel?>.value(
        value: null,
        child: const MaterialApp(home: LoginWebWidget()),
      ),
    );
    await tester.pumpAndSettle();

    final passwordFinder = find.byKey(const ValueKey('login-password'));
    await tester.ensureVisible(passwordFinder);
    final passwordInput = find.descendant(
      of: passwordFinder,
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(passwordInput).obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
