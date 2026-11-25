import 'package:flutter/material.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// La aceptación visual precede al cobro; la cotización no cambia ningún dato.
Future<Map<String, dynamic>?> confirmarImporteCobro(
  BuildContext context, {
  required String solicitudId,
  String? reciboId,
  int? fuente,
}) async {
  if (!SupaFlow.finanzasV1Habilitadas) return <String, dynamic>{};
  try {
    final response =
        await SupaFlow.client.functions.invoke('solicitudes-finanzas', body: {
      'accion': 'cotizar_cobro',
      'id': solicitudId,
      'recibo': reciboId,
      'fuente': fuente,
    });
    if (!context.mounted) return null;
    final data = response.data as Map;
    if (data['version'] == null) return <String, dynamic>{};
    if (data['pagado'] == true) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Pago registrado'),
                content: const Text('Este cobro ya fue pagado.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'))
                ],
              ));
      return null;
    }
    final aceptado = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Confirmar pago'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Total a cobrar: \$${(data['monto'] as num).toStringAsFixed(2)} COP'),
                        if ((data['recargo'] as num? ?? 0) > 0)
                          Text(
                              'Incluye recargo de Wompi (5 %): \$${(data['recargo'] as num).toStringAsFixed(2)} COP'),
                        const SizedBox(height: 12),
                        const Text(
                            'Los pagos anteriores ya están descontados del saldo.'),
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Confirmar'))
                  ],
                )) ??
        false;
    return aceptado ? Map<String, dynamic>.from(data) : null;
  } catch (_) {
    if (context.mounted) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('No se pudo consultar el importe'),
                content:
                    const Text('Intenta nuevamente antes de realizar el pago.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'))
                ],
              ));
    }
    return null;
  }
}
