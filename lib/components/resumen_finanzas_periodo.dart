import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/backend/supabase/supabase.dart';

class ResumenFinanzasPeriodo extends StatefulWidget {
  const ResumenFinanzasPeriodo({super.key, this.inicio, this.fin});
  final DateTime? inicio;
  final DateTime? fin;
  @override
  State<ResumenFinanzasPeriodo> createState() => _ResumenFinanzasPeriodoState();
}

class _ResumenFinanzasPeriodoState extends State<ResumenFinanzasPeriodo> {
  late Future<Map<String, dynamic>> _datos;
  @override
  void initState() {
    super.initState();
    _datos = _cargar();
  }

  Future<Map<String, dynamic>> _cargar() async {
    final now = DateTime.now();
    final inicio = widget.inicio ?? DateTime(now.year, now.month, 1);
    final end = widget.fin ?? now;
    final fin = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final r =
        await SupaFlow.client.functions.invoke('solicitudes-finanzas', body: {
      'accion': 'metricas',
      'inicio': inicio.toUtc().toIso8601String(),
      'fin': fin.toUtc().toIso8601String(),
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(
                onPressed: () => setState(() => _datos = _cargar()),
                child: const Text('Reintentar resumen financiero'));
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final metrics = [
            (
              key: 'cobros_confirmados',
              label: 'Cobros confirmados',
              icon: Icons.savings_outlined,
            ),
            (
              key: 'comision_neta',
              label: 'Comisión neta Hulp',
              icon: Icons.sell_outlined,
            ),
            (
              key: 'iva',
              label: 'IVA',
              icon: Icons.calculate_outlined,
            ),
          ];
          final currency = NumberFormat.currency(
            locale: 'en_US',
            symbol: '\$',
            decimalDigits: 2,
          );

          Widget metric(int index) {
            final item = metrics[index];
            final amount = snapshot.data![item.key];
            final value = amount is num
                ? amount
                : num.tryParse(amount?.toString() ?? '') ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: const Color(0xFF0B6244), size: 25),
                const SizedBox(width: 14),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${item.label}:  '),
                      TextSpan(
                        text: currency.format(value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF171B1D),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      if (index > 0) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFD0D4CE)),
                        const SizedBox(height: 12),
                      ],
                      metric(index),
                    ],
                  ],
                );
              }
              return Row(children: [
                Expanded(child: metric(0)),
                const SizedBox(height: 24, child: VerticalDivider(width: 28)),
                Expanded(child: metric(1)),
                const SizedBox(height: 24, child: VerticalDivider(width: 28)),
                Expanded(child: metric(2)),
              ]);
            }),
          );
        },
      );
}
