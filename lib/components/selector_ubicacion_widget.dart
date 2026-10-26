import '/components/buscador_direccion_widget.dart';
import '/components/mapa_punto_widget.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/centro_ciudad_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/places_service.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Captura del punto exacto de una solicitud.
///
/// Se monta DEBAJO del campo de dirección, no lo reemplaza: la dirección
/// escrita sigue siendo lo que el proveedor lee, y el punto es para navegar.
///
/// Tiene dos modos y **el de abajo nunca desaparece**:
///
///   - Con clave de Google Maps: buscador de direcciones y mapa donde hacer
///     clic o arrastrar el marcador.
///   - Siempre: pegar el enlace de Maps o el par de coordenadas. Con mapa
///     queda plegado, pero sigue ahí — es lo que salva el día cuando la clave
///     caduca, se agota la cuota o el revisor está sin conexión.
class SelectorUbicacionWidget extends StatefulWidget {
  const SelectorUbicacionWidget({
    super.key,
    required this.onCambio,
    this.coordenadasIniciales,
    this.direccionActual,
    this.onDireccionSugerida,
    this.ciudadId,
    this.nombreCiudad,
    this.etiqueta = 'Ubicación exacta (opcional)',
  });

  /// Se dispara con el punto validado, o con null cuando se borra o no se
  /// puede leer. Quien lo use debe tratar el null como "sin coordenadas",
  /// nunca como "no cambió nada".
  final ValueChanged<Coordenadas?> onCambio;

  /// Punto ya guardado, para el formulario de edición.
  final Coordenadas? coordenadasIniciales;

  /// Dirección escrita, para el enlace de respaldo y para sembrar el buscador.
  final String Function()? direccionActual;

  /// Permite devolver al formulario la dirección que Google reconoce, para que
  /// el campo de texto no se quede desfasado respecto al punto. Opcional: si
  /// no se pasa, el punto se captura igual y la dirección la escribe el admin.
  final ValueChanged<String>? onDireccionSugerida;

  /// Contexto del servicio. Solo encuadra la cámara; nunca selecciona un punto.
  final String? ciudadId;
  final String? nombreCiudad;

  final String etiqueta;

  @override
  State<SelectorUbicacionWidget> createState() =>
      _SelectorUbicacionWidgetState();
}

class _SelectorUbicacionWidgetState extends State<SelectorUbicacionWidget> {
  late final TextEditingController _controlador;
  late final PlacesService? _places;
  late final CentroCiudadController _centroCiudad;
  final _contextosCiudad = <String, ({String nombre, String? departamento})>{};
  Coordenadas? _punto;
  String? _error;
  bool _avisoFueraDeColombia = false;
  bool _pegarAbierto = false;

  String get _clave => FFDevEnvironmentValues().googleMapsApiKey;
  bool get _conMapa => FFDevEnvironmentValues().tieneGoogleMaps;

  @override
  void initState() {
    super.initState();
    _punto = widget.coordenadasIniciales;
    _avisoFueraDeColombia = _punto?.pareceFueraDeColombia ?? false;
    _places = _conMapa ? PlacesService(_clave) : null;
    // Si ya hay punto guardado se muestra en el campo, para que se vea que
    // está puesto y se pueda corregir sin tener que borrarlo a ciegas.
    _controlador = TextEditingController(text: _punto?.formateadas ?? '');
    _centroCiudad = CentroCiudadController(_resolverCentroCiudad)
      ..addListener(_actualizarEncuadre);
    if (_conMapa) {
      _centroCiudad.actualizar(widget.ciudadId, widget.nombreCiudad);
    }

    // Se le avisa al padre del punto de partida. Sin esto, en el formulario de
    // edición abrir y guardar sin tocar la ubicación la borraría: el padre
    // arrancaría en null y escribiría null. Va en post-frame porque el padre
    // suele estar todavía construyéndose.
    if (_punto != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCambio(_punto);
      });
    }
  }

  @override
  void dispose() {
    _centroCiudad.dispose();
    _controlador.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SelectorUbicacionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_conMapa &&
        (oldWidget.ciudadId != widget.ciudadId ||
            oldWidget.nombreCiudad != widget.nombreCiudad)) {
      _centroCiudad.actualizar(widget.ciudadId, widget.nombreCiudad);
    }
  }

  void _actualizarEncuadre() {
    if (mounted) setState(() {});
  }

  Future<Coordenadas?> _resolverCentroCiudad(String? id, String? nombre) async {
    final clave = '${id ?? ''}|${nombre ?? ''}';
    var contexto = _contextosCiudad[clave];
    if (contexto == null) {
      final ciudades = await CiudadesTable().queryRows(
        queryFn: (q) => (id?.isNotEmpty ?? false)
            ? q.eq('id', id!).limit(1)
            : q.eq('nombre', nombre!.trim()).limit(2),
      );
      if (ciudades.length > 1) return null;
      final ciudad = ciudades.firstOrNull;
      final nombreEfectivo = ciudad?.nombre ?? nombre?.trim() ?? '';
      if (nombreEfectivo.isEmpty) return null;
      String? departamento;
      final provinciaId = ciudad?.provinciaId;
      if (provinciaId != null && provinciaId.isNotEmpty) {
        final provincias = await ProvinciasTable().querySingleRow(
          queryFn: (q) => q.eq('id', provinciaId),
        );
        departamento = provincias.firstOrNull?.nombre;
      }
      contexto = (nombre: nombreEfectivo, departamento: departamento);
      _contextosCiudad[clave] = contexto;
    }
    return _places?.resolverCentroCiudad(contexto.nombre,
        departamento: contexto.departamento);
  }

  void _fijar(Coordenadas? punto,
      {String? error, bool sincronizarTexto = true}) {
    setState(() {
      _punto = punto;
      _error = error;
      _avisoFueraDeColombia = punto?.pareceFueraDeColombia ?? false;
      if (sincronizarTexto) {
        _controlador.text = punto?.formateadas ?? '';
      }
    });
    widget.onCambio(punto);
  }

  void _analizar(String valor) {
    final resultado = analizarUbicacion(valor);
    // El texto no se toca: lo está escribiendo el usuario ahora mismo.
    _fijar(resultado.coordenadas,
        error: resultado.error, sincronizarTexto: false);
  }

  Future<void> _pegarDelPortapapeles() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = datos?.text?.trim() ?? '';
    if (texto.isEmpty) return;
    _controlador.text = texto;
    _analizar(texto);
  }

  void _limpiar() => _fijar(null);

  /// Punto elegido en el mapa: se guarda y se pregunta a Google cómo se llama
  /// ese sitio, para que la dirección escrita no quede contradiciendo al punto.
  Future<void> _puntoDelMapa(Coordenadas punto) async {
    _fijar(punto);
    final avisar = widget.onDireccionSugerida;
    if (avisar == null || _places == null) return;
    final direccion = await _places.direccionDe(punto.latitud, punto.longitud);
    if (!mounted || direccion == null || direccion.isEmpty) return;
    avisar(direccion);
  }

  void _lugarDelBuscador(LugarResuelto lugar) {
    _fijar(lugar.coordenadas);
    if (lugar.direccion.isNotEmpty) {
      widget.onDireccionSugerida?.call(lugar.direccion);
    }
  }

  Future<void> _abrirEnMaps() async {
    final url = urlGoogleMaps(
      latitud: _punto?.latitud,
      longitud: _punto?.longitud,
      direccion: widget.direccionActual?.call(),
    );
    if (url == null) return;
    await launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final direccion = widget.direccionActual?.call().trim() ?? '';
    final puedeAbrirPorDireccion = _punto == null && direccion.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta,
          style: tema.bodyMedium.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.normal),
            fontSize: 16.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8.0),

        if (_conMapa) ...[
          BuscadorDireccionWidget(
            servicio: _places!,
            textoInicial: direccion,
            onLugar: _lugarDelBuscador,
          ),
          const SizedBox(height: 8.0),
          MapaPuntoWidget(
            claveApi: _clave,
            mapId: FFDevEnvironmentValues().googleMapsMapId,
            punto: _punto,
            centroCiudad: _centroCiudad.centro,
            onPunto: _puntoDelMapa,
          ),
          const SizedBox(height: 6.0),
        ] else
          _campoPegar(tema),

        if (_error != null)
          _Aviso(
            icono: Icons.error_outline_rounded,
            color: tema.error,
            texto: _error!,
          ),
        if (_centroCiudad.fallo && _punto == null)
          const _Aviso(
            icono: Icons.info_outline,
            color: Color(0xFF8A8A8A),
            texto: 'No se pudo centrar el mapa en la ciudad. Puedes buscar '
                'la dirección o elegir el punto manualmente.',
          ),
        if (_punto != null) ...[
          _Aviso(
            icono: Icons.check_circle_outline_rounded,
            color: tema.primary,
            texto: 'Punto guardado: ${_punto!.formateadas}',
            acciones: [
              _AccionAviso('Ver en Maps', _abrirEnMaps),
              // Con mapa el campo de pegar queda plegado, asi que sin esto no
              // habria forma visible de dejar la solicitud sin punto.
              _AccionAviso('Quitar', () async => _limpiar()),
            ],
          ),
          if (_avisoFueraDeColombia)
            _Aviso(
              icono: Icons.warning_amber_rounded,
              color: const Color(0xFFB26A00),
              texto: 'Ese punto cae fuera de Colombia. Verifica que la '
                  'latitud y la longitud no estén invertidas.',
            ),
        ],
        if (_punto == null && _error == null)
          _Aviso(
            icono: Icons.info_outline_rounded,
            color: const Color(0xFF8A8A8A),
            texto: _conMapa
                ? 'Busca la dirección arriba o haz clic en el mapa para fijar '
                    'el punto.'
                : (puedeAbrirPorDireccion
                    ? 'Sin punto exacto. El proveedor verá la dirección '
                        'escrita y la buscará en Maps como texto.'
                    : 'Sin punto exacto. Opcional, pero ayuda al proveedor '
                        'a llegar.'),
            acciones: [
              if (!_conMapa && puedeAbrirPorDireccion)
                _AccionAviso('Buscar la dirección', _abrirEnMaps),
            ],
          ),

        // Con mapa esto queda plegado, pero no se elimina: es la salida cuando
        // el mapa no carga.
        if (_conMapa) _pegarPlegable(tema),
      ],
    );
  }

  Widget _pegarPlegable(FlutterFlowTheme tema) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _pegarAbierto,
        onExpansionChanged: (v) => _pegarAbierto = v,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8.0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          'O pegar un enlace de Maps o unas coordenadas',
          style: tema.bodySmall.override(
            font: GoogleFonts.inter(),
            color: const Color(0xFF8A8A8A),
            fontSize: 13.0,
            letterSpacing: 0.0,
          ),
        ),
        children: [_campoPegar(tema)],
      ),
    );
  }

  Widget _campoPegar(FlutterFlowTheme tema) {
    return TextFormField(
      controller: _controlador,
      onChanged: _analizar,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Pega el enlace de Google Maps o «4.710989, -74.072092»',
        hintStyle: tema.labelMedium.override(
          font: GoogleFonts.inter(),
          color: const Color(0xFF8A8A8A),
          fontSize: 14.0,
          letterSpacing: 0.0,
        ),
        prefixIcon: Icon(
          Icons.place_outlined,
          size: 20.0,
          color: _punto != null ? tema.primary : const Color(0xFF8A8A8A),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pegar',
              icon: const Icon(Icons.content_paste_rounded, size: 18.0),
              onPressed: _pegarDelPortapapeles,
            ),
            if (_controlador.text.isNotEmpty)
              IconButton(
                tooltip: 'Quitar la ubicación',
                icon: const Icon(Icons.close_rounded, size: 18.0),
                onPressed: _limpiar,
              ),
          ],
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tema.alternate, width: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tema.alternate, width: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tema.error, width: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tema.error, width: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFAF9),
      ),
      style: tema.bodyMedium.override(
        font: GoogleFonts.inter(),
        fontSize: 15.0,
        letterSpacing: 0.0,
      ),
      cursorColor: tema.primaryText,
    );
  }
}

class _AccionAviso {
  const _AccionAviso(this.texto, this.alPulsar);
  final String texto;
  final Future<void> Function() alPulsar;
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.color,
    required this.texto,
    this.acciones = const [],
  });

  final IconData icono;
  final Color color;
  final String texto;
  final List<_AccionAviso> acciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 1.0, 6.0, 0.0),
            child: Icon(icono, size: 16.0, color: color),
          ),
          // Wrap y no Row: el texto y los enlaces van en linea cuando caben, y
          // saltan de renglon cuando no. Este selector vive dentro de columnas
          // estrechas de un formulario, donde una fila rigida se desborda.
          Expanded(
            child: Wrap(
              spacing: 10.0,
              runSpacing: 2.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  texto,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: color,
                        fontSize: 13.0,
                        letterSpacing: 0.0,
                      ),
                ),
                for (final accion in acciones)
                  InkWell(
                    onTap: () => accion.alPulsar(),
                    child: Text(
                      accion.texto,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: FlutterFlowTheme.of(context).primary,
                            fontSize: 13.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
