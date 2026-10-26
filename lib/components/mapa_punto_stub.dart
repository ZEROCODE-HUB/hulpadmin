import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/ubicacion_helpers.dart';

/// Sustituto del mapa fuera de la web.
///
/// Misma firma que la implementación real, para que el selector no tenga que
/// saber en qué plataforma está. Nunca llama a `onPunto`: sin mapa no hay
/// forma de elegir un punto aquí, y el campo de pegar coordenadas sigue
/// disponible en el selector.
class MapaPuntoWidget extends StatelessWidget {
  const MapaPuntoWidget({
    super.key,
    required this.claveApi,
    required this.onPunto,
    this.mapId,
    this.punto,
    this.centroCiudad,
    this.altura = 220.0,
  });

  final String claveApi;
  final String? mapId;
  final Coordenadas? punto;
  final Coordenadas? centroCiudad;
  final ValueChanged<Coordenadas> onPunto;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      height: 64.0,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF9),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: tema.alternate, width: 0.5),
      ),
      child: Text(
        'El mapa solo está disponible en el navegador.',
        textAlign: TextAlign.center,
        style: tema.bodySmall.override(
          font: GoogleFonts.inter(),
          color: const Color(0xFF8A8A8A),
          fontSize: 13.0,
          letterSpacing: 0.0,
        ),
      ),
    );
  }
}
