import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'solicitud_historial_widget.dart';

/// Distribución visual de Detalles. Mantiene montados los campos y acciones.
class DetalleSolicitudTabs extends StatefulWidget {
  const DetalleSolicitudTabs(
      {super.key,
      required this.encabezado,
      required this.datos,
      required this.finanzas,
      this.solicitudId,
      required this.acciones});
  final Widget encabezado, datos, finanzas, acciones;
  final String? solicitudId;
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
    final escritorio = MediaQuery.sizeOf(context).width >= 700;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.encabezado,
          const SizedBox(height: 2),
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
                                  tapTargetSize: escritorio
                                      ? MaterialTapTargetSize.shrinkWrap
                                      : MaterialTapTargetSize.padded,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  shape: const RoundedRectangleBorder(),
                                  textStyle: theme.bodyMedium.copyWith(
                                      fontWeight: tab == index
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                              child: Text(label))),
                  ]))),
          SizedBox(height: tab == 2 ? 14 : 20),
          Flexible(
              child: IndexedStack(index: tab, children: [
            SingleChildScrollView(controller: datosScroll, child: widget.datos),
            SingleChildScrollView(
                controller: finanzasScroll, child: widget.finanzas),
            SolicitudHistorialWidget(
                solicitudId: widget.solicitudId, visible: tab == 2),
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
