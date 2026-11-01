import '/components/modal_con_encabezado_fijo.dart';
import '/web/solicitudes/menu_estado_solicitud.dart';
import 'solicitud_responsive_fields.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/actualizar_cliente_solicitud.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/supabase/profesionales_query.dart';
import '/components/item_widget.dart';
import '/components/fecha_hora_solicitud_widget.dart';
import '/components/searchable_dropdown_widget.dart';
import '/components/selector_ubicacion_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/components/dropdown_solicitud_estado_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/dialog_helpers.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'edicion_solicitud_model.dart';
export 'edicion_solicitud_model.dart';

class EdicionSolicitudWidget extends StatefulWidget {
  const EdicionSolicitudWidget({
    super.key,
    required this.solicitudId,
  });

  final String? solicitudId;

  @override
  State<EdicionSolicitudWidget> createState() => _EdicionSolicitudWidgetState();
}

class _EdicionSolicitudWidgetState extends State<EdicionSolicitudWidget> {
  late EdicionSolicitudModel _model;
  final _fechaHoraKey = GlobalKey<FechaHoraSolicitudWidgetState>();
  bool get _legacyDateTimePickerEnabled => false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdicionSolicitudModel());

    _model.nroSolicitudFocusNode ??= FocusNode();

    _model.nombreFocusNode1 ??= FocusNode();

    _model.nombreFocusNode2 ??= FocusNode();

    _model.nombreFocusNode3 ??= FocusNode();

    _model.nombreFocusNode4 ??= FocusNode();

    _model.nombreFocusNode5 ??= FocusNode();

    _model.nombreFocusNode6 ??= FocusNode();

    _model.nombreFocusNode7 ??= FocusNode();

    _model.nombreFocusNode8 ??= FocusNode();

    _model.nombreFocusNode9 ??= FocusNode();

    _model.nombreFocusNode10 ??= FocusNode();

    _model.nombreFocusNode11 ??= FocusNode();

    _model.nombreFocusNode12 ??= FocusNode();

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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: MediaQuery.sizeOf(context).width < 700 ? 8 : 0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: FutureBuilder<List<VwSolicitudesServiciosCompletaRow>>(
            future: VwSolicitudesServiciosCompletaTable().querySingleRow(
              queryFn: (q) => q.eqOrNull('solicitud_id', widget.solicitudId),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                );
              }
              final solicitud = snapshot.data!.firstOrNull;
              if (solicitud == null) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No se encontró la solicitud.'),
                );
              }
              return Form(
                key: _model.formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ModalConEncabezadoFijo(
                    encabezado: _buildEditHeader(context),
                    cuerpo: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24.0),
                        _buildTwoColumnRow(
                          _buildTicketField(context, solicitud),
                          _buildEstadoField(context, solicitud),
                        ),
                        const SizedBox(height: 24.0),
                        _buildSectionTitle(context, 'Datos del usuario'),
                        const SizedBox(height: 12.0),
                        _buildDatosUsuarioFields(context, solicitud),
                        const SizedBox(height: 24.0),
                        _buildTwoColumnRow(
                          _buildProfesionalField(context, solicitud),
                          _buildServicioField(context, solicitud),
                        ),
                        const SizedBox(height: 16.0),
                        _buildTwoColumnRow(
                          _buildCiudadField(context, solicitud),
                          _buildPrecioField(context, solicitud),
                        ),
                        const SizedBox(height: 16.0),
                        _buildPreciosAdicionalesSection(context),
                        const SizedBox(height: 16.0),
                        _buildTwoColumnRow(
                          _buildFechaHoraField(context, solicitud),
                          _buildDireccionYUbicacionField(context, solicitud),
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                        const SizedBox(height: 16.0),
                        _buildTwoColumnRow(
                          _buildDescripcionField(context, solicitud),
                          _buildNotasField(context, solicitud),
                        ),
                        const SizedBox(height: 16.0),
                        _buildContactContext(context, solicitud),
                        const SizedBox(height: 24.0),
                        Align(
                          alignment: AlignmentDirectional.center,
                          child: FFButtonWidget(
                            onPressed: () => _guardarEdicion(context, solicitud),
                            text: 'Guardar cambios',
                            options: FFButtonOptions(
                              height: 48.0,
                              width: 320.0,
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEditHeader(BuildContext context) {
    return EncabezadoModal(
      titulo: Text(
        'Editar solicitud',
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w500),
              fontSize: 22.0,
              letterSpacing: 0.0,
            ),
      ),
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

  Widget _buildDatosUsuarioFields(
    BuildContext context,
    VwSolicitudesServiciosCompletaRow solicitud,
  ) {
    final campos = [
      _buildUsuarioField(context, solicitud),
      _buildTelefonoClienteField(context, solicitud),
      _buildCorreoClienteField(context, solicitud),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En el modal de escritorio los tres datos pertenecen a un mismo
        // bloque y caben alineados. En pantallas angostas se conservan
        // legibles en una columna, sin alterar sus controles ni su lógica.
        if (constraints.maxWidth < 840.0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: campos.divide(const SizedBox(height: 16.0)),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: campos[0]),
            const SizedBox(width: 16.0),
            Expanded(child: campos[1]),
            const SizedBox(width: 16.0),
            Expanded(child: campos[2]),
          ],
        );
      },
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

  Widget _buildSectionTitle(BuildContext context, String text) => Text(
        text,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              fontSize: 20.0,
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
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 0.5),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 0.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFBFAF9),
    );
  }

  Widget _buildTicketField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nroSolicitudTextController ??=
        TextEditingController(text: '#${solicitud.ticket ?? ''}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Ticket'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nroSolicitudTextController,
          focusNode: _model.nroSolicitudFocusNode,
          readOnly: true,
          decoration: _inputDecoration(context, ''),
        ),
      ],
    );
  }

  Widget _buildEstadoField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    final estado = solicitud.estadoSolicitud ?? 'Sin estado';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Estado'),
        const SizedBox(height: 8.0),
        Builder(builder: (anchorContext) => OutlinedButton.icon(
          onPressed: () async {
            await mostrarMenuEstadoSolicitud(
              anchorContext: anchorContext,
              builder: (dialogContext) => Material(
                color: Colors.transparent,
                child: DropdownSolicitudEstadoWidget(
                  estadoActual: estado,
                  index: 1,
                  solicitudId: solicitud.solicitudId!,
                  actionnavegacion: () async => Navigator.pop(context),
                ),
              ),
            );
          },
          icon: const Icon(Icons.keyboard_arrow_down),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(_estadoLabel(estado)),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48.0),
            alignment: Alignment.centerLeft,
            foregroundColor: FlutterFlowTheme.of(context).primaryText,
            side: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        )),
      ],
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'entrantes':
        return 'Pendiente';
      case 'aceptadas':
        return 'Activo';
      case 'finalizadas':
        return 'Finalizado';
      case 'canceladas':
        return 'Cancelado';
      case 'en proceso':
        return 'En curso';
      default:
        return estado;
    }
  }

  Widget _buildUsuarioField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    final nombre = nombreClienteVisible(solicitud.clienteNombreCompleto);
    final controller = _model.nombreTextController1 ??= TextEditingController();
    if (controller.text != nombre) {
      controller.text = nombre;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Usuario *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          focusNode: _model.nombreFocusNode1,
          readOnly: true,
          maxLines: null,
          decoration: _inputDecoration(context, 'Usuario'),
        ),
      ],
    );
  }

  Widget _buildTelefonoClienteField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController2 ??=
        TextEditingController(text: solicitud.clienteTelefono ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Teléfono'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController2,
          focusNode: _model.nombreFocusNode2,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(context, 'Ingrese el teléfono'),
        ),
      ],
    );
  }

  Widget _buildCorreoClienteField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController3 ??=
        TextEditingController(text: solicitud.clienteCorreo ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Correo electrónico'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController3,
          focusNode: _model.nombreFocusNode3,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(context, 'Ingrese el correo electrónico'),
        ),
      ],
    );
  }

  Future<List<VwProfesionalesCompletoRow>> _profesionalesActivosVerificados(
      String? servicioId) {
    final clave = servicioId ?? '';
    return _model.profesionalesPorServicio.putIfAbsent(
      clave,
      () => consultarProfesionales(
        estado: 'activo',
        verificado: 'verificado',
        servicioId: servicioId,
      ),
    );
  }

  Widget _buildProfesionalField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    final servicioId = _model.servicioNuevoValue ?? solicitud.servicioId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Profesional (Opcional)'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<VwProfesionalesCompletoRow>>(
          future: _profesionalesActivosVerificados(servicioId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No se pudieron cargar los profesionales.');
            }
            if (!snapshot.hasData) return _buildLoadingField();
            final profesionales =
                porProveedor(snapshot.data!).toList()
                  ..sort((a, b) => (a.nombres ?? '').compareTo(b.nombres ?? ''));
            final profesionalActual =
                _model.profesionalNuevoValue ?? solicitud.profesionalId;
            final profesionalDisponible = profesionales.any(
              (p) => p.profesionalId == profesionalActual,
            );
            return SearchableDropdown(
              values: profesionales
                  .map((p) => p.profesionalId ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(),
              labels: profesionales
                  .where((p) => (p.profesionalId ?? '').isNotEmpty)
                  .map((p) => p.nombreCompleto ?? p.nombres ?? '')
                  .toList(),
              selectedValue: profesionalDisponible ? profesionalActual : null,
              onChanged: (value) => safeSetState(
                  () => _model.profesionalNuevoValue = value),
              hint: profesionalActual != null && !profesionalDisponible
                  ? 'Profesional asignado no disponible'
                  : 'Sin asignar',
            );
          },
        ),
      ],
    );
  }

  Widget _buildServicioField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Servicio *'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<ServiciosRow>>(
          future: ServiciosTable().queryRows(
            queryFn: (q) => q.eqOrNull('estado', 'activo').order('nombre', ascending: true),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoadingField();
            final servicios = snapshot.data!;
            return SearchableDropdown(
              values: servicios.map((s) => s.id).toList(),
              labels: servicios.map((s) => s.nombre ?? '').toList(),
              selectedValue: _model.servicioNuevoValue ?? solicitud.servicioId,
              onChanged: (value) => safeSetState(() {
                _model.servicioNuevoValue = value;
                _model.profesionalNuevoValue = null;
                _model.servicioNuevoNombre = servicios
                    .where((s) => s.id == value)
                    .map((s) => s.nombre)
                    .firstOrNull;
              }),
              hint: 'Seleccionar servicio...',
            );
          },
        ),
      ],
    );
  }

  Widget _buildCiudadField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Ciudad *'),
        const SizedBox(height: 8.0),
        FutureBuilder<List<CiudadesRow>>(
          future: CiudadesTable().queryRows(queryFn: (q) => q.eqOrNull('activo', true)),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoadingField();
            final ciudades = snapshot.data!;
            final ciudadActual = ciudades
                .where((c) => c.nombre == solicitud.solicitudCiudad)
                .map((c) => c.id)
                .firstOrNull;
            return SearchableDropdown(
              values: ciudades.map((c) => c.id).toList(),
              labels: ciudades.map((c) => c.nombre ?? '').toList(),
              selectedValue: _model.ciudadNuevaValue ?? ciudadActual,
              onChanged: (value) =>
                  safeSetState(() => _model.ciudadNuevaValue = value),
              hint: 'Seleccionar ciudad...',
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingField() => const SizedBox(
        height: 48.0,
        child: Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );

  Widget _buildPrecioField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController7 ??=
        TextEditingController(text: solicitud.precioBase?.toString() ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Precio base *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController7,
          focusNode: _model.nombreFocusNode7,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(context, '0'),
        ),
      ],
    );
  }

  Widget _buildFechaHoraField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Fecha *'),
        const SizedBox(height: 8.0),
        FechaHoraSolicitudWidget(
          key: _fechaHoraKey,
          initialDate: solicitud.fecha,
          initialTime: solicitud.hora?.time,
          firstDate: getCurrentTimestamp,
          lastDate: DateTime(2050),
          showInstructions: false,
          timeLabel: 'Hora *',
          onDateChanged: (date) => _model.datePicked1 = date,
          onTimeChanged: (time) => _model.datePicked2 = time,
        ),
      ],
    );
  }

  Widget _buildDireccionYUbicacionField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController6 ??=
        TextEditingController(text: solicitud.ubicacion ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Dirección *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController6,
          minLines: 2,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          focusNode: _model.nombreFocusNode6,
          decoration: _inputDecoration(context, 'Digite la dirección'),
        ),
        const SizedBox(height: 8.0),
        SelectorUbicacionWidget(
          key: ValueKey('ubicacion_${widget.solicitudId}'),
          ciudadId: _model.ciudadNuevaValue,
          nombreCiudad: _model.ciudadNuevaValue == null ? solicitud.solicitudCiudad : null,
          coordenadasIniciales: solicitud.latitud != null && solicitud.longitud != null
              ? Coordenadas(solicitud.latitud!, solicitud.longitud!)
              : null,
          direccionActual: () => _model.nombreTextController6?.text ?? '',
          onCambio: (punto) => _model.coordenadas = punto,
          onDireccionSugerida: (valor) => safeSetState(
              () => _model.nombreTextController6?.text = valor),
        ),
      ],
    );
  }

  Widget _buildDescripcionField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController4 ??=
        TextEditingController(text: solicitud.solicitudDescripcion ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Descripción *'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController4,
          focusNode: _model.nombreFocusNode4,
          minLines: 5,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          decoration: _inputDecoration(context, 'Describe la solicitud...'),
        ),
      ],
    );
  }

  Widget _buildNotasField(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    _model.nombreTextController12 ??=
        TextEditingController(text: solicitud.informacionAdicional ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, 'Notas'),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _model.nombreTextController12,
          focusNode: _model.nombreFocusNode12,
          minLines: 5,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          decoration: _inputDecoration(context, 'Agrega notas adicionales...'),
        ),
      ],
    );
  }

  Widget _buildContactContext(
      BuildContext context, VwSolicitudesServiciosCompletaRow solicitud) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF9),
        border: Border.all(color: theme.alternate, width: 0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        childrenPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        leading: Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(Icons.contact_page_outlined, color: theme.primary),
        ),
        title: Text(
          'Información actual de contacto',
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
            fontSize: 16.0,
            letterSpacing: 0.0,
          ),
        ),
        subtitle: Text(
          'Referencia de cliente y profesional',
          style: theme.bodySmall,
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cliente = _buildReadOnlyContext(
                context,
                'Cliente',
                Icons.person_outline,
                nombreClienteVisible(solicitud.clienteNombreCompleto),
                solicitud.clienteTelefono,
                solicitud.clienteCorreo,
              );
              final profesional = _buildReadOnlyContext(
                context,
                'Profesional asignado',
                Icons.engineering_outlined,
                solicitud.proveedorNombreCompleto,
                solicitud.proveedorTelefono,
                solicitud.proveedorCorreo,
              );

              if (constraints.maxWidth < 720.0) {
                return Column(
                  children: [
                    cliente,
                    const SizedBox(height: 12.0),
                    profesional,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cliente),
                  const SizedBox(width: 12.0),
                  Expanded(child: profesional),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyContext(
    BuildContext context,
    String title,
    IconData icon,
    String? nombre,
    String? telefono,
    String? correo,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final nombreVisible = (nombre ?? '').trim();
    final telefonoVisible = (telefono ?? '').trim();
    final correoVisible = (correo ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate, width: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.0, color: theme.primary),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildContactDetail(context, Icons.person_outline,
              nombreVisible.isEmpty ? 'Sin especificar' : nombreVisible),
          const SizedBox(height: 8.0),
          _buildContactDetail(context, Icons.phone_outlined,
              telefonoVisible.isEmpty ? 'Sin teléfono' : telefonoVisible),
          const SizedBox(height: 8.0),
          _buildContactDetail(context, Icons.mail_outline,
              correoVisible.isEmpty ? 'Sin correo' : correoVisible),
        ],
      ),
    );
  }

  Widget _buildContactDetail(BuildContext context, IconData icon, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              value,
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
          ),
        ],
      );

  Future<void> _guardarEdicion(BuildContext context,
      VwSolicitudesServiciosCompletaRow solicitud) async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate() ||
        !(_fechaHoraKey.currentState?.validate() ?? false)) {
      return;
    }

    final profesionalNuevo = _model.profesionalNuevoValue;
    final profesionalCambio = profesionalNuevo != null &&
        profesionalNuevo.isNotEmpty &&
        profesionalNuevo != solicitud.profesionalId;
    final usuarioId = solicitud.usuarioId;
    final telefono = _model.nombreTextController2?.text.trim() ?? '';
    final correo = _model.nombreTextController3?.text.trim() ?? '';
    final contactoCambio = telefono != (solicitud.clienteTelefono ?? '') ||
        correo != (solicitud.clienteCorreo ?? '');

    if (contactoCambio && usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al cliente.')),
      );
      return;
    }

    try {
      if (contactoCambio) {
        // La Edge Function también exige dirección y ciudad. Se consultan del
        // perfil del cliente, no de la solicitud: `ubicacion`, latitud y
        // longitud pertenecen exclusivamente al servicio solicitado.
        final clienteRows = await UsuariosTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('id', usuarioId!),
        );
        final cliente = clienteRows.firstOrNull;
        if (cliente == null) {
          throw const ActualizarClienteSolicitudException(
            'No se pudo obtener el perfil actual del cliente.',
          );
        }

        await actualizarClienteSolicitud(
          usuarioId: usuarioId!,
          telefono: telefono,
          correoElectronico: correo,
          direccion: cliente.direccion ?? '',
          ciudad: cliente.ciudad ?? '',
        );
      }

      await SolicitudesServicioTable().update(
        data: {
          'descripcion': _model.nombreTextController4?.text,
          'ubicacion': _model.nombreTextController6?.text,
          'latitud': _model.coordenadas?.latitud ?? solicitud.latitud,
          'longitud': _model.coordenadas?.longitud ?? solicitud.longitud,
          'fecha': supaSerialize<DateTime>(_model.datePicked1 ?? solicitud.fecha),
          'hora': supaSerialize<PostgresTime>(
              PostgresTime(_model.datePicked2 ?? solicitud.hora?.time)),
          if (profesionalCambio) 'profesional_id': profesionalNuevo,
          if (_model.servicioNuevoValue != null)
            'servicio_id': _model.servicioNuevoValue,
          if (_model.servicioNuevoNombre != null)
            'servicio_nombre': _model.servicioNuevoNombre,
          if (_model.ciudadNuevaValue != null) 'ciudad_id': _model.ciudadNuevaValue,
          'precio_base': double.tryParse(_model.nombreTextController7?.text ?? ''),
          // Los importes existentes solo vienen agregados desde la vista. Si
          // no se añadieron ítems nuevos, conservar el total almacenado.
          'precio_adicionales': _model.preciosAdicionalesSolicitud.isEmpty
              ? solicitud.precioAdicionales
              : _model.preciosAdicionalesSolicitud
                  .fold(0.0, (sum, item) => sum + item.total),
          'informacion_adicional': _model.nombreTextController12?.text,
          if (profesionalCambio && solicitud.estadoSolicitud == 'entrantes')
            'estado': 'aceptadas',
        },
        matchingRows: (rows) => rows.eqOrNull('id', widget.solicitudId),
      );

      if (profesionalCambio) {
        _model.apiResult0mz = await SendNotificationUserCall.call(
          userIdSupabase: profesionalNuevo,
          title: 'Solicitud asignada',
          message: 'Se ha reasignado la solicitud',
        );
        await SenNotificationUserHulpCall.call(
          userIdSupabase: usuarioId,
          title: 'Re asignación de servicio',
          message: 'Se ha reasignado tu solicitud',
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la solicitud: $error')),
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
          child: Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: FutureBuilder<List<VwSolicitudesServiciosCompletaRow>>(
                future: VwSolicitudesServiciosCompletaTable().querySingleRow(
                  queryFn: (q) => q.eqOrNull(
                    'solicitud_id',
                    widget!.solicitudId,
                  ),
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
                  List<VwSolicitudesServiciosCompletaRow>
                      columnVwSolicitudesServiciosCompletaRowList =
                      snapshot.data!;

                  final columnVwSolicitudesServiciosCompletaRow =
                      columnVwSolicitudesServiciosCompletaRowList.isNotEmpty
                          ? columnVwSolicitudesServiciosCompletaRowList.first
                          : null;

                  return SingleChildScrollView(
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
                                'Edición de la solicitud',
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
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Numero de solicitud',
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
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    child: TextFormField(
                                      controller:
                                          _model.nroSolicitudTextController ??=
                                              TextEditingController(
                                        text:
                                            '#${columnVwSolicitudesServiciosCompletaRow?.ticket?.toString()}',
                                      ),
                                      focusNode: _model.nroSolicitudFocusNode,
                                      autofocus: false,
                                      readOnly: true,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 16.0,
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
                                        hintText: 'Nombres',
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF8A8A8A),
                                              fontSize: 16.0,
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
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 0.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 0.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            width: 0.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
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
                                      cursorColor: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      validator: _model
                                          .nroSolicitudTextControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: 150.0,
                                decoration: BoxDecoration(),
                                alignment: AlignmentDirectional(1.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estado',
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
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF6F5F3),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 4.0,
                                            color: Color(0x0000004D),
                                            offset: Offset(
                                              0.0,
                                              2.0,
                                            ),
                                          )
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                      child: Builder(
                                        builder: (context) => InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await showMapSafeAlignedDialog<void>(
                                              barrierColor: Colors.transparent,
                                              context: context,
                                              isGlobal: false,
                                              avoidOverflow: false,
                                              targetAnchor:
                                                  AlignmentDirectional(0.0, 0.0)
                                                      .resolve(
                                                          Directionality.of(
                                                              context)),
                                              followerAnchor:
                                                  AlignmentDirectional(0.0, 0.0)
                                                      .resolve(
                                                          Directionality.of(
                                                              context)),
                                              builder: (dialogContext) {
                                                return Material(
                                                  color: Colors.transparent,
                                                  child:
                                                      DropdownSolicitudEstadoWidget(
                                                    estadoActual:
                                                        columnVwSolicitudesServiciosCompletaRow!
                                                            .estadoSolicitud!,
                                                    index: 1,
                                                    solicitudId:
                                                        columnVwSolicitudesServiciosCompletaRow!
                                                            .solicitudId!,
                                                    actionnavegacion: () async {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.keyboard_arrow_down_sharp,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 32.0,
                                                  decoration: BoxDecoration(
                                                    color: columnVwSolicitudesServiciosCompletaRow
                                                                ?.estadoSolicitud ==
                                                            'entrantes'
                                                        ? Color(0xFFE9EBEC)
                                                        : (columnVwSolicitudesServiciosCompletaRow
                                                                    ?.estadoSolicitud ==
                                                                'aceptadas'
                                                            ? Color(0xFFD6EAFF)
                                                            : (columnVwSolicitudesServiciosCompletaRow
                                                                        ?.estadoSolicitud ==
                                                                    'finalizadas'
                                                                ? Color(
                                                                    0xFFDFF9D2)
                                                                : (columnVwSolicitudesServiciosCompletaRow
                                                                            ?.estadoSolicitud ==
                                                                        'canceladas'
                                                                    ? Color(
                                                                        0xFFF9DCDF)
                                                                    : Color(
                                                                        0xFFFFF5D6)))),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24.0),
                                                    shape: BoxShape.rectangle,
                                                    border: Border.all(
                                                      color: columnVwSolicitudesServiciosCompletaRow
                                                                  ?.estadoSolicitud ==
                                                              'entrantes'
                                                          ? Color(0xFF6C757D)
                                                          : (columnVwSolicitudesServiciosCompletaRow
                                                                      ?.estadoSolicitud ==
                                                                  'aceptadas'
                                                              ? Color(
                                                                  0xFF007BFF)
                                                              : (columnVwSolicitudesServiciosCompletaRow
                                                                          ?.estadoSolicitud ==
                                                                      'finalizadas'
                                                                  ? Color(
                                                                      0xFF388212)
                                                                  : (columnVwSolicitudesServiciosCompletaRow
                                                                              ?.estadoSolicitud ==
                                                                          'canceladas'
                                                                      ? Color(
                                                                          0xFFDC3545)
                                                                      : Color(
                                                                          0xFFD6A100)))),
                                                    ),
                                                  ),
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 2.0,
                                                                8.0, 2.0),
                                                    child: Text(
                                                      columnVwSolicitudesServiciosCompletaRow
                                                                  ?.estadoSolicitud ==
                                                              'entrantes'
                                                          ? 'Pendiente'
                                                          : (columnVwSolicitudesServiciosCompletaRow
                                                                      ?.estadoSolicitud ==
                                                                  'aceptadas'
                                                              ? 'Activo'
                                                              : (columnVwSolicitudesServiciosCompletaRow
                                                                          ?.estadoSolicitud ==
                                                                      'canceladas'
                                                                  ? 'Cancelado'
                                                                  : (columnVwSolicitudesServiciosCompletaRow
                                                                              ?.estadoSolicitud ==
                                                                          'finalizadas'
                                                                      ? 'Finalizado'
                                                                      : 'En curso'))),
                                                      maxLines: 2,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: columnVwSolicitudesServiciosCompletaRow
                                                                            ?.estadoSolicitud ==
                                                                        'entrantes'
                                                                    ? Color(
                                                                        0xFF6C757D)
                                                                    : (columnVwSolicitudesServiciosCompletaRow?.estadoSolicitud ==
                                                                            'aceptadas'
                                                                        ? Color(
                                                                            0xFF007BFF)
                                                                        : (columnVwSolicitudesServiciosCompletaRow?.estadoSolicitud ==
                                                                                'finalizadas'
                                                                            ? Color(
                                                                                0xFF388212)
                                                                            : (columnVwSolicitudesServiciosCompletaRow?.estadoSolicitud == 'canceladas'
                                                                                ? Color(0xFFDC3545)
                                                                                : Color(0xFFD6A100)))),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
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
                                  ].divide(SizedBox(height: 8.0)),
                                ),
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
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 20.0),
                                  child: Text(
                                    'Datos del usuario',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 20.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 24.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nombre',
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
                                                      .nombreTextController1 ??=
                                                  TextEditingController(
                                                text: nombreClienteVisible(
                                                    columnVwSolicitudesServiciosCompletaRow
                                                        ?.clienteNombreCompleto),
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode1,
                                              autofocus: false,
                                              readOnly: true,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController1Validator
                                                  .asValidator(context),
                                            ),
                                          ),
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
                                            'Telefono',
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
                                                      .nombreTextController2 ??=
                                                  TextEditingController(
                                                text:
                                                    columnVwSolicitudesServiciosCompletaRow
                                                        ?.clienteTelefono,
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode2,
                                              autofocus: false,
                                              readOnly: true,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController2Validator
                                                  .asValidator(context),
                                            ),
                                          ),
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
                                            'Correo electronico',
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
                                                      .nombreTextController3 ??=
                                                  TextEditingController(
                                                text:
                                                    columnVwSolicitudesServiciosCompletaRow
                                                        ?.clienteCorreo,
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode3,
                                              autofocus: false,
                                              readOnly: true,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController3Validator
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
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 20.0),
                                  child: Text(
                                    'Datos del servicio',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 20.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
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
                                          'Servicio',
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
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          // Era un campo de solo lectura: el
                                          // tipo de servicio no se podia
                                          // corregir desde el admin.
                                          child:
                                              FutureBuilder<List<ServiciosRow>>(
                                            future: ServiciosTable().queryRows(
                                              queryFn: (q) => q
                                                  .eqOrNull('estado', 'activo')
                                                  .order('nombre',
                                                      ascending: true),
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
                                              final serviciosDisponibles =
                                                  snapshot.data!;

                                              return SearchableDropdown(
                                                values: serviciosDisponibles
                                                    .map((e) => e.id)
                                                    .toList(),
                                                labels: serviciosDisponibles
                                                    .map((e) => e.nombre)
                                                    .toList(),
                                                selectedValue: _model
                                                        .servicioNuevoValue ??
                                                    columnVwSolicitudesServiciosCompletaRow
                                                        ?.servicioId,
                                                onChanged: (val) =>
                                                    safeSetState(() {
                                                  _model.servicioNuevoValue =
                                                      val;
                                                  _model.servicioNuevoNombre =
                                                      serviciosDisponibles
                                                          .where((e) =>
                                                              e.id == val)
                                                          .map((e) => e.nombre)
                                                          .firstOrNull;
                                                }),
                                                hint: 'Seleccionar servicio...',
                                              );
                                            },
                                          ),
                                        ),
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
                                          'Subcategoria',
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
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          child: TextFormField(
                                            controller:
                                                _model.nombreTextController5 ??=
                                                    TextEditingController(
                                              text:
                                                  columnVwSolicitudesServiciosCompletaRow
                                                      ?.subcategoriaNombre,
                                            ),
                                            focusNode: _model.nombreFocusNode5,
                                            autofocus: false,
                                            readOnly: true,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
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
                                              hintText: 'Nombres',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            Color(0xFF8A8A8A),
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
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
                                                .nombreTextController5Validator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ].divide(SizedBox(height: 8.0)),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: FechaHoraSolicitudWidget(
                                  key: _fechaHoraKey,
                                  initialDate:
                                      columnVwSolicitudesServiciosCompletaRow
                                          ?.fecha,
                                  initialTime:
                                      columnVwSolicitudesServiciosCompletaRow
                                          ?.hora?.time,
                                  firstDate: getCurrentTimestamp,
                                  lastDate: DateTime(2050),
                                  onDateChanged: (date) {
                                    safeSetState(() {
                                      _model.datePicked1 = date;
                                    });
                                  },
                                  onTimeChanged: (time) {
                                    safeSetState(() {
                                      _model.datePicked2 = time;
                                    });
                                  },
                                ),
                              ),
                              if (_legacyDateTimePickerEnabled)
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha',
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
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              final _datePicked1Date =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    getCurrentTimestamp,
                                                firstDate: getCurrentTimestamp,
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

                                              if (_datePicked1Date != null) {
                                                safeSetState(() {
                                                  _model.datePicked1 = DateTime(
                                                    _datePicked1Date.year,
                                                    _datePicked1Date.month,
                                                    _datePicked1Date.day,
                                                  );
                                                });
                                              } else if (_model.datePicked1 !=
                                                  null) {
                                                safeSetState(() {
                                                  _model.datePicked1 =
                                                      getCurrentTimestamp;
                                                });
                                              }
                                            },
                                            child: Container(
                                              height: 40.0,
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
                                              child: Align(
                                                alignment: AlignmentDirectional(
                                                    -1.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          8.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "MMMEd",
                                                          columnVwSolicitudesServiciosCompletaRow
                                                              ?.fecha),
                                                      'Seleccionar',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
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
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
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
                                            'Hora',
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
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              final _datePicked2Time =
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
                                              if (_datePicked2Time != null) {
                                                safeSetState(() {
                                                  _model.datePicked2 = DateTime(
                                                    getCurrentTimestamp.year,
                                                    getCurrentTimestamp.month,
                                                    getCurrentTimestamp.day,
                                                    _datePicked2Time.hour,
                                                    _datePicked2Time.minute,
                                                  );
                                                });
                                              } else if (_model.datePicked2 !=
                                                  null) {
                                                safeSetState(() {
                                                  _model.datePicked2 =
                                                      getCurrentTimestamp;
                                                });
                                              }
                                            },
                                            child: Container(
                                              height: 40.0,
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
                                              child: Align(
                                                alignment: AlignmentDirectional(
                                                    -1.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          8.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "jm",
                                                          columnVwSolicitudesServiciosCompletaRow
                                                              ?.hora?.time),
                                                      'Seleccionar',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
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
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
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
                                                      .nombreTextController6 ??=
                                                  TextEditingController(
                                                text: valueOrDefault<String>(
                                                  columnVwSolicitudesServiciosCompletaRow
                                                      ?.ubicacion,
                                                  'Sin especificar',
                                                ),
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode6,
                                              minLines: 2,
                                              maxLines: null,
                                              keyboardType: TextInputType.multiline,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController6Validator
                                                  .asValidator(context),
                                            ),
                                          ),
                                          SelectorUbicacionWidget(
                                            ciudadId: _model.ciudadNuevaValue,
                                            nombreCiudad: _model.ciudadNuevaValue == null
                                                ? columnVwSolicitudesServiciosCompletaRow?.solicitudCiudad
                                                : null,
                                            // La clave amarra el estado del
                                            // selector a ESTA solicitud: sin
                                            // ella, al abrir otra el widget se
                                            // reutiliza y conserva el punto de
                                            // la anterior.
                                            key: ValueKey(
                                                'ubicacion_${widget!.solicitudId}'),
                                            coordenadasIniciales:
                                                (columnVwSolicitudesServiciosCompletaRow
                                                                ?.latitud !=
                                                            null &&
                                                        columnVwSolicitudesServiciosCompletaRow
                                                                ?.longitud !=
                                                            null)
                                                    ? Coordenadas(
                                                        columnVwSolicitudesServiciosCompletaRow!
                                                            .latitud!,
                                                        columnVwSolicitudesServiciosCompletaRow
                                                            .longitud!)
                                                    : null,
                                            direccionActual: () =>
                                                _model.nombreTextController6
                                                    ?.text ??
                                                '',
                                            onCambio: (punto) =>
                                                _model.coordenadas = punto,
                                            onDireccionSugerida: (valor) =>
                                                safeSetState(() => _model
                                                    .nombreTextController6
                                                    ?.text = valor),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Precio base',
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
                                                      .nombreTextController7 ??=
                                                  TextEditingController(
                                                text:
                                                    columnVwSolicitudesServiciosCompletaRow
                                                        ?.precioBase
                                                        ?.toString(),
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode7,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController7Validator
                                                  .asValidator(context),
                                            ),
                                          ),
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
                                            'Proveedor',
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
                                                      .nombreTextController8 ??=
                                                  TextEditingController(
                                                // La vista ya trae el nombre;
                                                // mostrar el id de usuario no
                                                // le dice nada a nadie.
                                                text: valueOrDefault<String>(
                                                  columnVwSolicitudesServiciosCompletaRow
                                                              ?.proveedorNombreCompleto
                                                              ?.trim()
                                                              .isNotEmpty ==
                                                          true
                                                      ? columnVwSolicitudesServiciosCompletaRow
                                                          ?.proveedorNombreCompleto
                                                      : columnVwSolicitudesServiciosCompletaRow
                                                          ?.proveedorIdUsuario
                                                          ?.toString(),
                                                  'Sin asignar',
                                                ),
                                              ),
                                              focusNode:
                                                  _model.nombreFocusNode8,
                                              autofocus: false,
                                              readOnly: true,
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
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
                                                hintText: 'Nombres',
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
                                                  .nombreTextController8Validator
                                                  .asValidator(context),
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 8.0)),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 16.0, 0.0, 0.0),
                                child: _buildPreciosAdicionalesSection(context),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 20.0, 0.0, 20.0),
                                  child: Text(
                                    'Datos de proveedor',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 20.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
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
                                          'Nombre',
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
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          child: TextFormField(
                                            controller:
                                                _model.nombreTextController9 ??=
                                                    TextEditingController(
                                              text: valueOrDefault<String>(
                                                columnVwSolicitudesServiciosCompletaRow
                                                    ?.proveedorNombres,
                                                'Sin especificar',
                                              ),
                                            ),
                                            focusNode: _model.nombreFocusNode9,
                                            autofocus: false,
                                            readOnly: true,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
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
                                              hintText: 'Nombres',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            Color(0xFF8A8A8A),
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
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
                                                .nombreTextController9Validator
                                                .asValidator(context),
                                          ),
                                        ),
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
                                          'Telefono',
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
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          child: TextFormField(
                                            controller: _model
                                                    .nombreTextController10 ??=
                                                TextEditingController(
                                              text: valueOrDefault<String>(
                                                columnVwSolicitudesServiciosCompletaRow
                                                    ?.proveedorTelefono,
                                                'Sin especificar',
                                              ),
                                            ),
                                            focusNode: _model.nombreFocusNode10,
                                            autofocus: false,
                                            readOnly: true,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
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
                                              hintText: 'Nombres',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            Color(0xFF8A8A8A),
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
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
                                                .nombreTextController10Validator
                                                .asValidator(context),
                                          ),
                                        ),
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
                                          'Correo electronico',
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
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          child: TextFormField(
                                            controller: _model
                                                    .nombreTextController11 ??=
                                                TextEditingController(
                                              text: valueOrDefault<String>(
                                                columnVwSolicitudesServiciosCompletaRow
                                                    ?.proveedorCorreo,
                                                'Sin especificar',
                                              ),
                                            ),
                                            focusNode: _model.nombreFocusNode11,
                                            autofocus: false,
                                            readOnly: true,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
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
                                              hintText: 'Nombres',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
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
                                                        color:
                                                            Color(0xFF8A8A8A),
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
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
                                                .nombreTextController11Validator
                                                .asValidator(context),
                                          ),
                                        ),
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
                                          'Reasignar a:',
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
                                          future:
                                              _profesionalesActivosVerificados(
                                            _model.servicioNuevoValue ??
                                                columnVwSolicitudesServiciosCompletaRow
                                                    ?.servicioId,
                                          ),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (snapshot.hasError) {
                                              return const Text(
                                                'No se pudieron cargar los profesionales.',
                                              );
                                            }
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
                                            final profesionalNuevoVwProfesionalesCompletoRowList =
                                                porProveedor(snapshot.data!)
                                                    .toList()
                                                  ..sort((a, b) =>
                                                      (a.nombres ?? '').compareTo(
                                                          b.nombres ?? ''));

                                            return SearchableDropdown(
                                              values:
                                                  profesionalNuevoVwProfesionalesCompletoRowList
                                                      .map((p) =>
                                                          p.profesionalId ?? '')
                                                      .where((id) => id.isNotEmpty)
                                                      .toList(),
                                              labels:
                                                  profesionalNuevoVwProfesionalesCompletoRowList
                                                      .where((p) =>
                                                          (p.profesionalId ?? '')
                                                              .isNotEmpty)
                                                      .map((p) => p.nombreCompleto ??
                                                          p.nombres ?? '')
                                                      .toList(),
                                              selectedValue:
                                                  _model.profesionalNuevoValue,
                                              onChanged: (val) => safeSetState(
                                                  () => _model
                                                          .profesionalNuevoValue =
                                                      val),
                                              hint:
                                                  'Seleccionar profesional...',
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
                                    0.0, 20.0, 0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Align(
                                      alignment:
                                          AlignmentDirectional(-1.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 8.0),
                                        child: Text(
                                          'Notas adicionales',
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
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          1.0,
                                      child: TextFormField(
                                        controller:
                                            _model.nombreTextController12 ??=
                                                TextEditingController(
                                          text:
                                              columnVwSolicitudesServiciosCompletaRow
                                                  ?.informacionAdicional,
                                        ),
                                        focusNode: _model.nombreFocusNode12,
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 16.0,
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
                                          hintText: 'Informacion adicional',
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
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
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
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        validator: _model
                                            .nombreTextController12Validator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        FutureBuilder<List<CertificacionesRow>>(
                          future: CertificacionesTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'usuario_id',
                              widget!.solicitudId,
                            ),
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
                            List<CertificacionesRow>
                                containerCertificacionesRowList =
                                snapshot.data!;

                            return Container(
                              decoration: BoxDecoration(),
                            );
                          },
                        ),
                        FutureBuilder<List<ReferenciasLaboralesRow>>(
                          future: ReferenciasLaboralesTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'usuario_id',
                              widget!.solicitudId,
                            ),
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
                            List<ReferenciasLaboralesRow>
                                containerReferenciasLaboralesRowList =
                                snapshot.data!;

                            return Container(
                              decoration: BoxDecoration(),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 20.0, 0.0, 20.0),
                          child: Container(
                            decoration: BoxDecoration(),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                text: 'Cerrar',
                                options: FFButtonOptions(
                                  height: 40.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      32.0, 0.0, 32.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: Color(0xFFFBFAF9),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF606060),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: Color(0xFF8A8A8A),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  if (!(_fechaHoraKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  if (_model.profesionalNuevoValue != null &&
                                      _model.profesionalNuevoValue != '') {
                                    await SolicitudesServicioTable().update(
                                      data: {
                                        'ubicacion':
                                            _model.nombreTextController6.text,
                                        'latitud': _model.coordenadas?.latitud,
                                        'longitud':
                                            _model.coordenadas?.longitud,
                                        'fecha': supaSerialize<DateTime>(_model
                                                    .datePicked1 !=
                                                null
                                            ? _model.datePicked1
                                            : columnVwSolicitudesServiciosCompletaRow
                                                ?.fecha),
                                        'hora': supaSerialize<
                                            PostgresTime>(PostgresTime(_model
                                                    .datePicked2 !=
                                                null
                                            ? _model.datePicked2
                                            : columnVwSolicitudesServiciosCompletaRow
                                                ?.hora?.time)),
                                        'profesional_id':
                                            _model.profesionalNuevoValue,
                                        if (_model.servicioNuevoValue != null)
                                          'servicio_id':
                                              _model.servicioNuevoValue,
                                        if (_model.servicioNuevoNombre != null)
                                          'servicio_nombre':
                                              _model.servicioNuevoNombre,
                                        'precio_base': double.tryParse(
                                            _model.nombreTextController7.text),
                                        'precio_adicionales': _model
                                            .preciosAdicionalesSolicitud
                                            .fold(0.0, (s, e) => s + e.total),
                                        'informacion_adicional':
                                            _model.nombreTextController12.text,
                                        // Solo regresar a 'aceptadas' si la solicitud
                                        // aún está en 'entrantes'; no pisar estados
                                        // ya avanzados (en proceso, en camino, etc.).
                                        if (columnVwSolicitudesServiciosCompletaRow
                                                ?.estadoSolicitud ==
                                            'entrantes')
                                          'estado': 'aceptadas',
                                      },
                                      matchingRows: (rows) => rows.eqOrNull(
                                        'id',
                                        widget!.solicitudId,
                                      ),
                                    );
                                    _model.apiResult0mz =
                                        await SendNotificationUserCall.call(
                                      userIdSupabase:
                                          _model.profesionalNuevoValue,
                                      title: 'Solicitud asignada',
                                      message: 'Se ha reasignado la solicitud',
                                    );

                                    await SenNotificationUserHulpCall.call(
                                      userIdSupabase:
                                          columnVwSolicitudesServiciosCompletaRow
                                              ?.usuarioId,
                                      title: 'Re asignación de servicio',
                                      message: 'Se ha re asignado tu solicitud',
                                    );
                                  } else {
                                    await SolicitudesServicioTable().update(
                                      data: {
                                        'ubicacion':
                                            _model.nombreTextController6.text,
                                        'latitud': _model.coordenadas?.latitud,
                                        'longitud':
                                            _model.coordenadas?.longitud,
                                        'fecha': supaSerialize<DateTime>(_model
                                                    .datePicked1 !=
                                                null
                                            ? _model.datePicked1
                                            : columnVwSolicitudesServiciosCompletaRow
                                                ?.fecha),
                                        'hora': supaSerialize<
                                            PostgresTime>(PostgresTime(_model
                                                    .datePicked2 !=
                                                null
                                            ? _model.datePicked2
                                            : columnVwSolicitudesServiciosCompletaRow
                                                ?.hora?.time)),
                                        'precio_base': double.tryParse(
                                            _model.nombreTextController7.text),
                                        'precio_adicionales': _model
                                            .preciosAdicionalesSolicitud
                                            .fold(0.0, (s, e) => s + e.total),
                                        'informacion_adicional':
                                            _model.nombreTextController12.text,
                                      },
                                      matchingRows: (rows) => rows.eqOrNull(
                                        'id',
                                        widget!.solicitudId,
                                      ),
                                    );
                                  }

                                  Navigator.pop(context);

                                  safeSetState(() {});
                                },
                                text: 'Guardar',
                                options: FFButtonOptions(
                                  height: 40.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      32.0, 0.0, 32.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildPreciosAdicionalesSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios Adicionales',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                fontSize: 16.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
        SizedBox(height: 8.0),
        FFButtonWidget(
          onPressed: () async {
            await showMapSafeDialog<void>(
              context: context,
              builder: (dialogContext) {
                return Dialog(
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
                );
              },
            );
          },
          text: 'Agregar ítem',
          icon: Icon(Icons.add, size: 16.0),
          options: FFButtonOptions(
            height: 36.0,
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            color: FlutterFlowTheme.of(context).primary,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.inter(),
                  color: Colors.white,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        if (_model.preciosAdicionalesSolicitud.isNotEmpty) ...[
          SizedBox(height: 8.0),
          ...List.generate(_model.preciosAdicionalesSolicitud.length, (index) {
            final item = _model.preciosAdicionalesSolicitud[index];
            return Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      item.tipoItem ?? '',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: Colors.white,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      item.descripcion ?? '',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    '\$${functions.formatPrices(item.total)}',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: FlutterFlowTheme.of(context).error, size: 18.0),
                    onPressed: () {
                      safeSetState(() {
                        _model.removeAtIndexFromPreciosAdicionalesSolicitud(
                            index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          Divider(thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total adicionales:',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '\$${functions.formatPrices(_model.preciosAdicionalesSolicitud.fold(0.0, (s, e) => s + e.total))}',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primary,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
