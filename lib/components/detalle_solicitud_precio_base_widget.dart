import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/flutter_flow/flutter_flow_theme.dart';

class DetalleSolicitudPrecioBaseWidget extends StatelessWidget {
  const DetalleSolicitudPrecioBaseWidget({
    super.key,
    required this.precioBase,
  });

  final double? precioBase;

  static final _formatoEntero = NumberFormat('#,##0', 'es_CO');
  static final _formatoDecimal = NumberFormat('#,##0.00', 'es_CO');

  String _precioFormateado() {
    final precio = precioBase;
    if (precio == null || !precio.isFinite) return 'Precio base no disponible';

    final formato = precio % 1 == 0 ? _formatoEntero : _formatoDecimal;
    return '\$${formato.format(precio)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 560;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 8 : 20,
            vertical: compacto ? 20 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMensaje(theme, compacto),
                    SizedBox(height: compacto ? 16 : 22),
                    _buildPrecio(theme, compacto),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMensaje(FlutterFlowTheme theme, bool compacto) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 20 : 36,
          vertical: compacto ? 24 : 32,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border.all(color: const Color(0xFFE1E3E0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compacto ? 88 : 104,
              height: compacto ? 88 : 104,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: compacto ? 44 : 52,
                    color: theme.primary,
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.secondaryBackground,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.attach_money_rounded,
                        size: 22,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compacto ? 16 : 20),
            Text(
              'Sin desglose financiero',
              textAlign: TextAlign.center,
              style: theme.titleLarge.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Color(0xFF765A0A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta solicitud conserva el Precio lista del servicio.',
                      style: theme.bodyMedium.copyWith(
                        color: theme.primaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPrecio(FlutterFlowTheme theme, bool compacto) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 20 : 32,
          vertical: compacto ? 18 : 22,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F2),
          border: Border.all(color: theme.primary, width: 1.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final apilar = constraints.maxWidth < 480;
            final etiqueta = Text(
              'Precio base · Precio lista',
              style: theme.titleMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w700,
              ),
            );
            final precio = Text(
              _precioFormateado(),
              textAlign: apilar ? TextAlign.start : TextAlign.end,
              style: theme.headlineMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w700,
              ),
            );

            if (apilar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  etiqueta,
                  const SizedBox(height: 8),
                  precio,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: etiqueta),
                Container(
                  height: 44,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: const Color(0xFFD0E3D4),
                ),
                Flexible(child: precio),
              ],
            );
          },
        ),
      );
}
