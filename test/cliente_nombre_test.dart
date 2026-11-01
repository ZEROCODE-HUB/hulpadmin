import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/nombre_cliente_text.dart';
import 'package:hulp_admin/flutter_flow/cliente_nombre_helpers.dart';

void main() {
  group('nombre del cliente', () {
    test('conserva todos los nombres, apellidos y caracteres del dato recibido',
        () {
      expect(
        nombreClienteVisible("  María del Carmen De la Hoz O'Neill-Pérez  "),
        "María del Carmen De la Hoz O'Neill-Pérez",
      );
    });

    test('los datos ausentes nunca se sustituyen por una identidad inventada',
        () {
      for (final nombre in <String?>[null, '', '   ']) {
        expect(nombreClienteVisible(nombre), 'Cliente sin nombre');
      }
      expect(nombreClienteDePerfil(null, null), 'Cliente sin nombre');
      expect(nombreClienteDePerfil('  ', ''), 'Cliente sin nombre');
    });

    test('el perfil conserva las partes disponibles sin interpolar nulos', () {
      expect(nombreClienteDePerfil(' Diana ', ' Martinez '), 'Diana Martinez');
      expect(nombreClienteDePerfil('Diana', null), 'Diana');
      expect(nombreClienteDePerfil(null, 'Martínez'), 'Martínez');
      expect(
        nombreClienteDePerfil('María del Carmen', 'De la Hoz Pérez'),
        nombreClienteVisible('María del Carmen De la Hoz Pérez'),
      );
    });
  });

  testWidgets(
      'un nombre largo queda completo y consultable en una celda estrecha',
      (tester) async {
    const nombre = 'María del Carmen De la Hoz O’Neill-Pérez';
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 60,
          child: NombreClienteText(nombre: nombre),
        ),
      ),
    ));

    expect(find.text(nombre), findsOneWidget);
    expect(find.byTooltip(nombre), findsOneWidget);
    await tester.longPress(find.byType(NombreClienteText));
    await tester.pumpAndSettle();
    expect(find.text(nombre), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('al recibir otro nombre no conserva la identidad anterior',
      (tester) async {
    Widget perfil(String? nombre) => MaterialApp(
          home: Scaffold(body: NombreClienteText(nombre: nombre)),
        );

    await tester.pumpWidget(perfil('Diana Martinez'));
    expect(find.text('Diana Martinez'), findsOneWidget);
    await tester.pumpWidget(perfil('Ana María Pérez Gómez'));
    expect(find.text('Diana Martinez'), findsNothing);
    expect(find.text('Ana María Pérez Gómez'), findsOneWidget);
    await tester.pumpWidget(perfil(null));
    expect(find.text('Ana María Pérez Gómez'), findsNothing);
    expect(find.text('Cliente sin nombre'), findsOneWidget);
  });
}
