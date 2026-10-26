import 'package:flutter/material.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';

/// Conserva el nombre completo accesible incluso en las celdas estrechas.
class NombreClienteText extends StatelessWidget {
  const NombreClienteText({
    super.key,
    required this.nombre,
    this.style,
  });

  final String? nombre;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final visible = nombreClienteVisible(nombre);
    return Tooltip(
      message: visible,
      child: Text(
        visible,
        style: style,
        softWrap: true,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
