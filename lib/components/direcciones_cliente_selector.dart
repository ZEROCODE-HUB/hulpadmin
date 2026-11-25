import '/backend/direcciones_cliente.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/supabase/supabase.dart';
import 'agregar_direccion_cliente_widget.dart';
import 'package:flutter/material.dart';

class DireccionesClienteSelector extends StatefulWidget {
  const DireccionesClienteSelector(
      {super.key,
      required this.usuarioId,
      required this.nombreCliente,
      required this.onSeleccion,
      this.seleccionada,
      this.onSinDirecciones,
      this.repository});
  final String usuarioId;
  final String nombreCliente;
  final String? seleccionada;
  final ValueChanged<DireccionCliente> onSeleccion;
  final VoidCallback? onSinDirecciones;
  final DireccionesClienteRepository? repository;
  @override
  State<DireccionesClienteSelector> createState() => _SelectorState();
}

class _SelectorState extends State<DireccionesClienteSelector> {
  late final _repository = widget.repository ?? DireccionesClienteRepository();
  List<DireccionCliente>? _direcciones;
  List<CiudadesRow> _ciudades = [];
  bool _error = false;
  int _version = 0;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(DireccionesClienteSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usuarioId != oldWidget.usuarioId) _cargar();
  }

  Future<void> _cargar() async {
    final version = ++_version;
    setState(() {
      _direcciones = null;
      _error = false;
    });
    try {
      final direcciones = await _repository.cargar(widget.usuarioId);
      final ciudades = await _repository.ciudades();
      if (!mounted || version != _version) return;
      setState(() {
        _direcciones = direcciones;
        _ciudades = ciudades;
      });
      if (direcciones.isEmpty) widget.onSinDirecciones?.call();
    } catch (_) {
      if (mounted && version == _version) setState(() => _error = true);
    }
  }

  Future<void> _agregar() async {
    final usuarioId = widget.usuarioId;
    final result = await showDialog<DireccionCliente>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AgregarDireccionClienteWidget(
            usuarioId: usuarioId,
            nombreCliente: widget.nombreCliente,
            repository: _repository));
    if (!mounted || usuarioId != widget.usuarioId || result == null) return;
    setState(() {
      _direcciones = [...?_direcciones, result];
    });
    widget.onSeleccion(result);
  }

  String _detalle(DireccionCliente direccion) {
    final ciudades = _ciudades.where((c) => c.id == direccion.ciudadId);
    return '${direccion.completa}${ciudades.isEmpty ? '' : ' · ${ciudades.first.nombre}'}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final puedeAgregar = !_error && _direcciones != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Direcciones guardadas',
          style: tema.bodyMedium.copyWith(fontSize: 16)),
      const SizedBox(height: 8),
      if (_error)
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('No se pudieron cargar las direcciones.',
                  style: tema.bodySmall.copyWith(color: tema.error)),
              TextButton(
                  onPressed: _cargar,
                  style: TextButton.styleFrom(foregroundColor: tema.primary),
                  child: const Text('Reintentar')),
            ])
      else if (_direcciones == null)
        LinearProgressIndicator(
            color: tema.primary, backgroundColor: tema.alternate)
      else if (_direcciones!.isEmpty)
        Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
                'Sin direcciones guardadas. Agrega una o escribe la dirección manualmente.',
                style: tema.bodySmall.copyWith(
                    fontSize: 14, color: tema.secondaryText, height: 1.5)))
      else
        LayoutBuilder(
            builder: (context, constraints) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final direccion in _direcciones!)
                      Tooltip(
                        message:
                            '${direccion.etiqueta} · ${_detalle(direccion)}',
                        child: Semantics(
                          label:
                              '${direccion.etiqueta} · ${_detalle(direccion)}',
                          button: true,
                          selected: widget.seleccionada == direccion.id,
                          child: Material(
                            key: ValueKey('direccion_${direccion.id}'),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            color: widget.seleccionada == direccion.id
                                ? tema.primary
                                : const Color(0xFFFBFAF9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  width: .5,
                                  color: widget.seleccionada == direccion.id
                                      ? tema.primary
                                      : tema.alternate),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => widget.onSeleccion(direccion),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth.isFinite
                                          ? (constraints.maxWidth - 48)
                                              .clamp(1.0, 440.0)
                                              .toDouble()
                                          : 440),
                                  child: Text(
                                      widget.seleccionada == direccion.id ||
                                              _direcciones!
                                                      .where((d) =>
                                                          d.etiqueta ==
                                                          direccion.etiqueta)
                                                      .length >
                                                  1
                                          ? '${direccion.etiqueta} · ${direccion.completa}'
                                          : direccion.etiqueta,
                                      softWrap: false,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tema.bodyMedium.copyWith(
                                        inherit: false,
                                        fontSize: 16,
                                        color:
                                            widget.seleccionada == direccion.id
                                                ? Colors.white
                                                : tema.primaryText,
                                        shadows: const [],
                                        decoration: TextDecoration.none,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    _botonOtra(tema, puedeAgregar),
                  ],
                )),
      if (_error || _direcciones == null || _direcciones!.isEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _botonOtra(tema, puedeAgregar)),
      const SizedBox(height: 12),
    ]);
  }

  Widget _botonOtra(FlutterFlowTheme tema, bool puedeAgregar) => CustomPaint(
        foregroundPainter: _BordeDiscontinuo(
            tema.primary.withValues(alpha: puedeAgregar ? .65 : .25)),
        child: TextButton.icon(
          onPressed: puedeAgregar ? _agregar : null,
          style: TextButton.styleFrom(
            foregroundColor: tema.primary,
            disabledForegroundColor: tema.secondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(0, 44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: tema.bodyMedium
                .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Otra'),
        ),
      );
}

// Borde decorativo: no intercepta el foco, hover ni clic del botón.
class _BordeDiscontinuo extends CustomPainter {
  const _BordeDiscontinuo(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5), const Radius.circular(8)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double inicio = 0; inicio < metric.length; inicio += 6) {
        canvas.drawPath(
            metric.extractPath(
                inicio, (inicio + 3).clamp(0, metric.length).toDouble()),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BordeDiscontinuo oldDelegate) =>
      oldDelegate.color != color;
}
