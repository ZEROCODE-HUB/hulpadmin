import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/hulp_input_decoration.dart';

void main() {
  testWidgets('completa icono y placeholder semánticos', (tester) async {
    late InputDecoration decoracion;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            decoracion = decorarInputHulp(
              context,
              const InputDecoration(labelText: 'Correo'),
            );
            return TextField(decoration: decoracion);
          },
        ),
      ),
    );

    expect(decoracion.prefixIcon, isA<Icon>());
    expect((decoracion.prefixIcon! as Icon).icon, Icons.mail_outline_rounded);
    expect(decoracion.hintText, 'nombre@ejemplo.com');
  });

  testWidgets('conserva el icono existente y no agrega icono en solo lectura',
      (tester) async {
    const iconoBusqueda = Icon(Icons.search_rounded);
    late InputDecoration conIconoExistente;
    late InputDecoration soloLectura;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            conIconoExistente = decorarInputHulp(
              context,
              const InputDecoration(
                hintText: 'Buscar usuario',
                prefixIcon: iconoBusqueda,
              ),
            );
            soloLectura = decorarInputHulp(
              context,
              const InputDecoration(labelText: 'Nombre'),
              soloLectura: true,
            );
            return Column(
              children: [
                TextField(decoration: conIconoExistente),
                TextField(decoration: soloLectura),
              ],
            );
          },
        ),
      ),
    );

    expect(conIconoExistente.prefixIcon, same(iconoBusqueda));
    expect(conIconoExistente.hintText, 'Buscar usuario');
    expect(soloLectura.prefixIcon, isNull);
    expect(soloLectura.hintText, 'Ingresa el nombre');
  });
}
