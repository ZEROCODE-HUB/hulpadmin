import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Distribución visual de Detalles. Mantiene montados los campos y acciones.
class DetalleSolicitudTabs extends StatefulWidget {
  const DetalleSolicitudTabs(
      {super.key,
      required this.encabezado,
      required this.datos,
      required this.finanzas,
      required this.acciones});
  final Widget encabezado, datos, finanzas, acciones;
  @override
  State<DetalleSolicitudTabs> createState() => _DetalleSolicitudTabsState();
}

class _DetalleSolicitudTabsState extends State<DetalleSolicitudTabs> {
  int tab = 0;
  final datosScroll = ScrollController(), finanzasScroll = ScrollController();
  @override
  void dispose() {
    datosScroll.dispose();
    finanzasScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.encabezado,
          const SizedBox(height: 8),
          Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: theme.alternate, width: .5))),
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final (index, label) in [
                      (0, 'Datos'),
                      (1, 'Desglose financiero'),
                      (2, 'Historial')
                    ])
                      Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      width: 3,
                                      color: tab == index
                                          ? theme.primary
                                          : Colors.transparent))),
                          child: TextButton(
                              onPressed: () => setState(() => tab = index),
                              style: TextButton.styleFrom(
                                  foregroundColor: tab == index
                                      ? theme.primary
                                      : theme.secondaryText,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  shape: const RoundedRectangleBorder(),
                                  textStyle: theme.bodyMedium.copyWith(
                                      fontWeight: tab == index
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                              child: Text(label))),
                  ]))),
          const SizedBox(height: 20),
          Flexible(
              child: IndexedStack(index: tab, children: [
            SingleChildScrollView(controller: datosScroll, child: widget.datos),
            SingleChildScrollView(
                controller: finanzasScroll, child: widget.finanzas),
            const SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: Text(
                            'Sin información de historial para mostrar.',
                            textAlign: TextAlign.center)))),
          ])),
          Container(
              padding: const EdgeInsets.only(top: 16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: theme.alternate, width: .5))),
              child: widget.acciones),
        ]);
  }
}
