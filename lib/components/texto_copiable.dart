import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';

Future<void> copiarTextoAlPortapapeles(
    BuildContext context, String texto) async {
  try {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    final tema = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Copiado al portapapeles',
        style: TextStyle(color: tema.secondaryBackground, fontSize: 14),
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: tema.success,
    ));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo copiar al portapapeles.')),
    );
  }
}

class TextoCopiable extends StatelessWidget {
  const TextoCopiable(
    this.texto, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
  });

  final String texto;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Copiar',
        child: InkWell(
          mouseCursor: SystemMouseCursors.copy,
          onTap: () => copiarTextoAlPortapapeles(context, texto),
          child: Text(
            texto,
            style: style,
            textAlign: textAlign,
            softWrap: softWrap,
          ),
        ),
      );
}
