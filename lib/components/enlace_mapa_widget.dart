import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enlace de solo lectura a Google Maps para una solicitud.
///
/// Se degrada en dos escalones, para que nunca quede un hueco muerto:
///   1. Con coordenadas → abre el punto exacto.
///   2. Sin coordenadas pero con direccion → busca la direccion como texto.
///   3. Sin nada → no se pinta.
class EnlaceMapaWidget extends StatelessWidget {
  const EnlaceMapaWidget({
    super.key,
    this.latitud,
    this.longitud,
    this.direccion,
  });

  final double? latitud;
  final double? longitud;
  final String? direccion;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final hayPunto = latitud != null && longitud != null;
    final url = urlGoogleMaps(
      latitud: latitud,
      longitud: longitud,
      direccion: direccion,
    );
    if (url == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
      child: InkWell(
        onTap: () => launchURL(url),
        borderRadius: BorderRadius.circular(6.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Icon(
              hayPunto ? Icons.place_rounded : Icons.travel_explore_rounded,
              size: 16.0,
              color: tema.primary,
            ),
            Text(
              hayPunto
                  ? 'Abrir el punto en Google Maps'
                  : 'Buscar la dirección en Google Maps',
              style: tema.bodySmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: tema.primary,
                fontSize: 13.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            if (hayPunto) ...[
              Text(
                Coordenadas(latitud!, longitud!).formateadas,
                style: tema.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: Color(0xFF8A8A8A),
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
