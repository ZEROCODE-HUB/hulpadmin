import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'solicitud_historial_datos.dart';

const _fondoHistorial = Color(0xFFEEEEEE);
const _lineaHistorial = Color(0xFFDDDDDD);

enum _Filtro {
  todo('Todo'),
  operacion('Operación'),
  cambios('Cambios');

  const _Filtro(this.etiqueta);
  final String etiqueta;
}

class SolicitudHistorialWidget extends StatefulWidget {
  const SolicitudHistorialWidget({
    super.key,
    required this.solicitudId,
    required this.visible,
  });

  final String? solicitudId;
  final bool visible;

  @override
  State<SolicitudHistorialWidget> createState() =>
      _SolicitudHistorialWidgetState();
}

class _SolicitudHistorialWidgetState extends State<SolicitudHistorialWidget> {
  Future<List<ActividadSolicitud>>? _historial;
  _Filtro _filtro = _Filtro.todo;

  @override
  void initState() {
    super.initState();
    _cargarAlAbrir();
  }

  @override
  void didUpdateWidget(covariant SolicitudHistorialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solicitudId != widget.solicitudId) {
      _historial = null;
      _filtro = _Filtro.todo;
    }
    _cargarAlAbrir();
  }

  void _cargarAlAbrir() {
    if (widget.visible) _historial ??= _cargar(widget.solicitudId);
  }

  Future<List<ActividadSolicitud>> _cargar(String? id) async {
    if (id == null) return [];
    final respuesta = await SupaFlow.client.functions.invoke(
      'solicitudes-finanzas',
      body: {'accion': 'historial_admin', 'id': id},
    );
    await initializeDateFormatting('es_CO');
    return leerActividadesSolicitud(respuesta.data as Map);
  }

  @override
  Widget build(BuildContext context) {
    if (_historial == null) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Actividad de la solicitud',
              style: theme.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final filtro in _Filtro.values)
                ChoiceChip(
                  label: Text(filtro.etiqueta),
                  selected: _filtro == filtro,
                  onSelected: (_) => setState(() => _filtro = filtro),
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: _filtro == filtro
                        ? theme.primary
                        : const Color(0xFFC6C6C6),
                  ),
                  selectedColor: theme.primary,
                  backgroundColor: theme.secondaryBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: theme.bodyMedium.copyWith(
                    color: _filtro == filtro ? Colors.white : theme.primaryText,
                    fontWeight:
                        _filtro == filtro ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FutureBuilder<List<ActividadSolicitud>>(
              key: ValueKey(widget.solicitudId),
              future: _historial,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return widget.visible
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo cargar el historial.',
                            textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => setState(() {
                            _historial = _cargar(widget.solicitudId);
                          }),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                return _lineaDeTiempo(snapshot.data ?? const [], theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaDeTiempo(
      List<ActividadSolicitud> actividades, FlutterFlowTheme theme) {
    final dias = <DateTime, List<ActividadSolicitud>>{};
    for (final actividad in actividades) {
      if (_filtro == _Filtro.operacion && actividad.esFinanciera ||
          _filtro == _Filtro.cambios && !actividad.esFinanciera) {
        continue;
      }
      final fecha = actividad.fechaColombia;
      final dia = DateTime.utc(fecha.year, fecha.month, fecha.day);
      dias.putIfAbsent(dia, () => []).add(actividad);
    }
    if (dias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          actividades.isEmpty
              ? 'Sin información de historial para mostrar.'
              : 'No hay actividad para este filtro.',
          textAlign: TextAlign.center,
          style: theme.bodyMedium,
        ),
      );
    }

    final formatoFecha = DateFormat("d 'de' MMMM 'de' y", 'es_CO');
    return ListView(
      primary: false,
      children: [
        for (final MapEntry(key: dia, value: eventos) in dias.entries) ...[
          Container(
            decoration: BoxDecoration(
              color: _fondoHistorial,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Text(formatoFecha.format(dia),
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                for (final (indice, evento) in eventos.indexed)
                  _EventoHistorial(
                    actividad: evento,
                    primero: indice == 0,
                    ultimo: indice == eventos.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EventoHistorial extends StatelessWidget {
  const _EventoHistorial({
    required this.actividad,
    required this.primero,
    required this.ultimo,
  });

  final ActividadSolicitud actividad;
  final bool primero;
  final bool ultimo;

  IconData get _icono => switch (actividad.tipo) {
        TipoActividadSolicitud.creada => Icons.add,
        TipoActividadSolicitud.aceptada ||
        TipoActividadSolicitud.finalizada =>
          Icons.check,
        TipoActividadSolicitud.enCamino => Icons.local_shipping_outlined,
        TipoActividadSolicitud.iniciada => Icons.play_arrow_outlined,
        TipoActividadSolicitud.financiera => Icons.edit_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fecha = actividad.fechaColombia;
    final hora = '${DateFormat('h:mm', 'es_CO').format(fecha)} '
        '${fecha.hour < 12 ? 'a. m.' : 'p. m.'}';
    final secundaria = theme.bodyMedium.copyWith(color: theme.secondaryText);
    final titulo =
        theme.bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Stack(
        children: [
          if (!primero || !ultimo)
            Positioned(
              left: 17,
              top: primero ? 18 : 0,
              bottom: ultimo ? null : 0,
              height: ultimo ? 18 : null,
              width: 2,
              child: const ColoredBox(color: _lineaHistorial),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primary, width: 1.5),
                  ),
                  child: Icon(_icono, size: 18, color: theme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(actividad.titulo, style: titulo)),
                          const SizedBox(width: 8),
                          Text(hora, style: secundaria),
                        ],
                      ),
                      if (actividad.autor case final autor?)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(autor, style: secundaria),
                        ),
                      if (actividad.cambios.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _fondoHistorial,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final cambio in actividad.cambios)
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (actividad.cambios.length > 1 ||
                                          actividad.titulo ==
                                              'Desglose financiero actualizado')
                                        Text(cambio.campo, style: secundaria),
                                      Text(
                                          '${cambio.anterior} → ${cambio.nuevo}',
                                          style: theme.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w700)),
                                      if (actividad.cambios.length == 1 &&
                                          actividad.motivo != null)
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                                left: BorderSide(
                                                    color: theme.alternate)),
                                          ),
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Text(
                                              'Motivo: ${actividad.motivo}',
                                              style: secundaria),
                                        ),
                                    ],
                                  ),
                                if (actividad.cambios.length > 1 &&
                                    actividad.motivo != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Motivo: ${actividad.motivo}',
                                        style: secundaria),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
