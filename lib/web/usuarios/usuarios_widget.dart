import '/components/texto_tabla_completo.dart';
import '/backend/supabase/supabase.dart';
import '/backend/actualizar_cliente_solicitud.dart';
import '/components/crear_usuario_widget.dart';
import '/components/nombre_cliente_text.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';
import '/components/historial_servicios_widget.dart';
import '/components/responsive_layout_rows.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web/menu/menu_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'usuarios_model.dart';
export 'usuarios_model.dart';

class UsuariosWidget extends StatefulWidget {
  const UsuariosWidget({super.key});

  static String routeName = 'Usuarios';
  static String routePath = '/usuarios';

  @override
  State<UsuariosWidget> createState() => _UsuariosWidgetState();
}

class _UsuariosWidgetState extends State<UsuariosWidget> {
  /// Ciudades activas para el desplegable de edicion.
  List<String> _ciudades = [];

  Future<void> _cargarCiudades() async {
    try {
      final filas = await CiudadesTable().queryRows(
        queryFn: (q) =>
            q.eqOrNull('activo', true).order('nombre', ascending: true),
      );
      if (!mounted) return;
      safeSetState(() => _ciudades = filas.map((c) => c.nombre).toList());
    } catch (e) {
      print('No se pudieron cargar las ciudades: $e');
    }
  }

  /// Edita los datos de contacto y dirección del perfil, sin alterar la
  /// identidad del cliente ni ninguna de sus solicitudes.
  Future<void> _editarPerfilCliente(
      VwListaUsuariosConServiciosRow usuario) async {
    final usuarioId = usuario.id;
    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al cliente.')),
      );
      return;
    }
    final String clienteId = usuarioId;

    if (_ciudades.isEmpty) {
      await _cargarCiudades();
      if (!mounted) return;
    }

    UsuariosRow? perfil;
    try {
      final perfiles = await UsuariosTable().querySingleRow(
        queryFn: (q) => q.eqOrNull('id', clienteId),
      );
      perfil = perfiles.firstOrNull;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el perfil: $error')),
      );
      return;
    }

    final perfilCliente = perfil;
    if (!mounted) return;
    if (perfilCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente no encontrado.')),
      );
      return;
    }

    final telefonoController =
        TextEditingController(text: perfilCliente.telefono ?? '');
    final correoController =
        TextEditingController(text: perfilCliente.correoElectronico ?? '');
    final direccionController =
        TextEditingController(text: perfilCliente.direccion ?? '');
    final formKey = GlobalKey<FormState>();
    final ciudadActual = (perfilCliente.ciudad?.trim().isNotEmpty ?? false)
        ? perfilCliente.ciudad!.trim()
        : null;
    String? ciudadSeleccionada =
        _ciudades.contains(ciudadActual) ? ciudadActual : null;
    final opcionesCiudad = _ciudades.toSet().toList()
      ..sort();
    final nombre = nombreClienteDePerfil(
      perfilCliente.nombres,
      perfilCliente.apellidos,
    );
    final origen =
        perfilCliente.usuarioExterno == true ? 'Externo' : 'Aplicativo';
    String? errorFormulario;
    bool guardando = false;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, actualizarDialogo) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar perfil del cliente'),
              const SizedBox(height: 8.0),
              NombreClienteText(
                nombre: nombre,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              Text(
                'Origen: $origen',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          insetPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          content: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width < 704.0
                ? MediaQuery.sizeOf(dialogContext).width - 112.0
                : 640.0,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto',
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12.0),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final campos = [
                          TextFormField(
                            controller: telefonoController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          TextFormField(
                            controller: correoController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final correo = value?.trim() ?? '';
                              if (correo.isEmpty ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(correo)) {
                                return 'Ingresa un correo electrónico válido.';
                              }
                              return null;
                            },
                          ),
                        ];

                        if (constraints.maxWidth < 520.0) {
                          return Column(
                            children: [
                              campos[0],
                              const SizedBox(height: 12.0),
                              campos[1],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: campos[0]),
                            const SizedBox(width: 12.0),
                            Expanded(child: campos[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      'Dirección',
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      value: ciudadSeleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecciona una ciudad'),
                      items: opcionesCiudad
                          .map(
                            (ciudad) => DropdownMenuItem(
                              value: ciudad,
                              child: Text(ciudad),
                            ),
                          )
                          .toList(),
                      onChanged: guardando
                          ? null
                          : (ciudad) => actualizarDialogo(
                                () => ciudadSeleccionada = ciudad,
                              ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Selecciona una ciudad.'
                          : null,
                    ),
                    if (ciudadActual != null && ciudadSeleccionada == null) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        'La ciudad actual ya no está activa. Selecciona una ciudad activa.',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(dialogContext).error,
                        ),
                      ),
                    ],
                    if (errorFormulario != null) ...[
                      const SizedBox(height: 12.0),
                      Text(
                        errorFormulario!,
                        style: TextStyle(
                          color: FlutterFlowTheme.of(dialogContext).error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      actualizarDialogo(() {
                        guardando = true;
                        errorFormulario = null;
                      });
                      try {
                        await actualizarClienteSolicitud(
                          usuarioId: clienteId,
                          telefono: telefonoController.text.trim(),
                          correoElectronico: correoController.text.trim(),
                          direccion: direccionController.text.trim(),
                          ciudad: ciudadSeleccionada!,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(true);
                      } on ActualizarClienteSolicitudException catch (error) {
                        if (!dialogContext.mounted) return;
                        actualizarDialogo(() {
                          guardando = false;
                          errorFormulario = error.message;
                        });
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        actualizarDialogo(() {
                          guardando = false;
                          errorFormulario =
                              'No se pudieron guardar los cambios. Inténtalo de nuevo.';
                        });
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      height: 18.0,
                      width: 18.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    telefonoController.dispose();
    correoController.dispose();
    direccionController.dispose();

    if (guardado != true || !mounted) return;
    safeSetState(() => _model.requestCompleter = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil actualizado',
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryBackground,
          ),
        ),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
    );
  }

  late UsuariosModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static DateTime _epochFallback(DateTime? d) =>
      d ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Filtra por ventana de registro según el dropdown (Recientes = sin recorte).
  List<VwListaUsuariosConServiciosRow> _applyFechaRegistroFilter(
    List<VwListaUsuariosConServiciosRow> base,
  ) {
    final sel = _model.dropDownValue?.trim();
    if (sel == null || sel.isEmpty || sel == 'Recientes') {
      return base;
    }

    final now = DateTime.now();
    late final DateTime desde;
    if (sel == 'Ultimos 7 dias') {
      desde = now.subtract(const Duration(days: 7));
    } else if (sel == 'Ultimos 30 dias') {
      desde = now.subtract(const Duration(days: 30));
    } else {
      return base;
    }

    return base.where((e) {
      final d = e.fechaRegistro;
      if (d == null) return false;
      return !d.isBefore(desde);
    }).toList();
  }

  List<VwListaUsuariosConServiciosRow> _usuariosParaTabla({
    required List<VwListaUsuariosConServiciosRow> filtroBusqueda,
    required List<VwListaUsuariosConServiciosRow> todos,
  }) {
    final hayTexto = _model.textController.text.trim().isNotEmpty;
    final base = hayTexto
        ? filtroBusqueda
        : todos
            .sortedList(
              keyOf: (e) => _epochFallback(e.fechaRegistro),
              desc: true,
            )
            .toList();
    return _applyFechaRegistroFilter(base);
  }

  Widget _buildUsersFilterBar(BuildContext context, {required int total}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0x7C766C4D), width: 0.5),
      ),
      padding: EdgeInsets.all(8.0),
      child: ResponsiveProviderFilterLayout(
        breakpoint: 900.0,
        label: Text(
          'Filtrar por:',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(),
                color: Color(0xFF4A4A4A),
                fontSize: 16.0,
              ),
        ),
        filters: [
          LayoutBuilder(
            builder: (context, constraints) => FlutterFlowDropDown<String>(
              controller: _model.dropDownValueController ??=
                  FormFieldController<String>(_model.dropDownValue),
              options: [
                'Recientes',
                'Ultimos 7 dias',
                'Ultimos 30 dias',
              ],
              onChanged: (value) => safeSetState(
                () => _model.dropDownValue = value,
              ),
              width: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 200.0,
              height: 48.0,
              textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    fontSize: 16.0,
                  ),
              hintText: 'Filtrar fecha',
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 24.0,
              ),
              fillColor: Color(0xFFFBFAF9),
              elevation: 2.0,
              borderColor: Color(0xFFDFDFDF),
              borderWidth: 1.0,
              borderRadius: 8.0,
              margin: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
              hidesUnderline: true,
              isOverButton: false,
              isSearchable: false,
              isMultiSelect: false,
            ),
          ),
        ],
        summary: RichText(
          textScaler: MediaQuery.of(context).textScaler,
          text: TextSpan(
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(),
                  color: Color(0xFF0B6244),
                  fontSize: 16.0,
                ),
            children: [
              TextSpan(text: 'Total registrados: '),
              TextSpan(
                text: total.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UsuariosModel());
    _cargarCiudades();

    _model.dropDownValue ??= 'Recientes';

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textFieldFocusNode!.addListener(
      () async {
        safeSetState(() => _model.requestCompleter = null);
        await _model.waitForRequestCompleted();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchoContenido = MediaQuery.sizeOf(context).width -
        (MenuWidget.esMovil(context)
            ? 0.0
            : (FFAppState().MenuAbierto ? 280.0 : 112.0));
    final paddingHorizontal = anchoContenido < 900.0 ? 16.0 : 40.0;
    final isShortViewport = MediaQuery.sizeOf(context).height < 500.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: MenuWidget.barraMovil(context),
        drawer: MenuWidget.menuMovil(context),
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, -1.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                wrapWithModel(
                  model: _model.menuModel,
                  updateCallback: () => safeSetState(() {}),
                  child: MenuWidget(),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 72.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFEEECE8),
                          border: Border.all(
                            color: Color(0xFFD9C19C),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  paddingHorizontal, 0.0, 12.0, 0.0),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: 394.0),
                                  child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    '_model.textController',
                                    Duration(milliseconds: 2000),
                                    () async {
                                      safeSetState(
                                          () => _model.requestCompleter = null);
                                      await _model.waitForRequestCompleted();
                                    },
                                  ),
                                  autofocus: false,
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
                                          fontSize: 14.0,
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
                                    hintText: 'Buscar usuario',
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
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
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
                                        color: Color(0xFF8A8A8A),
                                        width: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
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
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                  ),
                                ),
                              ),
                            ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, paddingHorizontal, 12.0),
                              child: Icon(
                                Icons.notifications_none,
                                color: FlutterFlowTheme.of(context).accent3,
                                size: 24.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child:
                            FutureBuilder<List<VwListaUsuariosConServiciosRow>>(
                          future: (_model.requestCompleter ??= Completer<
                                  List<VwListaUsuariosConServiciosRow>>()
                                ..complete(VwListaUsuariosConServiciosTable()
                                    .queryRows(
                                  queryFn: (q) => q
                                      .eqOrNull(
                                        'rol',
                                        'usuario',
                                      )
                                      .ilike(
                                        'nombres',
                                        '%${_model.textController.text}%',
                                      ),
                                )))
                              .future,
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
                            List<VwListaUsuariosConServiciosRow>
                                containerfiltroVwListaUsuariosConServiciosRowList =
                                snapshot.data!;

                            return Container(
                              decoration: BoxDecoration(),
                              child: FutureBuilder<
                                  List<VwListaUsuariosConServiciosRow>>(
                                future: VwListaUsuariosConServiciosTable()
                                    .queryRows(
                                  queryFn: (q) => q.eqOrNull(
                                    'rol',
                                    'usuario',
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  List<VwListaUsuariosConServiciosRow>
                                      containerVwListaUsuariosConServiciosRowList =
                                      snapshot.data!;

                                  return Container(
                                    decoration: BoxDecoration(),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          paddingHorizontal,
                                          isShortViewport ? 8.0 : 24.0,
                                          paddingHorizontal,
                                          0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      context.goNamed(
                                                        DashboardWidget
                                                            .routeName,
                                                        extra: <String,
                                                            dynamic>{
                                                          '__transition_info__':
                                                              TransitionInfo(
                                                            hasTransition: true,
                                                            transitionType:
                                                                PageTransitionType
                                                                    .fade,
                                                            duration: Duration(
                                                                milliseconds:
                                                                    0),
                                                          ),
                                                        },
                                                      );
                                                    },
                                                    child: Text(
                                                      'Inicio',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                            color: Color(
                                                                0xFF5E252B),
                                                            fontSize: 16.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 0.0,
                                                                4.0, 0.0),
                                                    child: Icon(
                                                      Icons.chevron_right,
                                                      color: Color(0xFF5E252B),
                                                      size: 24.0,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      context.pushNamed(
                                                        UsuariosWidget
                                                            .routeName,
                                                        extra: <String,
                                                            dynamic>{
                                                          '__transition_info__':
                                                              TransitionInfo(
                                                            hasTransition: true,
                                                            transitionType:
                                                                PageTransitionType
                                                                    .fade,
                                                            duration: Duration(
                                                                milliseconds:
                                                                    0),
                                                          ),
                                                        },
                                                      );
                                                    },
                                                    child: Text(
                                                      'Usuarios',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                            color: Color(
                                                                0xFF5E252B),
                                                            fontSize: 16.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0,
                                                    isShortViewport ? 8.0 : 16.0,
                                                    0.0,
                                                    0.0),
                                            child: ResponsiveSpaceBetween(
                                              breakpoint: 900.0,
                                              runSpacing:
                                                  isShortViewport ? 6.0 : 12.0,
                                              leading: Text(
                                                  'Usuarios',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        fontSize: 28.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                                trailing: Builder(
                                                  builder: (context) =>
                                                      FFButtonWidget(
                                                    onPressed: () async {
                                                      await showDialog(
                                                        context: context,
                                                        builder:
                                                            (dialogContext) {
                                                          return Dialog(
                                                            elevation: 0,
                                                            insetPadding:
                                                                EdgeInsets.all(16.0),
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            alignment: AlignmentDirectional(
                                                                    0.0, 0.0)
                                                                .resolve(
                                                                    Directionality.of(
                                                                        context)),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                FocusScope.of(
                                                                        dialogContext)
                                                                    .unfocus();
                                                                FocusManager
                                                                    .instance
                                                                    .primaryFocus
                                                                    ?.unfocus();
                                                              },
                                                              child:
                                                                  CrearUsuarioWidget(),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    text: '+ Nuevo usuario',
                                                    options: FFButtonOptions(
                                                      height: 40.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  0.0,
                                                                  16.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .interTight(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                              ),
                                                      elevation: 0.0,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                0.0,
                                                isShortViewport ? 8.0 : 24.0,
                                                0.0,
                                                0.0),
                                            child: _buildUsersFilterBar(
                                              context,
                                              total: _usuariosParaTabla(
                                                filtroBusqueda:
                                                    containerfiltroVwListaUsuariosConServiciosRowList,
                                                todos:
                                                    containerVwListaUsuariosConServiciosRowList,
                                              ).length,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0,
                                                      isShortViewport ? 8.0 : 20.0,
                                                      0.0,
                                                      isShortViewport ? 8.0 : 16.0),
                                              child: Container(
                                                decoration: BoxDecoration(),
                                                child: Container(
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(),
                                                  child: Builder(
                                                    builder: (context) {
                                                      final users =
                                                          _usuariosParaTabla(
                                                        filtroBusqueda:
                                                            containerfiltroVwListaUsuariosConServiciosRowList,
                                                        todos:
                                                            containerVwListaUsuariosConServiciosRowList,
                                                      );

                                                      return FlutterFlowDataTable<
                                                          VwListaUsuariosConServiciosRow>(
                                                        controller: _model
                                                            .paginatedDataTableController,
                                                        data: users,
                                                        columnsBuilder:
                                                            (onSortChanged) => [
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Fecha y hora registro',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Nombre',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Correo',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Celular',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Tipo documento',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Número ID',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Historial',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Origen',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          DataColumn2(
                                                            label:
                                                                DefaultTextStyle
                                                                    .merge(
                                                              softWrap: true,
                                                              child: Text(
                                                                'Editar perfil',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        dataRowBuilder: (usersItem,
                                                                usersIndex,
                                                                selected,
                                                                onSelectChanged) =>
                                                            DataRow(
                                                          color:
                                                              MaterialStateProperty
                                                                  .all(
                                                            usersIndex % 2 == 0
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground
                                                                : FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                          ),
                                                          cells: [
                                                            TextoTablaCompleto(
                                                              '${dateTimeFormat("d/M/y", usersItem.fechaRegistro)} - ${dateTimeFormat("Hm", usersItem.fechaRegistro)}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            NombreClienteText(
                                                              nombre: nombreClienteDePerfil(
                                                                usersItem.nombres,
                                                                usersItem.apellidos,
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    color: Color(
                                                                        0xFF4A4A4A),
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            TextoTablaCompleto(
                                                              valueOrDefault<
                                                                  String>(
                                                                usersItem
                                                                    .correoElectronico,
                                                                'Sin correo',
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    color: Color(
                                                                        0xFF4A4A4A),
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            TextoTablaCompleto(
                                                              valueOrDefault<
                                                                  String>(
                                                                '${usersItem.codigoPais} ${usersItem.telefono}',
                                                                'Sin teléfono',
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            TextoTablaCompleto(
                                                              valueOrDefault<
                                                                  String>(
                                                                usersItem
                                                                    .tipoDocumento,
                                                                'Sin documento',
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            TextoTablaCompleto(
                                                              valueOrDefault<
                                                                  String>(
                                                                usersItem
                                                                    .numeroDocumento,
                                                                'Sin número',
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            Builder(
                                                              builder:
                                                                  (context) =>
                                                                      InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (dialogContext) {
                                                                      return Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.all(16.0),
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              HistorialServiciosWidget(
                                                                            userId:
                                                                                usersItem.id!,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                child: TextoTablaCompleto(
                                                                  '${usersItem.totalServiciosFinalizados?.toString()} de ${usersItem.totalServicios?.toString()}',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                        decoration:
                                                                            TextDecoration.underline,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            FutureBuilder<
                                                                List<
                                                                    UsuariosRow>>(
                                                              future: UsuariosTable()
                                                                  .querySingleRow(
                                                                queryFn: (q) =>
                                                                    q.eqOrNull(
                                                                  'id',
                                                                  usersItem.id,
                                                                ),
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                // Customize what your widget looks like when it's loading.
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          50.0,
                                                                      height:
                                                                          50.0,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<Color>(
                                                                          FlutterFlowTheme.of(context)
                                                                              .primary,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                List<UsuariosRow>
                                                                    textUsuariosRowList =
                                                                    snapshot
                                                                        .data!;

                                                                final textUsuariosRow =
                                                                    textUsuariosRowList
                                                                            .isNotEmpty
                                                                        ? textUsuariosRowList
                                                                            .first
                                                                        : null;

                                                                return TextoTablaCompleto(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    textUsuariosRow?.usuarioExterno !=
                                                                            true
                                                                        ? 'Aplicativo'
                                                                        : 'Externo',
                                                                    'Aplicativo',
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .inter(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                );
                                                              },
                                                            ),
                                                            // El perfil se actualiza mediante la Edge Function;
                                                            // la tabla nunca modifica datos de Auth directamente.
                                                            Tooltip(
                                                              message: 'Editar perfil',
                                                              child: FlutterFlowIconButton(
                                                                borderRadius: 10.0,
                                                                buttonSize: 34.0,
                                                                fillColor: FlutterFlowTheme.of(context).warning,
                                                                icon: Icon(Icons.edit,
                                                                    color: FlutterFlowTheme.of(context).info,
                                                                    size: 18.0),
                                                                onPressed: () => _editarPerfilCliente(usersItem),
                                                              ),
                                                            ),
                                                          ]
                                                              .map((c) =>
                                                                  DataCell(c))
                                                              .toList(),
                                                        ),
                                                        paginated: true,
                                                        selectable: false,
                                                        hidePaginator: false,
                                                        showFirstLastButtons:
                                                            false,
                                                        minWidth: 1450.0,
                                                        width:
                                                            double.infinity,
                                                        height:
                                                            double.infinity,
                                                        headingRowHeight: 56.0,
                                                        dataRowHeight: 48.0,
                                                        columnSpacing: 20.0,
                                                        headingRowColor:
                                                            Color(0xFFFBFAF9),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        addHorizontalDivider:
                                                            false,
                                                        addTopAndBottomDivider:
                                                            false,
                                                        hideDefaultHorizontalDivider:
                                                            true,
                                                        addVerticalDivider:
                                                            false,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
