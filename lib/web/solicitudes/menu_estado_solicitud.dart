import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// El contexto debe pertenecer al botón de la fila, no a la pantalla o tabla.
Future<void> mostrarMenuEstadoSolicitud({
  required BuildContext anchorContext,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(anchorContext, rootNavigator: true);
  final boton = anchorContext.findRenderObject()! as RenderBox;
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final rtl = Directionality.of(anchorContext) == TextDirection.rtl;
  final posicion = boton.localToGlobal(
    Offset(rtl ? boton.size.width : 0, boton.size.height),
    ancestor: overlay,
  );
  final ruta = _RutaMenuEstado(
    context: anchorContext,
    builder: (context) => PointerInterceptor(child: builder(context)),
    position: posicion,
    followerAlignment: rtl ? Alignment.topRight : Alignment.topLeft,
    barrierColor: Colors.transparent,
    avoidOverflow: true,
    themes: InheritedTheme.capture(from: anchorContext, to: navigator.context),
  );

  // La tabla puede desplazar sus filas en ambos ejes y estar dentro del scroll
  // de la página. No observar el scroll del propio menú, solo el de sus anclas.
  final posiciones = <ScrollPosition>{};
  anchorContext.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      posiciones.add((element.state as ScrollableState).position);
    }
    return true;
  });
  var cerrando = false;
  void cerrarAlDesplazar() {
    if (cerrando || !ruta.isCurrent || !ruta.isActive) return;
    cerrando = true;
    // Un ajuste de scroll puede notificarse durante el layout de la tabla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && ruta.isCurrent) navigator.pop();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  for (final posicion in posiciones) {
    posicion.addListener(cerrarAlDesplazar);
  }
  try {
    await navigator.push<void>(ruta);
  } finally {
    for (final posicion in posiciones) {
      posicion.removeListener(cerrarAlDesplazar);
    }
  }
}

class _RutaMenuEstado extends AlignedDialogRoute<void> {
  _RutaMenuEstado(
      {required super.context,
      required super.builder,
      required super.position,
      required super.followerAlignment,
      required super.barrierColor,
      required super.avoidOverflow,
      required super.themes});

  @override
  Widget buildModalBarrier() =>
      PointerInterceptor(child: super.buildModalBarrier());
}
