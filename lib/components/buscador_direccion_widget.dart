import 'dart:async';

import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/places_service.dart';

/// Buscador de direcciones con sugerencias de Google Places.
///
/// Las sugerencias se pintan **debajo del campo**, dentro del propio árbol, en
/// vez de en un Overlay: esto vive dentro de diálogos que se desplazan, y un
/// overlay se queda flotando en la posición vieja al hacer scroll.
class BuscadorDireccionWidget extends StatefulWidget {
  const BuscadorDireccionWidget({
    super.key,
    required this.servicio,
    required this.onLugar,
    this.textoInicial = '',
  });

  final PlacesService servicio;

  /// Se dispara al elegir una sugerencia, ya resuelta a punto + dirección.
  final ValueChanged<LugarResuelto> onLugar;

  final String textoInicial;

  @override
  State<BuscadorDireccionWidget> createState() =>
      _BuscadorDireccionWidgetState();
}

class _BuscadorDireccionWidgetState extends State<BuscadorDireccionWidget> {
  late final TextEditingController _controlador;
  Timer? _espera;
  List<SugerenciaLugar> _sugerencias = const [];
  bool _buscando = false;
  bool _resolviendo = false;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: widget.textoInicial);
  }

  @override
  void dispose() {
    _espera?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    // Cada pulsación no puede ser una llamada: Google cobra por sesión, pero
    // la latencia y la cuota sí se notan. 350 ms es el punto donde deja de
    // sentirse lento sin disparar una petición por letra.
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    if (texto.trim().length < 3) {
      if (mounted) setState(() => _sugerencias = const []);
      return;
    }
    setState(() => _buscando = true);
    final resultado = await widget.servicio.sugerencias(texto);
    if (!mounted) return;
    setState(() {
      _sugerencias = resultado;
      _buscando = false;
    });
  }

  Future<void> _elegir(SugerenciaLugar s) async {
    setState(() {
      _resolviendo = true;
      _sugerencias = const [];
    });
    final lugar = await widget.servicio.detalle(s.placeId);
    if (!mounted) return;
    setState(() => _resolviendo = false);
    if (lugar == null) {
      // Sin punto no se avisa hacia arriba: mejor no cambiar nada que dejar
      // la dirección de un sitio y el punto de otro.
      _controlador.text = s.completo;
      return;
    }
    _controlador.text =
        lugar.direccion.isNotEmpty ? lugar.direccion : s.completo;
    widget.onLugar(lugar);
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controlador,
          onChanged: _alEscribir,
          decoration: decorarInputHulp(context, InputDecoration(
            isDense: true,
            hintText: 'Buscar una dirección…',
            hintStyle: tema.labelMedium.override(
              font: GoogleFonts.inter(),
              color: const Color(0xFF8A8A8A),
              fontSize: 14.0,
              letterSpacing: 0.0,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20.0),
            suffixIcon: (_buscando || _resolviendo)
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : (_controlador.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar la búsqueda',
                        icon: const Icon(Icons.close_rounded, size: 18.0),
                        onPressed: () {
                          _controlador.clear();
                          setState(() => _sugerencias = const []);
                        },
                      )
                    : null),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: tema.alternate, width: 0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: tema.alternate, width: 0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: const Color(0xFFFBFAF9),
          )),
          style: tema.bodyMedium.override(
            font: GoogleFonts.inter(),
            fontSize: 15.0,
            letterSpacing: 0.0,
          ),
          cursorColor: tema.primaryText,
        ),
        if (_sugerencias.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            constraints: const BoxConstraints(maxHeight: 190.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: tema.alternate, width: 0.5),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _sugerencias.length,
              separatorBuilder: (_, __) => Divider(
                height: 1.0,
                thickness: 0.5,
                color: tema.alternate,
              ),
              itemBuilder: (_, i) {
                final s = _sugerencias[i];
                return InkWell(
                  onTap: () => _elegir(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 9.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                          child: Icon(Icons.place_outlined,
                              size: 16.0, color: tema.accent3),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.principal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.bodyMedium.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (s.secundario.isNotEmpty)
                                Text(
                                  s.secundario,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tema.bodySmall.override(
                                    font: GoogleFonts.inter(),
                                    color: const Color(0xFF8A8A8A),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
