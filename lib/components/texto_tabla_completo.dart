import 'package:flutter/material.dart';

/// Conserva el valor íntegro accesible sin desbordar las filas de una tabla.
class TextoTablaCompleto extends StatelessWidget {
  const TextoTablaCompleto(
    this.texto, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String texto;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: texto,
      constraints: const BoxConstraints(maxWidth: 480.0),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 20),
      child: Text(
        texto,
        style: style,
        textAlign: textAlign,
        maxLines: null,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }
}
