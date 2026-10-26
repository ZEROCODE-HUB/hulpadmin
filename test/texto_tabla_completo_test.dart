import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/nombre_cliente_text.dart';
import 'package:hulp_admin/components/texto_tabla_completo.dart';
import 'package:hulp_admin/flutter_flow/flutter_flow_data_table.dart';

void comprobarTextoCompleto(WidgetTester tester, String texto) {
  final finder = find.text(texto);
  expect(tester.widget<Text>(finder).maxLines, isNull);
  expect(tester.widget<Text>(finder).overflow, TextOverflow.visible);
  final parrafo = tester.renderObject<RenderParagraph>(finder);
  final medida = TextPainter(
      text: parrafo.text,
      textDirection: parrafo.textDirection,
      textScaler: parrafo.textScaler)
    ..layout(maxWidth: parrafo.size.width);
  expect(parrafo.didExceedMaxLines, isFalse);
  expect(parrafo.size.height, greaterThanOrEqualTo(medida.height));
  medida.dispose();
}

void main() {
  testWidgets(
      'todas las celdas crecen, incluso al cambiar ancho o recibir datos',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const datos = [
      'Prueba Larga para comprobar campo test con todos sus apellidos y nombres adicionales',
      'correo.extremadamente.largo.para.el.listado.y.todos.sus.datos@ejemplo.com',
      'Nota extensa con todos los detalles de la solicitud y referencias. Incluye torre, apartamento y explicaciones.',
    ];
    final valor = ValueNotifier(datos.last);
    final controller = FlutterFlowDataTableController<String>();
    addTearDown(valor.dispose);
    addTearDown(controller.dispose);
    var clics = 0;
    Future<void> montar(double ancho) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
        width: ancho,
        height: 1000,
        child: FlutterFlowDataTable<String>(
          controller: controller,
          data: datos,
          columnSpacing: 20,
          dataRowHeight: 48,
          columnsBuilder: (_) => const [
            DataColumn2(label: Text('Valor')),
            DataColumn2(label: Text('Acciones'))
          ],
          dataRowBuilder: (texto, index, selected, onSelectChanged) =>
              DataRow(cells: [
            DataCell(index == 0
                ? NombreClienteText(
                    nombre: texto, style: const TextStyle(fontSize: 16))
                : index == 2
                    ? ValueListenableBuilder<String>(
                        valueListenable: valor,
                        builder: (_, texto, child) => TextoTablaCompleto(texto))
                    : TextoTablaCompleto(texto,
                        style: const TextStyle(fontSize: 16))),
            DataCell(TextButton(
                onPressed: () => clics++, child: const Text('Editar'))),
          ]),
        ),
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final texto in [datos.first, datos[1], valor.value]) {
        comprobarTextoCompleto(tester, texto);
      }
      final valores = [datos.first, datos[1], valor.value];
      for (var i = 0; i < valores.length - 1; i++) {
        expect(
          tester.getRect(find.text(valores[i])).bottom,
          lessThanOrEqualTo(tester.getRect(find.text(valores[i + 1])).top),
        );
      }
    }

    await montar(600);
    final altoInicial = tester.getSize(find.text(datos.first)).height;
    await montar(400);
    expect(tester.getSize(find.text(datos.first)).height,
        greaterThan(altoInicial));
    valor.value = List.filled(4, datos.last).join(' ');
    await tester.pumpAndSettle();
    comprobarTextoCompleto(tester, valor.value);
    await tester.tap(find.text('Editar').first);
    expect(clics, 1);
    expect(tester.takeException(), isNull);
  });
}
