import 'solicitud_responsive_fields.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/supabase/profesionales_query.dart';
import '/components/item_widget.dart';
import '/components/fecha_hora_solicitud_widget.dart';
import '/components/searchable_dropdown_widget.dart';
import '/components/selector_ubicacion_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/dialog_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:async';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'crear_solicitud_model.dart';
export 'crear_solicitud_model.dart';

class CrearSolicitudWidget extends StatefulWidget {
  const CrearSolicitudWidget({super.key});

  @override
  State<CrearSolicitudWidget> createState() => _CrearSolicitudWidgetState();
}

class _CrearSolicitudWidgetState extends State<CrearSolicitudWidget> {
  late CrearSolicitudModel _model;
  final _fechaHoraKey = GlobalKey<FechaHoraSolicitudWidgetState>();
  DateTime? _selectedServiceDate;
  DateTime? _selectedServiceTime;
  bool get _legacyDateTimePickerEnabled => false;

  void _updateSelectedServiceDateTime() {
    final date = _selectedServiceDate;
    final time = _selectedServiceTime;
    safeSetState(() {
      _model.datePicked = date == null || time == null
          ? null
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<List<CiudadesRow>> _consultarCiudadesActivas() =>
      _model.ciudadesActivasRequest ??= CiudadesTable().queryRows(
        queryFn: (q) => q.eqOrNull('activo', true),
      );

  Future<List<ServiciosRow>> _consultarServiciosDisponibles() =>
      _model.serviciosDisponiblesRequest ??= ServiciosTable().queryRows(
        queryFn: (q) => q.order('nombre', ascending: true),
      );

  Future<List<VwSolicitudesServiciosCompletaRow>>
      _consultarHistorialCliente(String clienteId) {
    if (_model.historialClienteId != clienteId) {
      _model.historialClienteId = clienteId;
      _model.historialSolicitudesRequest =
          VwSolicitudesServiciosCompletaTable().queryRows(
        queryFn: (q) => q.eqOrNull('usuario_id', clienteId),
      );
    }
    return _model.historialSolicitudesRequest!;
  }

  void _seleccionarCliente(String? usuarioId, List<UsuariosRow> usuarios) {
    final cliente =
        usuarios.where((usuario) => usuario.id == usuarioId).firstOrNull;
    safeSetState(() {
      _model.usuarioSeleccionadoValue = usuarioId;
      _model.clienteAutocompletadoId = usuarioId;
      _model.historialClienteId = null;
      _model.historialSolicitudesRequest = null;
      _model.servicioHistorialNoDisponible = null;
      _model.ciudadHistorialNoDisponible = null;

      // Una sugerencia pertenece al cliente anterior. Al cambiarlo se puede
      // reemplazar; una elección manual no se toca.
      if (_model.servicioSugeridoPorHistorial &&
          !_model.servicioEditadoManualmente) {
        _model.servicioSeleccValue = null;
        _model.servicioSugeridoPorHistorial = false;
        _model.precioss = null;
        _model.precio = '0';
        _model.preciobaseTextController?.text = '0';
      }
      if (_model.ciudadSugeridaPorHistorial &&
          !_model.ciudadEditadaManualmente) {
        _model.ciudadSeleccValue = null;
        _model.ciudadSugeridaPorHistorial = false;
      }
    });

    if (cliente == null) return;
    _aplicarDireccionCliente(cliente);
    _aplicarCiudadCliente(cliente);
    unawaited(_aplicarSugerenciasHistorial(cliente.id));
  }

  VwSolicitudesServiciosCompletaRow? _seleccionarSolicitudDeReferencia(
    List<VwSolicitudesServiciosCompletaRow> historial,
  ) {
    final candidatas = historial
        .where((solicitud) => solicitud.estadoSolicitud != 'canceladas')
        .toList();

    if (candidatas.isEmpty) return null;
    candidatas.sort((a, b) {
      final creadaEnA = a.solicitudCreadaEn ??
          a.fecha ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final creadaEnB = b.solicitudCreadaEn ??
          b.fecha ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final porCreacion = creadaEnB.compareTo(creadaEnA);
      if (porCreacion != 0) return porCreacion;
      return (b.ticket ?? 0).compareTo(a.ticket ?? 0);
    });
    return candidatas.first;
  }

  bool get _puedeReemplazarServicioConHistorial =>
      (_model.servicioSeleccValue?.isEmpty ?? true) ||
      (_model.servicioSugeridoPorHistorial &&
          !_model.servicioEditadoManualmente);

  bool get _puedeReemplazarCiudadConHistorial =>
      (_model.ciudadSeleccValue?.isEmpty ?? true) ||
      ((_model.ciudadSugeridaPorCliente || _model.ciudadSugeridaPorHistorial) &&
          !_model.ciudadEditadaManualmente);

  Future<void> _aplicarSugerenciasHistorial(String clienteId) async {
    try {
      final historial = await _consultarHistorialCliente(clienteId);
      final referencia = _seleccionarSolicitudDeReferencia(historial);
      final servicios = await _consultarServiciosDisponibles();
      final ciudades = await _consultarCiudadesActivas();

      if (!mounted || _model.usuarioSeleccionadoValue != clienteId) return;

      final servicioId = referencia?.servicioId;
      final servicio = servicioId == null
          ? null
          : servicios.where((item) => item.id == servicioId).firstOrNull;
      final ciudadHistorica = referencia?.solicitudCiudad?.trim() ?? '';
      final ciudad = ciudadHistorica.isEmpty
          ? null
          : ciudades
              .where(
                (item) =>
                    item.nombre.trim().toLowerCase() ==
                    ciudadHistorica.toLowerCase(),
              )
              .firstOrNull;

      safeSetState(() {
        if (_puedeReemplazarServicioConHistorial) {
          if (servicio == null) {
            if (_model.servicioSugeridoPorHistorial) {
              _model.servicioSeleccValue = null;
            }
            _model.servicioSugeridoPorHistorial = false;
            _model.servicioHistorialNoDisponible = servicioId == null
                ? null
                : 'El servicio del historial ya no está disponible. Selecciona otro.';
          } else {
            _model.servicioSeleccValue = servicio.id;
            _model.servicioSugeridoPorHistorial = true;
            _model.servicioEditadoManualmente = false;
            _model.servicioHistorialNoDisponible = null;
          }
        }

        if (_puedeReemplazarCiudadConHistorial) {
          if (ciudad == null) {
            if (_model.ciudadSugeridaPorHistorial) {
              _model.ciudadSeleccValue = null;
            }
            _model.ciudadSugeridaPorHistorial = false;
            _model.ciudadHistorialNoDisponible = ciudadHistorica.isEmpty
                ? null
                : 'La ciudad del historial no está disponible. Selecciona una ciudad.';
          } else {
            _model.ciudadSeleccValue = ciudad.id;
            _model.ciudadSugeridaPorCliente = false;
            _model.ciudadSugeridaPorHistorial = true;
            _model.ciudadEditadaManualmente = false;
            _model.ciudadPerfilNoDisponible = null;
            _model.ciudadHistorialNoDisponible = null;
          }
        }
      });

      // Es el precio vigente del catálogo del servicio sugerido, no el precio
      // de la solicitud histórica. Mantiene el mismo comportamiento que al
      // seleccionar ese servicio manualmente.
      if (servicio != null &&
          _model.servicioSeleccValue == servicio.id &&
          _model.servicioSugeridoPorHistorial) {
        unawaited(_cargarPrecioServicio(servicio.id));
      }
    } catch (_) {
      if (!mounted || _model.usuarioSeleccionadoValue != clienteId) return;
      safeSetState(() {
        _model.servicioHistorialNoDisponible =
            'No se pudieron consultar las sugerencias del historial.';
      });
    }
  }

  void _aplicarDireccionCliente(UsuariosRow cliente) {
    final direccionSugerida = cliente.direccion?.trim() ?? '';
    final puedeReemplazar =
        (_model.direccionTextController?.text.trim().isEmpty ?? true) ||
            (_model.direccionSugeridaPorCliente &&
                !_model.direccionEditadaManualmente);

    if (!puedeReemplazar) return;

    safeSetState(() {
      if (direccionSugerida.isEmpty) {
        if (_model.direccionSugeridaPorCliente) {
          _model.direccionTextController?.clear();
          _model.coordenadas = null;
        }
        _model.direccionSugeridaPorCliente = false;
        _model.direccionEditadaManualmente = false;
        return;
      }

      _model.direccionTextController?.text = direccionSugerida;
      // El perfil no tiene coordenadas. No se puede conservar un punto de
      // mapa anterior para una dirección sugerida distinta.
      _model.coordenadas = null;
      _model.direccionSugeridaPorCliente = true;
      _model.direccionEditadaManualmente = false;
    });
  }

  Future<void> _aplicarCiudadCliente(UsuariosRow cliente) async {
    final ciudadPerfil = cliente.ciudad?.trim() ?? '';
    final puedeReemplazar =
        (_model.ciudadSeleccValue?.isEmpty ?? true) ||
            (_model.ciudadSugeridaPorCliente &&
                !_model.ciudadEditadaManualmente);

    if (!puedeReemplazar) return;

    try {
      final ciudades = await _consultarCiudadesActivas();
      if (!mounted || _model.usuarioSeleccionadoValue != cliente.id) return;

      final ciudadNormalizada = ciudadPerfil.toLowerCase();
      final ciudad = ciudades
          .where(
            (item) => item.nombre.trim().toLowerCase() == ciudadNormalizada,
          )
          .firstOrNull;

      // El historial tiene prioridad. Esta comprobación debe hacerse después
      // de esperar las ciudades porque ambas sugerencias son asíncronas.
      if (_model.ciudadSugeridaPorHistorial ||
          _model.ciudadEditadaManualmente) {
        return;
      }

      safeSetState(() {
        if (ciudad == null) {
          if (_model.ciudadSugeridaPorCliente) {
            _model.ciudadSeleccValue = null;
          }
          _model.ciudadSugeridaPorCliente = false;
          _model.ciudadEditadaManualmente = false;
          _model.ciudadPerfilNoDisponible = ciudadPerfil.isEmpty
              ? null
              : 'La ciudad del perfil no está disponible. Selecciona una ciudad.';
          return;
        }

        _model.ciudadSeleccValue = ciudad.id;
        _model.ciudadSugeridaPorCliente = true;
        _model.ciudadEditadaManualmente = false;
        _model.ciudadPerfilNoDisponible = null;
      });
    } catch (_) {
      if (!mounted || _model.usuarioSeleccionadoValue != cliente.id) return;
      safeSetState(() {
        _model.ciudadPerfilNoDisponible =
            'No se pudo sugerir la ciudad del perfil.';
      });
    }
  }

  void _marcarDireccionComoManual() {
    safeSetState(() {
      _model.direccionSugeridaPorCliente = false;
      _model.direccionEditadaManualmente = true;
    });
  }

  void _seleccionarCiudadManualmente(String? ciudadId) {
    safeSetState(() {
      _model.ciudadSeleccValue = ciudadId;
      _model.ciudadSugeridaPorCliente = false;
      _model.ciudadSugeridaPorHistorial = false;
      _model.ciudadEditadaManualmente = true;
      _model.ciudadPerfilNoDisponible = null;
      _model.ciudadHistorialNoDisponible = null;
    });
  }

  void _seleccionarServicioManualmente(String? servicioId) {
    safeSetState(() {
      _model.servicioSeleccValue = servicioId;
      _model.servicioSugeridoPorHistorial = false;
      _model.servicioEditadoManualmente = true;
      _model.servicioHistorialNoDisponible = null;
    });
    if (servicioId == null) return;
    unawaited(_cargarPrecioServicio(servicioId));
  }

  Future<void> _cargarPrecioServicio(String servicioId) async {
    final servicios = await _consultarServiciosDisponibles();
    if (!mounted || _model.servicioSeleccValue != servicioId) return;
    final servicio = servicios.where((item) => item.id == servicioId).firstOrNull;
    if (servicio == null) return;
    safeSetState(() {
      _model.precioss = [servicio];
      _model.precio = servicio.precio.toString();
      _model.preciobaseTextController?.text = servicio.precio.toString();
    });
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CrearSolicitudModel());

    _model.descripcionTextController ??= TextEditingController();
    _model.descripcionFocusNode ??= FocusNode();

    _model.direccionTextController ??= TextEditingController();
    _model.direccionFocusNode ??= FocusNode();

    _model.preciobaseTextController ??= TextEditingController();
    _model.preciobaseFocusNode ??= FocusNode();

    _model.notasTextController ??= TextEditingController();
    _model.notasFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: MediaQuery.sizeOf(context).width < 700 ? 8 : 0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: FutureBuilder<List<UsuariosRow>>(
            future: UsuariosTable().queryRows(queryFn: (q) => q),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }

              return Form(
                key: _model.formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24.0),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTwoColumnRow(
                                _buildUsuarioField(context, snapshot.data!),
                                _buildProfesionalField(context),
                              ),
                              const SizedBox(height: 16.0),
                              _buildTwoColumnRow(
                                _buildServicioField(context),
                                _buildCiudadField(context),
                              ),
                              const SizedBox(height: 16.0),
                              _buildTwoColumnRow(
                                _buildPrecioField(context),
                                _buildPreciosAdicionalesSection(context),
                              ),
                              const SizedBox(height: 16.0),
                              _buildTwoColumnRow(
                                _buildFechaHoraField(context),
                                _buildDireccionYUbicacionField(context),
                                crossAxisAlignment: CrossAxisAlignment.start,
                              ),
                              const SizedBox(height: 16.0),
                              _buildTwoColumnRow(
                                _buildDescripcionField(context),
                                _buildNotasField(context),
                              ),
                              const SizedBox(height: 24.0),
                              Align(
                                alignment: AlignmentDirectional.center,
                                child: FFButtonWidget(
                                  onPressed: () => _guardarSolicitud(context),
                                  text: 'Continuar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    width: 320.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w500),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48.0, height: 48.0),
        Flexible(
            child: Text(
          'Crear solicitud',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                fontSize: 22.0,
                letterSpacing: 0.0,
              ),
        )),
        IconButton(
          tooltip: 'Cerrar',
          constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          padding: const EdgeInsets.all(12.0),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 24.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnRow(Widget left, Widget right,
      {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return SolicitudResponsiveFields(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16.0),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildFieldLabel(BuildContext context, String text) => Text(
        text,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.normal),
              fontSize: 16.0,
              letterSpacing: 0.0,
            ),
      );

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final border = OutlineInputBorder(
      borderSide:
          BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 0.5),
      borderRadius: BorderRadius.circular(8.0),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
            font: GoogleFonts.inter(),
            color: const Color(0xFF8A8A8A),
            fontSize: 16.0,
            letterSpacing: 0.0,
          ),
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border.copyWith(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).error,
          width: 0.5,
        ),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).error,
          width: 0.5,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFFBFAF9),
    );
  }

  Widget _buildUsuarioField(
      BuildContext context, List<UsuariosRow> usuarios) {
    final users = usuarios
        .sortedList(keyOf: (e) => e.nombres ?? '', desc: false)
        .where((e) => e.rol == 'usuario')
        .toList();
    final userLabels = users
        .map((u) => '${u.nombres ?? ''} ${u.apellidos ?? ''}'.trim())
        .toList();
    final userSearchTexts = users
        .map(
          (u) => [
            u.nombres ?? '',
            u.apellidos ?? '',
            u.telefono ?? '',
            u.correoElectronico ?? '',
          ].join(' '),
        )
        .toList();
    final userDetails = users
        .map(
          (u) => [
            if ((u.telefono ?? '').trim().isNotEmpty) u.telefono!.trim(),
            if ((u.correoElectronico ?? '').trim().isNotEmpty)
              u.correoElectronico!.trim(),
          ].join(' · '),
        )
        .toList();
    final secondaryUsers = usuarios.where((e) => e.rol == 'usuario').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Usuario *'),
        const SizedBox(height: 8.0),
        SearchableDropdown(
          values: users.map((u) => u.id).toList(),
          labels: userLabels,
          searchTexts: userSearchTexts,
          details: userDetails,
          selectedValue: _model.usuarioSeleccionadoValue,
          onChanged: (val) => _seleccionarCliente(val, users),
          hint: 'Seleccionar usuario...',
          searchHint: 'Nombre, teléfono o correo',
        ),
        if (currentUserUid == '-1') ...[
          const SizedBox(height: 8.0),
          SearchableDropdown(
            values: secondaryUsers.map((u) => u.id!).toList(),
            labels: secondaryUsers.map((u) => u.nombres ?? '').toList(),
            selectedValue: _model.usuarioSeleccionado2Value,
            onChanged: (val) => safeSetState(
                () => _model.usuarioSeleccionado2Value = val),
            hint: 'Seleccionar usuario...',
          ),
        ],
      ],
    );
  }

  Widget _buildProfesionalField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Profesional (Opcional)'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<VwProfesionalesCompletoRow>>(
          future: _model.profesionalesDisponiblesRequest ??=
              consultarProfesionales(estado: 'activo', verificado: 'verificado'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'No se pudieron cargar los profesionales',
                style: FlutterFlowTheme.of(context).bodySmall,
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              );
            }
            final proveedores = porProveedor(snapshot.data!).toList()
              ..sort((a, b) =>
                  (a.nombres ?? '').compareTo(b.nombres ?? ''));
            return SearchableDropdown(
              values: proveedores
                  .map((p) => p.profesionalId ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(),
              labels: proveedores
                  .where((p) => (p.profesionalId ?? '').isNotEmpty)
                  .map((p) => p.nombreCompleto ??
                      '${p.nombres ?? ''} ${p.apellidos ?? ''}'.trim())
                  .toList(),
              selectedValue: _model.proveedorSeleccionadoValue,
              onChanged: (val) => safeSetState(
                  () => _model.proveedorSeleccionadoValue = val),
              hint: 'Sin asignar',
            );
          },
        ),
      ],
    );
  }

  Widget _buildServicioField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Servicio *'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<ServiciosRow>>(
          future: _consultarServiciosDisponibles(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildLoadingField(context);
            }
            final servicios = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  values: servicios.map((s) => s.id).toList(),
                  labels: servicios.map((s) => s.nombre).toList(),
                  selectedValue: _model.servicioSeleccValue,
                  onChanged: _seleccionarServicioManualmente,
                  hint: 'Seleccione el servicio',
                ),
                if (_model.servicioSugeridoPorHistorial) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    'Sugerido según la última solicitud no cancelada',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],
                if (_model.servicioHistorialNoDisponible != null) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    _model.servicioHistorialNoDisponible!,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          color: FlutterFlowTheme.of(context).error,
                        ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCiudadField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Ciudad *'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<CiudadesRow>>(
          future: _consultarCiudadesActivas(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildLoadingField(context);
            }
            final ciudades = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  values: ciudades.map((c) => c.id).toList(),
                  labels: ciudades.map((c) => c.nombre).toList(),
                  selectedValue: _model.ciudadSeleccValue,
                  onChanged: _seleccionarCiudadManualmente,
                  hint: 'Seleccione la ciudad',
                ),
                if (_model.ciudadSugeridaPorHistorial) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    'Sugerida según la última solicitud no cancelada',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ] else if (_model.ciudadSugeridaPorCliente) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    'Ciudad sugerida desde el perfil',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],
                if (_model.ciudadPerfilNoDisponible != null) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    _model.ciudadPerfilNoDisponible!,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          color: FlutterFlowTheme.of(context).error,
                        ),
                  ),
                ],
                if (_model.ciudadHistorialNoDisponible != null) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    _model.ciudadHistorialNoDisponible!,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          color: FlutterFlowTheme.of(context).error,
                        ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingField(BuildContext context) => const SizedBox(
        height: 48.0,
        child: Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );

  Widget _buildPrecioField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Precio *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.preciobaseTextController,
          focusNode: _model.preciobaseFocusNode,
          decoration: _inputDecoration(
            context,
            valueOrDefault<String>(_model.precio, '0'),
          ),
          cursorColor: FlutterFlowTheme.of(context).primaryText,
          validator:
              _model.preciobaseTextControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  Widget _buildFechaHoraField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Fecha *'),
        const SizedBox(height: 8.0),
        FechaHoraSolicitudWidget(
          key: _fechaHoraKey,
          showInstructions: false,
          timeLabel: 'Hora *',
          onDateChanged: (date) {
            _selectedServiceDate = date;
            _updateSelectedServiceDateTime();
          },
          onTimeChanged: (time) {
            _selectedServiceTime = time;
            _updateSelectedServiceDateTime();
          },
        ),
      ],
    );
  }

  Widget _buildDireccionYUbicacionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel(context, 'Dirección *'),
            if (_model.direccionSugeridaPorCliente) ...[
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Sugerida desde el perfil',
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.direccionTextController,
          focusNode: _model.direccionFocusNode,
          decoration: _inputDecoration(context, 'Digite la dirección'),
          cursorColor: FlutterFlowTheme.of(context).primaryText,
          onChanged: (_) => _marcarDireccionComoManual(),
          validator:
              _model.direccionTextControllerValidator.asValidator(context),
        ),
        const SizedBox(height: 8.0),
        SelectorUbicacionWidget(
          ciudadId: _model.ciudadSeleccValue,
          direccionActual: () => _model.direccionTextController.text,
          onCambio: (punto) => safeSetState(() {
            _model.coordenadas = punto;
            _model.direccionSugeridaPorCliente = false;
            _model.direccionEditadaManualmente = true;
          }),
          onDireccionSugerida: (valor) {
            safeSetState(() {
              _model.direccionTextController?.text = valor;
              _model.direccionSugeridaPorCliente = false;
              _model.direccionEditadaManualmente = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescripcionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Descripción *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.descripcionTextController,
          focusNode: _model.descripcionFocusNode,
          minLines: 5,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: _inputDecoration(context, 'Describe la solicitud...'),
          cursorColor: FlutterFlowTheme.of(context).primaryText,
          validator:
              _model.descripcionTextControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  Widget _buildNotasField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Notas'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.notasTextController,
          focusNode: _model.notasFocusNode,
          minLines: 5,
          maxLines: 5,
          decoration:
              _inputDecoration(context, 'Agrega notas adicionales...'),
          cursorColor: FlutterFlowTheme.of(context).primaryText,
          validator: _model.notasTextControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  Future<void> _guardarSolicitud(BuildContext context) async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate() ||
        _model.servicioSeleccValue == null) {
      return;
    }
    if (_model.ciudadSeleccValue == null || _model.ciudadSeleccValue == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la ciudad')),
      );
      return;
    }
    if (!(_fechaHoraKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final tieneProfesional = _model.proveedorSeleccionadoValue != null &&
          _model.proveedorSeleccionadoValue != '';
      await SolicitudesServicioTable().insert({
        'usuario_id': _model.usuarioSeleccionadoValue,
        'descripcion': _model.descripcionTextController.text,
        'ubicacion': _model.direccionTextController.text,
        'fecha': supaSerialize<DateTime>(
            functions.formatTimestamp(_model.datePicked!, true)),
        'hora': supaSerialize<PostgresTime>(
            PostgresTime(functions.formatTimestamp(_model.datePicked!, false))),
        'precio':
            valueOrDefault<double>(_model.precioss?.firstOrNull?.precio, 0.0),
        'estado': tieneProfesional ? 'aceptadas' : 'entrantes',
        'servicio_id': _model.servicioSeleccValue,
        'estado_pago': 'pendiente',
        'precio_base':
            valueOrDefault<double>(_model.precioss?.firstOrNull?.precio, 0.0),
        'precio_adicionales': _model.preciosAdicionalesSolicitud
            .fold(0.0, (s, e) => s + e.total),
        'servicio_nombre': _model.precioss?.firstOrNull?.nombre,
        'tipo': 'externo',
        'informacion_adicional': _model.notasTextController.text,
        if (tieneProfesional)
          'profesional_id': _model.proveedorSeleccionadoValue,
        'ciudad_id': _model.ciudadSeleccValue,
        'latitud': _model.coordenadas?.latitud,
        'longitud': _model.coordenadas?.longitud,
      });
      Navigator.pop(context);
      context.goNamed(SolicitudesWidget.routeName);
      safeSetState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear la solicitud: $e',
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Widget _buildLegacy(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 20.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 800.0,
          ),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: FutureBuilder<List<UsuariosRow>>(
            future: UsuariosTable().queryRows(
              queryFn: (q) => q,
            ),
            builder: (context, snapshot) {
              // Customize what your widget looks like when it's loading.
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }
              List<UsuariosRow> formUsuariosRowList = snapshot.data!;

              return Form(
                key: _model.formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Opacity(
                              opacity: 0.0,
                              child: Icon(
                                Icons.close,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                'Crear solicitud',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      fontSize: 22.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.close,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 24.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Usuario *',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                        Builder(builder: (context) {
                                          final users = formUsuariosRowList
                                              .sortedList(
                                                  keyOf: (e) => e.nombres ?? '',
                                                  desc: false)
                                              .where((e) => e.rol == 'usuario')
                                              .toList();
                                          return SearchableDropdown(
                                            values: users
                                                .map((u) => u.id!)
                                                .toList(),
                                            labels: users
                                                .map((u) =>
                                                    '${u.nombres ?? ''} ${u.apellidos ?? ''}'
                                                        .trim())
                                                .toList(),
                                            selectedValue:
                                                _model.usuarioSeleccionadoValue,
                                            onChanged: (val) => safeSetState(() =>
                                                _model.usuarioSeleccionadoValue =
                                                    val),
                                            hint: 'Seleccionar usuario...',
                                          );
                                        }),
                                        if (currentUserUid == '-1')
                                          Builder(builder: (context) {
                                            final users = formUsuariosRowList
                                                .where(
                                                    (e) => e.rol == 'usuario')
                                                .toList();
                                            return SearchableDropdown(
                                              values: users
                                                  .map((u) => u.id!)
                                                  .toList(),
                                              labels: users
                                                  .map((u) => u.nombres ?? '')
                                                  .toList(),
                                              selectedValue: _model
                                                  .usuarioSeleccionado2Value,
                                              onChanged: (val) => safeSetState(
                                                  () => _model
                                                          .usuarioSeleccionado2Value =
                                                      val),
                                              hint: 'Seleccionar usuario...',
                                            );
                                          }),
                                      ].divide(SizedBox(height: 8.0)),
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Profesional (Opcional)',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                        FutureBuilder<
                                            List<VwProfesionalesCompletoRow>>(
                                          future: _model
                                                  .profesionalesDisponiblesRequest ??=
                                              consultarProfesionales(
                                            estado: 'activo',
                                            verificado: 'verificado',
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return Text(
                                                'No se pudieron cargar los profesionales',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall,
                                              );
                                            }
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            }

                                            final proveedores = porProveedor(
                                              snapshot.data!,
                                            ).toList()
                                              ..sort((a, b) => (a.nombres ?? '')
                                                  .compareTo(b.nombres ?? ''));

                                            return SearchableDropdown(
                                              values: proveedores
                                                  .map((p) =>
                                                      p.profesionalId ?? '')
                                                  .where((id) => id.isNotEmpty)
                                                  .toList(),
                                              labels: proveedores
                                                  .where((p) =>
                                                      (p.profesionalId ?? '')
                                                          .isNotEmpty)
                                                  .map((p) =>
                                                      p.nombreCompleto ??
                                                      '${p.nombres ?? ''} ${p.apellidos ?? ''}'
                                                          .trim())
                                                  .toList(),
                                              selectedValue: _model
                                                  .proveedorSeleccionadoValue,
                                              onChanged: (val) => safeSetState(
                                                  () => _model
                                                      .proveedorSeleccionadoValue =
                                                  val),
                                              hint: 'Sin asignar',
                                            );
                                          },
                                        ),
                                      ].divide(SizedBox(height: 8.0)),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Descripcion *',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Container(
                                            // Antes pedia el ancho entero de la
                                            // pantalla dentro de una columna que
                                            // ocupa la mitad: el Row lo recortaba
                                            // igualmente, asi que solo servia
                                            // para confundir.
                                            width: double.infinity,
                                            child: TextFormField(
                                              controller: _model
                                                  .descripcionTextController,
                                              focusNode:
                                                  _model.descripcionFocusNode,
                                              autofocus: false,
                                              obscureText: false,
                                              // Es lo que el proveedor lee para
                                              // saber a que va: cabe mas de una
                                              // linea y crece hasta seis.
                                              minLines: 4,
                                              maxLines: 6,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              textInputAction:
                                                  TextInputAction.newline,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                labelStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                hintText:
                                                    'Digite la descripción',
                                                hintStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF8A8A8A),
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                filled: true,
                                                fillColor: Color(0xFFFBFAF9),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                              cursorColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              validator: _model
                                                  .descripcionTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dirección *',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            child: TextFormField(
                                              controller: _model
                                                  .direccionTextController,
                                              focusNode:
                                                  _model.direccionFocusNode,
                                              autofocus: false,
                                              obscureText: false,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                labelStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                hintText: 'Digite la dirección',
                                                hintStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF8A8A8A),
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                filled: true,
                                                fillColor: Color(0xFFFBFAF9),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                              cursorColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              validator: _model
                                                  .direccionTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ),
                                          SelectorUbicacionWidget(
                                            ciudadId: _model.ciudadSeleccValue,
                                            direccionActual: () => _model
                                                .direccionTextController.text,
                                            onCambio: (punto) =>
                                                _model.coordenadas = punto,
                                            // Al fijar el punto se rellena la
                                            // direccion con el nombre que le
                                            // da Google, para que el texto y
                                            // el punto no se contradigan.
                                            onDireccionSugerida: (valor) =>
                                                safeSetState(() => _model
                                                    .direccionTextController
                                                    ?.text = valor),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 24.0)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Precio *',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          Container(
                                            width: double.infinity,
                                            child: TextFormField(
                                              controller: _model
                                                  .preciobaseTextController,
                                              focusNode:
                                                  _model.preciobaseFocusNode,
                                              autofocus: false,
                                              obscureText: false,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                labelStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                hintText:
                                                    valueOrDefault<String>(
                                                  _model.precio,
                                                  '0',
                                                ),
                                                hintStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF8A8A8A),
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 0.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                filled: true,
                                                fillColor: Color(0xFFFBFAF9),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                              cursorColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              validator: _model
                                                  .preciobaseTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 3,
                                      child: _buildPreciosAdicionalesSection(
                                          context),
                                    ),
                                  ].divide(SizedBox(width: 12.0)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Servicio *',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          FutureBuilder<List<ServiciosRow>>(
                                            future: ServiciosTable().queryRows(
                                              queryFn: (q) => q,
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<ServiciosRow>
                                                  servicioSeleccServiciosRowList =
                                                  snapshot.data!;

                                              return SearchableDropdown(
                                                values:
                                                    servicioSeleccServiciosRowList
                                                        .map((s) => s.id)
                                                        .toList(),
                                                labels:
                                                    servicioSeleccServiciosRowList
                                                        .map((s) =>
                                                            s.nombre ?? '')
                                                        .toList(),
                                                selectedValue:
                                                    _model.servicioSeleccValue,
                                                onChanged: (val) {
                                                  safeSetState(() => _model
                                                          .servicioSeleccValue =
                                                      val);
                                                  if (val != null) {
                                                    ServiciosTable()
                                                        .queryRows(
                                                      queryFn: (q) =>
                                                          q.eqOrNull('id', val),
                                                    )
                                                        .then((rows) {
                                                      _model.precioss = rows;
                                                      if (rows.isNotEmpty) {
                                                        _model.precio = rows
                                                                .first.precio
                                                                ?.toString() ??
                                                            '0';
                                                        safeSetState(() {
                                                          _model
                                                              .preciobaseTextController
                                                              ?.text = rows
                                                                  .first.precio
                                                                  ?.toString() ??
                                                              '0';
                                                        });
                                                      }
                                                    });
                                                  }
                                                },
                                                hint: 'Seleccione el servicio',
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding: EdgeInsetsDirectional
                                                .fromSTEB(0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Ciudad*',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    fontSize: 16.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                          FutureBuilder<List<CiudadesRow>>(
                                            future: CiudadesTable().queryRows(
                                              queryFn: (q) =>
                                                  q.eqOrNull('activo', true),
                                            ),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<CiudadesRow>
                                                  ciudadSeleccCiudadesRowList =
                                                  snapshot.data!;

                                              return SearchableDropdown(
                                                values: ciudadSeleccCiudadesRowList
                                                    .map((c) => c.id)
                                                    .toList(),
                                                labels: ciudadSeleccCiudadesRowList
                                                    .map((c) => c.nombre)
                                                    .toList(),
                                                selectedValue:
                                                    _model.ciudadSeleccValue,
                                                onChanged: (val) {
                                                  safeSetState(() => _model
                                                      .ciudadSeleccValue = val);
                                                },
                                                hint: 'Seleccione la ciudad',
                                              );
                                            },
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha*',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                            ),
                                          ),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: 480.0),
                                            child: FechaHoraSolicitudWidget(
                                              key: _fechaHoraKey,
                                              onDateChanged: (date) {
                                                _selectedServiceDate = date;
                                                _updateSelectedServiceDateTime();
                                              },
                                              onTimeChanged: (time) {
                                                _selectedServiceTime = time;
                                                _updateSelectedServiceDateTime();
                                              },
                                            ),
                                          ),
                                          if (_legacyDateTimePickerEnabled)
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              final _datePickedDate =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    getCurrentTimestamp,
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime(2050),
                                                builder: (context, child) {
                                                  return wrapInMaterialDatePickerTheme(
                                                    context,
                                                    child!,
                                                    headerBackgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    headerForegroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .info,
                                                    headerTextStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineLarge
                                                            .override(
                                                              font: GoogleFonts
                                                                  .interTight(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineLarge
                                                                    .fontStyle,
                                                              ),
                                                              fontSize: 32.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle: FlutterFlowTheme
                                                                      .of(context)
                                                                  .headlineLarge
                                                                  .fontStyle,
                                                            ),
                                                    pickerBackgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    pickerForegroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                    selectedDateTimeBackgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    selectedDateTimeForegroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .info,
                                                    actionButtonForegroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                    iconSize: 24.0,
                                                  );
                                                },
                                              );

                                              TimeOfDay? _datePickedTime;
                                              if (_datePickedDate != null) {
                                                _datePickedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime:
                                                      TimeOfDay.fromDateTime(
                                                          getCurrentTimestamp),
                                                  builder: (context, child) {
                                                    return wrapInMaterialTimePickerTheme(
                                                      context,
                                                      child!,
                                                      headerBackgroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      headerForegroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .info,
                                                      headerTextStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineLarge
                                                              .override(
                                                                font: GoogleFonts
                                                                    .interTight(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineLarge
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 32.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineLarge
                                                                    .fontStyle,
                                                              ),
                                                      pickerBackgroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryBackground,
                                                      pickerForegroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      selectedDateTimeBackgroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      selectedDateTimeForegroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .info,
                                                      actionButtonForegroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      iconSize: 24.0,
                                                    );
                                                  },
                                                );
                                              }

                                              if (_datePickedDate != null &&
                                                  _datePickedTime != null) {
                                                safeSetState(() {
                                                  _model.datePicked = DateTime(
                                                    _datePickedDate.year,
                                                    _datePickedDate.month,
                                                    _datePickedDate.day,
                                                    _datePickedTime!.hour,
                                                    _datePickedTime.minute,
                                                  );
                                                });
                                              } else if (_model.datePicked !=
                                                  null) {
                                                safeSetState(() {
                                                  _model.datePicked =
                                                      getCurrentTimestamp;
                                                });
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 13.0, 12.0, 13.0),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFFBFAF9),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                border: Border.all(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _model.datePicked != null
                                                          ? dateTimeFormat(
                                                              "d/M/yyyy  HH:mm",
                                                              _model.datePicked)
                                                          : 'Seleccione fecha y hora',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(),
                                                            color: _model
                                                                        .datePicked !=
                                                                    null
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText
                                                                : Color(
                                                                    0xFF8A8A8A),
                                                            fontSize: 16.0,
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons
                                                        .calendar_month_outlined,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    size: 20.0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 24.0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 24.0, 0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notas',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          1.0,
                                      child: TextFormField(
                                        controller: _model.notasTextController,
                                        focusNode: _model.notasFocusNode,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          hintText: 'Ingresa notas',
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          filled: true,
                                          fillColor: Color(0xFFFBFAF9),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        maxLines: 5,
                                        minLines: 5,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        validator: _model
                                            .notasTextControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 8.0)),
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 42.0, 0.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                if (_model.formKey.currentState == null ||
                                    !_model.formKey.currentState!.validate()) {
                                  return;
                                }
                                if (_model.servicioSeleccValue == null) {
                                  return;
                                }
                                if (_model.ciudadSeleccValue == null ||
                                    _model.ciudadSeleccValue == '') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Seleccione la ciudad'),
                                    ),
                                  );
                                  return;
                                }
                                if (!(_fechaHoraKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                try {
                                  // El `ticket` lo autogenera la secuencia
                                  // `ticket_seq` (DEFAULT de la columna). Ya no se
                                  // calcula "último+1" aquí: ese cálculo manual
                                  // insertaba el ticket sin avanzar la secuencia,
                                  // la desincronizaba y rompía el agendamiento en
                                  // la app de usuarios (ver migración 0002).
                                  if (_model.proveedorSeleccionadoValue ==
                                          null ||
                                      _model.proveedorSeleccionadoValue == '') {
                                    await SolicitudesServicioTable().insert({
                                      'usuario_id':
                                          _model.usuarioSeleccionadoValue,
                                      'descripcion':
                                          _model.descripcionTextController.text,
                                      'ubicacion':
                                          _model.direccionTextController.text,
                                      'fecha': supaSerialize<DateTime>(
                                          functions.formatTimestamp(
                                              _model.datePicked!, true)),
                                      'hora': supaSerialize<PostgresTime>(
                                          PostgresTime(
                                              functions.formatTimestamp(
                                                  _model.datePicked!, false))),
                                      'precio': valueOrDefault<double>(
                                        _model.precioss?.firstOrNull?.precio,
                                        0.0,
                                      ),
                                      'estado': 'entrantes',
                                      'servicio_id': _model.servicioSeleccValue,
                                      'estado_pago': 'pendiente',
                                      'precio_base': valueOrDefault<double>(
                                        _model.precioss?.firstOrNull?.precio,
                                        0.0,
                                      ),
                                      'precio_adicionales': _model
                                          .preciosAdicionalesSolicitud
                                          .fold(0.0, (s, e) => s + e.total),
                                      'servicio_nombre':
                                          _model.precioss?.firstOrNull?.nombre,
                                      'tipo': 'externo',
                                      'informacion_adicional':
                                          _model.notasTextController.text,
                                      'ciudad_id': _model.ciudadSeleccValue,
                                      // Van juntas o no van: la restriccion
                                      // de la tabla rechaza media coordenada.
                                      'latitud': _model.coordenadas?.latitud,
                                      'longitud': _model.coordenadas?.longitud,
                                    });
                                  } else {
                                    await SolicitudesServicioTable().insert({
                                      'usuario_id':
                                          _model.usuarioSeleccionadoValue,
                                      'descripcion':
                                          _model.descripcionTextController.text,
                                      'ubicacion':
                                          _model.direccionTextController.text,
                                      'fecha': supaSerialize<DateTime>(
                                          functions.formatTimestamp(
                                              _model.datePicked!, true)),
                                      'hora': supaSerialize<PostgresTime>(
                                          PostgresTime(
                                              functions.formatTimestamp(
                                                  _model.datePicked!, false))),
                                      'precio': valueOrDefault<double>(
                                        _model.precioss?.firstOrNull?.precio,
                                        0.0,
                                      ),
                                      'estado': 'aceptadas',
                                      'servicio_id': _model.servicioSeleccValue,
                                      'estado_pago': 'pendiente',
                                      'precio_base': valueOrDefault<double>(
                                        _model.precioss?.firstOrNull?.precio,
                                        0.0,
                                      ),
                                      'precio_adicionales': _model
                                          .preciosAdicionalesSolicitud
                                          .fold(0.0, (s, e) => s + e.total),
                                      'servicio_nombre':
                                          _model.precioss?.firstOrNull?.nombre,
                                      'tipo': 'externo',
                                      'informacion_adicional':
                                          _model.notasTextController.text,
                                      'profesional_id':
                                          _model.proveedorSeleccionadoValue,
                                      'ciudad_id': _model.ciudadSeleccValue,
                                      // Van juntas o no van: la restriccion
                                      // de la tabla rechaza media coordenada.
                                      'latitud': _model.coordenadas?.latitud,
                                      'longitud': _model.coordenadas?.longitud,
                                    });
                                  }

                                  Navigator.pop(context);
                                  context.goNamed(SolicitudesWidget.routeName);
                                  safeSetState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al crear la solicitud: $e',
                                        style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                        ),
                                      ),
                                      duration: Duration(milliseconds: 4000),
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).error,
                                    ),
                                  );
                                }
                              },
                              text: 'Continuar',
                              options: FFButtonOptions(
                                height: 48.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreciosAdicionalesSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios adicionales',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.normal),
                fontSize: 16.0,
                letterSpacing: 0.0,
              ),
        ),
        Builder(
          builder: (context) => InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await showMapSafeDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog(
                  elevation: 0,
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                  backgroundColor: Colors.transparent,
                  alignment: AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  child: ItemWidget(
                    action: (item) async {
                      safeSetState(() {
                        _model.addToPreciosAdicionalesSolicitud(item);
                      });
                    },
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFFBFAF9),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).alternate,
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Agregar ítem',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: Color(0xFF8A8A8A),
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                          ),
                    ),
                    Icon(Icons.add_circle_outline,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_model.preciosAdicionalesSolicitud.isNotEmpty)
          Builder(
            builder: (context) {
              final items = _model.preciosAdicionalesSolicitud.toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      6.0, 2.0, 6.0, 2.0),
                                  child: Text(item.tipoItem,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                              font: GoogleFonts.inter(),
                                              letterSpacing: 0.0)),
                                ),
                              ),
                              SizedBox(width: 6.0),
                              Flexible(
                                child: Text(item.descripcion,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                            font: GoogleFonts.inter(),
                                            letterSpacing: 0.0)),
                              ),
                            ]),
                            Text(
                              functions.formatPrices(item.total),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: () async {
                          _model
                              .removeAtIndexFromPreciosAdicionalesSolicitud(i);
                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFD80715),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                8.0, 4.0, 8.0, 4.0),
                            child: Icon(
                              Icons.delete_forever,
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              size: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 12.0)),
                  );
                }).divide(SizedBox(height: 8.0)),
              );
            },
          ),
        if (_model.preciosAdicionalesSolicitud.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total adicionales:',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500)),
              Text(
                functions.formatPrices(_model.preciosAdicionalesSolicitud
                    .fold(0.0, (s, e) => s + e.total)),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
      ].divide(SizedBox(height: 8.0)),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.inter(),
            color: Color(0xFF8A8A8A),
            fontSize: 16.0,
            letterSpacing: 0.0,
          ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).alternate, width: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).error, width: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: FlutterFlowTheme.of(context).error, width: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Color(0xFFFBFAF9),
      contentPadding: EdgeInsetsDirectional.fromSTEB(12.0, 14.0, 12.0, 14.0),
    );
  }
}
