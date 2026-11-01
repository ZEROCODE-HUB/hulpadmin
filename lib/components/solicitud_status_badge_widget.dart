import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/solicitud_status_helpers.dart';

class SolicitudStatusBadgeWidget extends StatelessWidget {
  const SolicitudStatusBadgeWidget({
    super.key,
    required this.estado,
    this.onTap,
    this.showArrow = false,
  });

  final String estado;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final bgColor = solicitudStatusBackgroundColor(estado);
    final fgColor = solicitudStatusForegroundColor(estado);
    final label = solicitudStatusLabel(estado);

    final badge = Container(
      constraints: const BoxConstraints(minHeight: 32.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: fgColor),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding:
            const EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 2.0),
        child: Text(
          label,
          maxLines: null,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                color: fgColor,
                fontSize: 16.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );

    if (!showArrow && onTap == null) return badge;

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F5F3),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).tertiary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showArrow)
              Icon(
                Icons.keyboard_arrow_down_sharp,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
            Expanded(child: badge),
          ],
        ),
      ),
    );
  }
}
