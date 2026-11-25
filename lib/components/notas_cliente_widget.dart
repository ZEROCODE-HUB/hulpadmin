import 'package:flutter/material.dart';
import 'texto_copiable.dart';

class NotasClienteWidget extends StatelessWidget {
  const NotasClienteWidget({super.key, this.notas});
  final String? notas;

  @override
  Widget build(BuildContext context) {
    final notasGuardadas = notas?.trim();
    final texto = notasGuardadas == null || notasGuardadas.isEmpty
        ? 'Sin notas del cliente'
        : notasGuardadas;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Notas del cliente', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFBFAF9),
              border: Border.all(color: const Color(0xFFD5D0CA)),
              borderRadius: BorderRadius.circular(8)),
          child: SelectableText(
            texto,
            onTap: () => copiarTextoAlPortapapeles(context, texto),
          )),
    ]);
  }
}
