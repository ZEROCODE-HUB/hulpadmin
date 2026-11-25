import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'hulp_modal_actions.dart';
import 'modal_con_encabezado_fijo.dart';

class AvisoProveedorAnteriorDialog extends StatelessWidget {
  const AvisoProveedorAnteriorDialog({
    super.key,
    required this.nombre,
    required this.telefono,
  });

  final String? nombre;
  final String? telefono;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final nombreContacto = nombre?.trim() ?? '';
    final telefonoContacto = telefono?.trim() ?? '';

    return Dialog(
      backgroundColor: theme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      constraints: const BoxConstraints(maxWidth: 520),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ModalConEncabezadoFijo(
          fijarPie: true,
          encabezado: EncabezadoModal(
            titulo: Text(
              'Avisar al proveedor anterior',
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                fontSize: 22,
                letterSpacing: 0,
              ),
            ),
          ),
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'La solicitud se reasignó. Comunica el cambio al proveedor anterior por WhatsApp.',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.alternate, width: .5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline, color: theme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            nombreContacto.isEmpty
                                ? 'Proveedor anterior'
                                : nombreContacto,
                            style: theme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            telefonoContacto.isEmpty
                                ? 'Sin teléfono registrado'
                                : telefonoContacto,
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              KeyedSubtree(
                key: modalFixedFooterKey,
                child: hulpModalActionRow(
                  actions: [
                    hulpModalPrimaryButton(
                      context: context,
                      text: 'Entendido',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
