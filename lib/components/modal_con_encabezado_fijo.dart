import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Mantiene el cierre fuera de la barra y del área desplazable del formulario.
class ModalConEncabezadoFijo extends StatelessWidget {
  const ModalConEncabezadoFijo({
    super.key,
    required this.encabezado,
    required this.cuerpo,
  });

  final Widget encabezado;
  final Widget cuerpo;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          encabezado,
          Flexible(child: SingleChildScrollView(child: cuerpo)),
        ],
      );
}

class EncabezadoModal extends StatelessWidget {
  const EncabezadoModal(
      {super.key, this.titulo, this.onCerrar, this.habilitado = true});

  final Widget? titulo;
  final VoidCallback? onCerrar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const SizedBox(width: 48.0),
          Expanded(child: Center(child: titulo ?? const SizedBox.shrink())),
          IconButton(
            tooltip: 'Cerrar',
            constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            padding: const EdgeInsets.all(12.0),
            onPressed: habilitado
                ? (onCerrar ?? () => Navigator.of(context).pop())
                : null,
            icon: Icon(Icons.close,
                size: 24.0, color: FlutterFlowTheme.of(context).primaryText),
          ),
        ],
      );
}
