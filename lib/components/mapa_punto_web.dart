import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/google_maps_web.dart';
import '/flutter_flow/ubicacion_helpers.dart';

// Implementacion real. No se importa directamente: se llega por
// mapa_punto_widget.dart, que elige entre esta y el sustituto segun
// plataforma. Importarla a mano rompe `flutter test`, que corre en la VM.

/// Mapa interactivo para fijar el punto de una solicitud.
///
/// Un clic en el mapa —o arrastrar el marcador— fija el punto. El widget no
/// guarda estado propio de la selección: avisa hacia arriba con `onPunto` y
/// vuelve a pintar con lo que le devuelvan. Así no hay dos versiones de la
/// verdad entre el mapa y el formulario.
class MapaPuntoWidget extends StatefulWidget {
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
  State<MapaPuntoWidget> createState() => _MapaPuntoWidgetState();
}

class _MapaPuntoWidgetState extends State<MapaPuntoWidget> {
  /// Vista general de Colombia mientras no hay ciudad resuelta ni punto.
  static const _centroPorDefecto = Coordenadas(4.5, -73.5);

  static int _contador = 0;

  late final String _idVista;
  late final web.HTMLElement _div;
  MapaGoogle? _mapa;
  void Function()? _liberarEventos;
  Coordenadas? _pintado;
  bool _fallo = false;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _idVista = 'hulp-mapa-${_contador++}';
    _div = crearContenedorMapa();
    registrarVistaMapa(_idVista, _div);
    _preparar();
  }

  Future<void> _preparar() async {
    final cargado = await cargarGoogleMaps(widget.claveApi);
    if (!mounted) return;
    if (!cargado) {
      setState(() => _fallo = true);
      return;
    }
    _intentarCrear(0);
  }

  /// El mapa necesita que su div ya esté en el documento y con tamaño; si no,
  /// se dibuja en gris. La vista de plataforma se engancha durante el layout,
  /// que puede ir un frame por detrás de la carga del script, así que se
  /// reintenta unos frames antes de rendirse.
  void _intentarCrear(int intento) {
    if (!mounted || _mapa != null) return;
    if (!_div.isConnected || _div.clientWidth == 0) {
      if (intento >= 20) {
        setState(() => _fallo = true);
        return;
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _intentarCrear(intento + 1));
      return;
    }

    final inicial = widget.punto ?? widget.centroCiudad ?? _centroPorDefecto;
    final mapa = crearMapa(
      elemento: _div,
      latitud: inicial.latitud,
      longitud: inicial.longitud,
      // Con punto se entra de cerca, porque ya se sabe dónde es; sin punto,
      // una vista de ciudad para poder buscar.
      zoom: widget.punto != null ? 17 : (widget.centroCiudad != null ? 12 : 5),
      mapId: widget.mapId,
      conMarcador: widget.punto != null,
      alElegirPunto: (lat, lng) {
        _pintado = Coordenadas(lat, lng);
        widget.onPunto(_pintado!);
      },
    );
    if (mapa == null) {
      setState(() => _fallo = true);
      return;
    }
    _mapa = mapa;
    _liberarEventos = aislarEventosMapa(_div);
    _pintado = widget.punto;
    setState(() => _listo = true);
  }

  @override
  void dispose() {
    _liberarEventos?.call();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapaPuntoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mapa = _mapa;
    if (mapa == null) return;

    final nuevo = widget.punto;
    // Comparar contra lo ya pintado, no contra el widget anterior: si el punto
    // vino del propio mapa, ya está en su sitio y volver a centrarlo daría un
    // salto de cámara en mitad del arrastre.
    if (nuevo == _pintado) {
      if (nuevo == null && widget.centroCiudad != oldWidget.centroCiudad) {
        _centrarCiudad(mapa);
      }
      return;
    }

    if (nuevo == null) {
      mapa.quitarMarcador();
      _centrarCiudad(mapa);
    } else {
      mapa.moverA(nuevo.latitud, nuevo.longitud, zoom: 17);
    }
    _pintado = nuevo;
  }

  void _centrarCiudad(MapaGoogle mapa) {
    final centro = widget.centroCiudad ?? _centroPorDefecto;
    mapa.centrarEn(centro.latitud, centro.longitud,
        zoom: widget.centroCiudad != null ? 12 : 5);
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    if (_fallo) {
      // Sin mapa se sigue pudiendo trabajar: queda el campo de pegar enlace.
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
          'No se pudo cargar el mapa. Puedes pegar el enlace o las '
          'coordenadas más abajo.',
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

    return SizedBox(
      height: widget.altura,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            Positioned.fill(child: HtmlElementView(viewType: _idVista)),
            if (!_listo)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF1F1F1),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(tema.primary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
