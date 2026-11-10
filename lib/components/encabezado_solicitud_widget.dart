import 'package:flutter/material.dart';
import '/flutter_flow/solicitud_status_helpers.dart';

class EncabezadoSolicitudWidget extends StatelessWidget {
  const EncabezadoSolicitudWidget({
    super.key,
    required this.titulo,
    required this.ticket,
    required this.estado,
    required this.onEstado,
    this.estadoInteractivo = true,
    this.pagoRecibido,
    this.onCerrar,
  });

  final String titulo;
  final int? ticket;
  final String? estado;
  final ValueChanged<BuildContext> onEstado;
  final bool estadoInteractivo;
  final bool? pagoRecibido;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) => estadoInteractivo
      ? _encabezadoEditable(context)
      : _encabezadoInformativo(context);

  Widget _encabezadoInformativo(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _badge(
                    'Ticket #${ticket ?? '—'}',
                    const Color(0xFFEEECE8),
                    const Color(0xFF202124),
                  ),
                  if (estado != null)
                    _badge(
                      solicitudStatusLabel(estado),
                      solicitudStatusBackgroundColor(estado),
                      solicitudStatusForegroundColor(estado),
                      icono:
                          estado == 'finalizadas' ? Icons.check_rounded : null,
                    ),
                  if (pagoRecibido != null)
                    _badge(
                      pagoRecibido! ? 'Pago recibido' : 'Pago pendiente',
                      pagoRecibido!
                          ? const Color(0xFFE2F4E6)
                          : const Color(0xFFFFF5D6),
                      pagoRecibido!
                          ? const Color(0xFF147B4D)
                          : const Color(0xFF946A00),
                      icono: pagoRecibido!
                          ? Icons.check_rounded
                          : Icons.schedule_rounded,
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar ?? () => Navigator.pop(context),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.close),
          ),
        ],
      );

  Widget _encabezadoEditable(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                spacing: 18,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '|',
                    style: TextStyle(color: Color(0xFFD5D0CA), fontSize: 24),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'Ticket: ',
                      children: [
                        TextSpan(
                          text: ticket == null ? '—' : '#$ticket',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Text('Estado: ', style: TextStyle(fontSize: 16)),
                      Builder(
                        builder: (anchor) => TextButton.icon(
                          onPressed: () => onEstado(anchor),
                          icon: Icon(
                            estado == 'finalizadas'
                                ? Icons.check
                                : Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                          label: Text(solicitudStatusLabel(estado)),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                solicitudStatusForegroundColor(estado),
                            backgroundColor:
                                solicitudStatusBackgroundColor(estado),
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar ?? () => Navigator.pop(context),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.close),
          ),
        ],
      );

  Widget _badge(String text, Color fondo, Color color, {IconData? icono}) =>
      Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      );
}
