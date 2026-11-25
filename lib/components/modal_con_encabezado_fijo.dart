import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

const Key modalFixedFooterKey = ValueKey<String>('modal_fixed_footer');

/// Mantiene el cierre fuera de la barra y del área desplazable del formulario.
class ModalConEncabezadoFijo extends StatelessWidget {
  const ModalConEncabezadoFijo({
    super.key,
    required this.encabezado,
    required this.cuerpo,
    this.fijarPie = false,
  });

  final Widget encabezado;
  final Widget cuerpo;
  final bool fijarPie;

  @override
  Widget build(BuildContext context) {
    final secciones = fijarPie ? _separarPie(cuerpo) : _SeccionesModal(cuerpo);
    assert(!fijarPie || secciones.pie != null,
        'fijarPie requiere marcar la última acción con modalFixedFooterKey.');
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        encabezado,
        Flexible(child: SingleChildScrollView(child: secciones.cuerpo)),
        if (secciones.pie != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: theme.alternate, width: .5)),
            ),
            child: secciones.pie,
          ),
      ],
    );
  }
}

class _SeccionesModal {
  const _SeccionesModal(this.cuerpo, {this.pie});

  final Widget cuerpo;
  final Widget? pie;
}

_SeccionesModal _separarPie(Widget widget) {
  if (widget is Padding && widget.child != null) {
    final secciones = _separarPie(widget.child!);
    return _SeccionesModal(
      Padding(padding: widget.padding, child: secciones.cuerpo),
      pie: secciones.pie,
    );
  }
  if (widget is Column && widget.children.isNotEmpty) {
    final ultimo = widget.children.last;
    if (ultimo.key == modalFixedFooterKey) {
      return _SeccionesModal(
        Column(
          key: widget.key,
          mainAxisAlignment: widget.mainAxisAlignment,
          mainAxisSize: widget.mainAxisSize,
          crossAxisAlignment: widget.crossAxisAlignment,
          textDirection: widget.textDirection,
          verticalDirection: widget.verticalDirection,
          textBaseline: widget.textBaseline,
          children: widget.children.take(widget.children.length - 1).toList(),
        ),
        pie: ultimo,
      );
    }
  }
  return _SeccionesModal(widget);
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
