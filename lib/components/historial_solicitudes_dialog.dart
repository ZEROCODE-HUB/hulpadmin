import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/hulp_modal_actions.dart';
import '/flutter_flow/solicitud_status_helpers.dart';

class ResultadoHistorialSolicitudes {
  const ResultadoHistorialSolicitudes.seleccionada(this.solicitud)
      : continuarSinHistorial = false;

  const ResultadoHistorialSolicitudes.continuarSinHistorial()
      : solicitud = null,
        continuarSinHistorial = true;

  final VwSolicitudesServiciosCompletaRow? solicitud;
  final bool continuarSinHistorial;
}

class HistorialSolicitudesDialog extends StatefulWidget {
  const HistorialSolicitudesDialog({
    super.key,
    required this.nombreCliente,
    required this.solicitudes,
  });

  final String nombreCliente;
  final List<VwSolicitudesServiciosCompletaRow> solicitudes;

  @override
  State<HistorialSolicitudesDialog> createState() =>
      _HistorialSolicitudesDialogState();
}

class _HistorialSolicitudesDialogState
    extends State<HistorialSolicitudesDialog> {
  static const int _pageSize = 5;
  static const double _anchoMinimoTabla = 960;

  late final List<VwSolicitudesServiciosCompletaRow> _solicitudes;
  final _scrollTabla = ScrollController();
  VwSolicitudesServiciosCompletaRow? _seleccionada;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _solicitudes = _ordenar(widget.solicitudes);
  }

  @override
  void dispose() {
    _scrollTabla.dispose();
    super.dispose();
  }

  List<VwSolicitudesServiciosCompletaRow> _ordenar(
    List<VwSolicitudesServiciosCompletaRow> solicitudes,
  ) {
    final ordenadas = [...solicitudes];
    ordenadas.sort((a, b) {
      final fechaA = a.solicitudCreadaEn ??
          a.fecha ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.solicitudCreadaEn ??
          b.fecha ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final porFecha = fechaB.compareTo(fechaA);
      if (porFecha != 0) return porFecha;
      final porTicket = (b.ticket ?? 0).compareTo(a.ticket ?? 0);
      if (porTicket != 0) return porTicket;
      return (b.solicitudId ?? '').compareTo(a.solicitudId ?? '');
    });
    return ordenadas;
  }

  DateTime? _fechaReferencia(VwSolicitudesServiciosCompletaRow solicitud) =>
      solicitud.solicitudCreadaEn ?? solicitud.fecha;

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year}';
  }

  String _formatearHora(DateTime? hora) {
    if (hora == null) return '—';
    final horas = hora.hour.toString().padLeft(2, '0');
    final minutos = hora.minute.toString().padLeft(2, '0');
    return '$horas:$minutos';
  }

  String _nombreProveedor(VwSolicitudesServiciosCompletaRow solicitud) {
    final nombreCompleto = solicitud.proveedorNombreCompleto?.trim();
    if (nombreCompleto != null && nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }
    return [solicitud.proveedorNombres, solicitud.proveedorApellidos]
        .whereType<String>()
        .map((parte) => parte.trim())
        .where((parte) => parte.isNotEmpty)
        .join(' ');
  }

  bool _esCancelada(VwSolicitudesServiciosCompletaRow solicitud) {
    final estado = solicitud.estadoSolicitud?.trim().toLowerCase();
    return estado == 'canceladas' || estado == 'cancelada';
  }

  bool _puedeSeleccionar(VwSolicitudesServiciosCompletaRow solicitud) =>
      !_esCancelada(solicitud) &&
      (solicitud.solicitudId?.trim().isNotEmpty ?? false);

  String _estadoLabel(String? estado) {
    switch (estado?.trim().toLowerCase()) {
      case 'entrantes':
        return 'Pendiente';
      case 'aceptadas':
        return 'Aceptado';
      case 'canceladas':
      case 'cancelada':
        return 'Cancelado';
      case 'finalizadas':
        return 'Finalizado';
      case 'reagendadas':
      case 'reagendada':
        return 'Reagendada';
      case 'en camino':
        return 'En camino';
      case 'en proceso':
        return 'En curso';
      default:
        return estado?.trim().isNotEmpty == true ? estado!.trim() : '—';
    }
  }

  int get _totalPaginas {
    final total = _solicitudes.length;
    return total == 0 ? 1 : (total / _pageSize).ceil();
  }

  List<VwSolicitudesServiciosCompletaRow> get _solicitudesPagina {
    final solicitudes = _solicitudes;
    final inicio = _pagina * _pageSize;
    final fin = (inicio + _pageSize).clamp(0, solicitudes.length).toInt();
    return solicitudes.sublist(inicio, fin);
  }

  void _seleccionar(VwSolicitudesServiciosCompletaRow solicitud) {
    if (!_puedeSeleccionar(solicitud)) return;
    setState(() => _seleccionada = solicitud);
  }

  Widget _encabezado(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historial de solicitudes',
                style: theme.titleLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.nombreCliente} · Elige una solicitud para completar el formulario',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar historial',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _celdaTitulo(
    BuildContext context,
    String texto, {
    int flex = 1,
  }) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );

  Widget _celda(
    FlutterFlowTheme theme,
    String? valor, {
    required int flex,
    bool mostrarCompleto = false,
  }) {
    final texto = valor?.trim() ?? '';
    final contenido = Text(
      texto.isEmpty ? '—' : texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.bodyMedium,
    );
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: mostrarCompleto && texto.isNotEmpty
            ? Tooltip(message: texto, child: contenido)
            : contenido,
      ),
    );
  }

  Widget _fila(
    BuildContext context,
    VwSolicitudesServiciosCompletaRow solicitud,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final seleccionable = _puedeSeleccionar(solicitud);
    final seleccionada = _seleccionada != null &&
        _seleccionada!.solicitudId == solicitud.solicitudId;
    final estado = solicitud.estadoSolicitud;
    final foreground = solicitudStatusForegroundColor(estado);
    final background = solicitudStatusBackgroundColor(estado);

    return Semantics(
      button: seleccionable,
      selected: seleccionada,
      child: Material(
        color: seleccionada
            ? theme.primary.withValues(alpha: 0.09)
            : theme.secondaryBackground,
        child: InkWell(
          onTap: seleccionable ? () => _seleccionar(solicitud) : null,
          child: Opacity(
            opacity: seleccionable ? 1 : 0.58,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.alternate, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Radio<String>(
                      value: solicitud.solicitudId ?? '',
                      groupValue: _seleccionada?.solicitudId,
                      onChanged:
                          seleccionable ? (_) => _seleccionar(solicitud) : null,
                      activeColor: theme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  _celda(theme, _formatearFecha(_fechaReferencia(solicitud)),
                      flex: 2),
                  _celda(theme, _formatearHora(solicitud.hora?.time), flex: 2),
                  _celda(theme,
                      solicitud.servicioNombre ?? 'Servicio no disponible',
                      flex: 3),
                  _celda(theme, solicitud.solicitudCiudad, flex: 2),
                  _celda(theme, solicitud.ubicacion,
                      flex: 5, mostrarCompleto: true),
                  _celda(
                    theme,
                    _nombreProveedor(solicitud),
                    flex: 3,
                    mostrarCompleto: true,
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            child: Text(
                              _estadoLabel(estado),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabla(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final solicitudes = _solicitudesPagina;
    final total = _solicitudes.length;
    final desde = _pagina * _pageSize + 1;
    final hasta = (desde + solicitudes.length - 1).clamp(0, total).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Ordenadas por fecha de solicitud, más reciente primero',
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Scrollbar(
            controller: _scrollTabla,
            thumbVisibility: constraints.maxWidth < _anchoMinimoTabla,
            child: SingleChildScrollView(
              controller: _scrollTabla,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < _anchoMinimoTabla
                    ? _anchoMinimoTabla
                    : constraints.maxWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 48),
                        _celdaTitulo(context, 'Fecha', flex: 2),
                        _celdaTitulo(context, 'Hora', flex: 2),
                        _celdaTitulo(context, 'Servicio', flex: 3),
                        _celdaTitulo(context, 'Ciudad', flex: 2),
                        _celdaTitulo(context, 'Dirección', flex: 5),
                        _celdaTitulo(context, 'Proveedor', flex: 3),
                        _celdaTitulo(context, 'Estado', flex: 2),
                      ],
                    ),
                    for (final solicitud in solicitudes)
                      _fila(context, solicitud),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_seleccionada != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Se completarán los datos disponibles de esta solicitud. El precio será el vigente del catálogo.',
              style: theme.bodySmall.copyWith(color: theme.primary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecciona una solicitud para usar sus datos.',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando $desde–$hasta de $total solicitudes',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ),
            IconButton(
              tooltip: 'Página anterior',
              onPressed: _pagina > 0 ? () => setState(() => _pagina--) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Página ${_pagina + 1} de $_totalPaginas',
              style: theme.bodySmall,
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: _pagina + 1 < _totalPaginas
                  ? () => setState(() => _pagina++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contenido(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_solicitudes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Este usuario todavía no tiene solicitudes anteriores. Puedes continuar con el ingreso manual.',
          textAlign: TextAlign.center,
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
      );
    }
    return SingleChildScrollView(child: _tabla(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: theme.secondaryBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1120,
          maxHeight: viewportHeight * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _encabezado(context),
              const SizedBox(height: 12),
              Divider(color: theme.alternate, height: 1),
              const SizedBox(height: 14),
              Flexible(child: _contenido(context)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      const ResultadoHistorialSolicitudes
                          .continuarSinHistorial(),
                    ),
                    child: const Text('Continuar sin historial'),
                  ),
                  hulpModalCloseButton(
                    text: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                    ),
                  hulpModalPrimaryButton(
                    context: context,
                    text: 'Usar solicitud',
                    onPressed: _seleccionada == null
                        ? null
                        : () => Navigator.of(context).pop(
                              ResultadoHistorialSolicitudes.seleccionada(
                                _seleccionada!,
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
