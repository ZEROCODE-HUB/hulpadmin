import '/components/texto_tabla_completo.dart';
import '/backend/supabase/profesionales_query.dart';
import '/backend/supabase/supabase.dart';
import '/components/aceptar_proveedor_widget.dart';
import '/components/crear_proveedor_widget.dart';
import '/components/dropdown_proveedor_estado_widget.dart';
import '/components/informacion_proveedor_widget.dart';
import '/components/rechazar_proveedor_widget.dart';
import '/components/responsive_layout_rows.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web/menu/menu_widget.dart';
import '/web/shared/admin_loading_skeleton.dart';
import '/web/shared/admin_page_spacing.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'registro_proveedores_model.dart';
export 'registro_proveedores_model.dart';

class RegistroProveedoresWidget extends StatefulWidget {
  const RegistroProveedoresWidget({super.key});

  static String routeName = 'RegistroProveedores';
  static String routePath = '/registroProveedores';

  @override
  State<RegistroProveedoresWidget> createState() =>
      _RegistroProveedoresWidgetState();
}

class _RegistroProveedoresWidgetState extends State<RegistroProveedoresWidget> {
  late RegistroProveedoresModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegistroProveedoresModel());

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

  Widget _buildLoadingHeaderBar(BuildContext context) => AdminPageHeaderBar(
        routeTitle: 'Registro talento Hulp',
        searchHint: 'Buscar proveedor',
        controller: _model.textController,
        focusNode: _model.textFieldFocusNode,
        trailingPadding: AdminPageSpacing.headerHorizontal(context),
        onChanged: (_) => EasyDebounce.debounce(
          '_model.textController',
          const Duration(milliseconds: 2000),
          () async {
            safeSetState(() => _model.requestCompleter = null);
            await _model.waitForRequestCompleted();
          },
        ),
        onFieldSubmitted: (_) async {
          safeSetState(() => _model.requestCompleter = null);
          await _model.waitForRequestCompleted();
        },
      );

  void _seleccionarFiltroVerificado(String estado) {
    if (_model.filtroVerificado == estado) return;
    safeSetState(() {
      _model.filtroVerificado = estado;
      _model.dropDownValueController?.reset();
      _model.dropDownValue = null;
      _model.ciudadDropdownValueController?.reset();
      _model.ciudadDropdownValue = null;
      _model.invalidarConsultas();
    });
  }

  Widget _buildEstadoFilterCounter({
    required String label,
    required String estado,
    required Color color,
  }) {
    final seleccionado = _model.filtroVerificado == estado;
    final conteo = _model.conteosPorVerificacion.putIfAbsent(
      estado,
      () => contarProveedores(verificado: estado),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: () => _seleccionarFiltroVerificado(estado),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFF0F5F3) : Colors.transparent,
          border: Border.all(
            color: seleccionado ? color : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label:',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    fontSize: 16.0,
                    color: color,
                  ),
            ),
            FutureBuilder<int>(
              future: conteo,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const AdminSkeletonBlock(width: 32, height: 18);
                }
                return Text(
                  snapshot.data.toString(),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: color,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                      ),
                );
              },
            ),
          ].divide(const SizedBox(width: 8.0)),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return ResponsiveToolbarRow(
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
        context.pushNamed(
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
        color: Color(0xFF606060),
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
          RegistroProveedoresWidget
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
        'Registro talento Hulp',
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
);
  }


  @override
  Widget build(BuildContext context) {
    final pageHorizontal = AdminPageSpacing.contentHorizontal(context);
    final headerHorizontal = AdminPageSpacing.headerHorizontal(context);
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
                  child: FutureBuilder<List<VwProfesionalesCompletoRow>>(
                    future: _model.listaCompletaRequest ??=
                        consultarProfesionales(
                          verificado: _model.filtroVerificado,
                        ),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return AdminPageLoadingSkeleton(
                          topBar: _buildLoadingHeaderBar(context),
                          filterCount: 2,
                          summaryCount: 3,
                          columnCount: 6,
                          rowCount: 5,
                        );
                      }
                      List<VwProfesionalesCompletoRow>
                          containersinfiltroVwProfesionalesCompletoRowList =
                          snapshot.data!;

                      return Container(
                        decoration: BoxDecoration(),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (MenuWidget.breadcrumbEnBarraSuperior(context)) ...[
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 24.0),
                                      child: _buildBreadcrumb(context),
                                    ),
                                  ],
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        headerHorizontal,
                                        0.0,
                                        12.0,
                                        0.0,
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: AdminHeaderSearchWidth(
                                          child: TextFormField(
                                            controller: _model.textController,
                                            focusNode:
                                                _model.textFieldFocusNode,
                                            onChanged: (_) =>
                                                EasyDebounce.debounce(
                                              '_model.textController',
                                              Duration(milliseconds: 2000),
                                              () async {
                                                safeSetState(() => _model
                                                    .requestCompleter = null);
                                                await _model
                                                    .waitForRequestCompleted();
                                              },
                                            ),
                                            onFieldSubmitted: (_) async {
                                              safeSetState(() => _model
                                                  .requestCompleter = null);
                                              await _model
                                                  .waitForRequestCompleted();
                                            },
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: decorarInputHulp(context, InputDecoration(
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
                                                        fontSize: 14.0,
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
                                              hintText: 'Buscar proveedor',
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
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
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
                                                  color: Color(0xFF8A8A8A),
                                                  width: 0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
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
                                              fillColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            )),
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
                                                .textControllerValidator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0,
                                        12.0,
                                        headerHorizontal,
                                        12.0),
                                    child: Icon(
                                      Icons.notifications_none,
                                      color:
                                          FlutterFlowTheme.of(context).accent3,
                                      size: 24.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: FutureBuilder<
                                  List<VwProfesionalesCompletoRow>>(
                                future: (_model.requestCompleter ??= Completer<
                                        List<VwProfesionalesCompletoRow>>()
                                      ..complete(consultarProfesionales(
                                        verificado: _model.filtroVerificado,
                                        busqueda: _model.textController.text,
                                      )))
                                    .future,
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return AdminPageLoadingSkeleton(
                                      filterCount: 2,
                                      columnCount: 6,
                                      rowCount: 5,
                                    );
                                  }
                                  List<VwProfesionalesCompletoRow>
                                      containerfiltroVwProfesionalesCompletoRowList =
                                      snapshot.data!;

                                  return Container(
                                    decoration: BoxDecoration(),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        pageHorizontal,
                                        16.0,
                                        pageHorizontal,
                                        0.0,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (!MenuWidget.breadcrumbEnBarraSuperior(context)) _buildBreadcrumb(context),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 16.0, 0.0, 0.0),
                                            child: ResponsiveSpaceBetween(
                                              leading: Text(
                                                'Registro talento Hulp',
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
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (dialogContext) {
                                                        return Dialog(
                                                          elevation: 0,
                                                          insetPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16.0,
                                                                  vertical:
                                                                      16.0),
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
                                                                CrearProveedorWidget(),
                                                          ),
                                                        );
                                                      },
                                                    );
// La lista se arma con consultas puntuales, no con un stream en vivo:
// hay que volver a pedirla despues de crear, aceptar o rechazar.
                                                    safeSetState(() => _model
                                                        .invalidarConsultas());
                                                  },
                                                  text: 'Agregar proveedor',
                                                  icon: Icon(
                                                    Icons.add,
                                                    size: 15.0,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: 200.0,
                                                    height: 48.0,
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .interTight(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
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
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 24.0, 0.0, 0.0),
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                                border: Border.all(
                                                  color: Color(0x7C766C4D),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 6.0, 0.0, 6.0),
                                                child:
                                                    ResponsiveProviderFilterLayout(
                                                  label: Text(
                                                    'Filtrar por:',
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
                                                          color:
                                                              Color(0xFF4A4A4A),
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
                                                  ),
                                                  filters: [
                                                    ResponsiveFilterField(
                                                      selector:
                                                          FlutterFlowDropDown<
                                                              String>(
                                                        controller: _model
                                                                .dropDownValueController ??=
                                                            FormFieldController<
                                                                String>(null),
                                                        options: _model.textController
                                                                        .text !=
                                                                    null &&
                                                                _model.textController
                                                                        .text !=
                                                                    ''
                                                            ? containerfiltroVwProfesionalesCompletoRowList
                                                                .unique((e) =>
                                                                    e.categoriaNombre ??
                                                                    '')
                                                                .map((e) => e
                                                                    .categoriaNombre)
                                                                .withoutNulls
                                                                .toList()
                                                            : containersinfiltroVwProfesionalesCompletoRowList
                                                                .unique((e) =>
                                                                    e.categoriaNombre ??
                                                                    '')
                                                                .map((e) => e
                                                                    .categoriaNombre)
                                                                .withoutNulls
                                                                .toList(),
                                                        onChanged: (val) =>
                                                            safeSetState(() =>
                                                                _model.dropDownValue =
                                                                    val),
                                                        width: 200.0,
                                                        height: 48.0,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                                  fontSize:
                                                                      16.0,
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
                                                        hintText: 'Categorias',
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          size: 24.0,
                                                        ),
                                                        fillColor:
                                                            Color(0xFFFBFAF9),
                                                        elevation: 2.0,
                                                        borderColor:
                                                            Color(0xFFDFDFDF),
                                                        borderWidth: 1.0,
                                                        borderRadius: 8.0,
                                                        margin:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    0.0,
                                                                    12.0,
                                                                    0.0),
                                                        hidesUnderline: true,
                                                        isOverButton: false,
                                                        isSearchable: false,
                                                        isMultiSelect: false,
                                                      ),
                                                      clearAction:
                                                          _model.dropDownValue !=
                                                                      null &&
                                                                  _model.dropDownValue !=
                                                                      ''
                                                              ? Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          4.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child:
                                                                      InkWell(
                                                                    splashColor:
                                                                        Colors
                                                                            .transparent,
                                                                    focusColor:
                                                                        Colors
                                                                            .transparent,
                                                                    hoverColor:
                                                                        Colors
                                                                            .transparent,
                                                                    highlightColor:
                                                                        Colors
                                                                            .transparent,
                                                                    onTap:
                                                                        () async {
                                                                      safeSetState(
                                                                          () {
                                                                        _model
                                                                            .dropDownValueController
                                                                            ?.reset();
                                                                        _model.dropDownValue =
                                                                            null;
                                                                      });
                                                                    },
                                                                    child: Icon(
                                                                      Icons
                                                                          .close,
                                                                      color: Color(
                                                                          0xFFE20E0E),
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                  ),
                                                                )
                                                              : null,
                                                    ),
                                                    ResponsiveFilterField(
                                                      selector:
                                                          FlutterFlowDropDown<
                                                              String>(
                                                        controller: _model
                                                                .ciudadDropdownValueController ??=
                                                            FormFieldController<
                                                                String>(null),
                                                        options: _model.textController
                                                                        .text !=
                                                                    null &&
                                                                _model.textController
                                                                        .text !=
                                                                    ''
                                                            ? containerfiltroVwProfesionalesCompletoRowList
                                                                .map((e) =>
                                                                    e.ciudad)
                                                                .whereType<
                                                                    String>()
                                                                .where((e) => e
                                                                    .isNotEmpty)
                                                                .toSet()
                                                                .toList()
                                                            : containersinfiltroVwProfesionalesCompletoRowList
                                                                .map((e) =>
                                                                    e.ciudad)
                                                                .whereType<
                                                                    String>()
                                                                .where((e) => e
                                                                    .isNotEmpty)
                                                                .toSet()
                                                                .toList(),
                                                        onChanged: (val) =>
                                                            safeSetState(() =>
                                                                _model.ciudadDropdownValue =
                                                                    val),
                                                        width: 180.0,
                                                        height: 48.0,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium,
                                                        hintText: 'Ciudades',
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          size: 24.0,
                                                        ),
                                                        fillColor:
                                                            Color(0xFFFBFAF9),
                                                        elevation: 2.0,
                                                        borderColor:
                                                            Color(0xFFDFDFDF),
                                                        borderWidth: 1.0,
                                                        borderRadius: 8.0,
                                                        margin:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    0.0,
                                                                    12.0,
                                                                    0.0),
                                                        hidesUnderline: true,
                                                        isOverButton: false,
                                                        isSearchable: false,
                                                        isMultiSelect: false,
                                                      ),
                                                      clearAction: _model
                                                                      .ciudadDropdownValue !=
                                                                  null &&
                                                              _model.ciudadDropdownValue !=
                                                                  ''
                                                          ? Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          4.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: InkWell(
                                                                onTap:
                                                                    () async {
                                                                  safeSetState(
                                                                      () {
                                                                    _model
                                                                        .ciudadDropdownValueController
                                                                        ?.reset();
                                                                    _model.ciudadDropdownValue =
                                                                        null;
                                                                  });
                                                                },
                                                                child: Icon(
                                                                  Icons.close,
                                                                  color: Color(
                                                                      0xFFE20E0E),
                                                                  size: 24.0,
                                                                ),
                                                              ))
                                                          : null,
                                                    ),
                                                  ],
                                                  summary: ResponsiveToolbarRow(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    wrapAlignment:
                                                        WrapAlignment.center,
                                                    spacing: 8.0,
                                                    runSpacing: 8.0,
                                                    children: [
                                                      _buildEstadoFilterCounter(
                                                        label: 'Pendientes',
                                                        estado: 'pendiente',
                                                        color: const Color(
                                                          0xFF0D70E7,
                                                        ),
                                                      ),
                                                      _buildEstadoFilterCounter(
                                                        label: 'Docs. faltantes',
                                                        estado: 'sin documentos',
                                                        color: const Color(
                                                          0xFF6C757D,
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
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
                                                            onTap: () async {
                                                              context.pushNamed(
                                                                SolicitudesRechazadasWidget
                                                                    .routeName,
                                                                extra: <String,
                                                                    dynamic>{
                                                                  '__transition_info__':
                                                                      TransitionInfo(
                                                                    hasTransition:
                                                                        true,
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
                                                              'Rechazadas:',
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
                                                                    color: Color(
                                                                        0xFF0D70E7),
                                                                    fontSize:
                                                                        16.0,
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
                                                                    decoration:
                                                                        TextDecoration
                                                                            .underline,
                                                                  ),
                                                            ),
                                                          ),
                                                          FutureBuilder<int>(
                                                            future:
                                                                contarProveedores(
                                                              verificado:
                                                                  'no verificado',
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return const AdminSkeletonBlock(
                                                                  width: 32,
                                                                  height: 18,
                                                                );
                                                              }
                                                              final int
                                                                  cantidadProveedores =
                                                                  snapshot
                                                                      .data!;

                                                              return Text(
                                                                valueOrDefault<
                                                                    String>(
                                                                  cantidadProveedores
                                                                      .toString(),
                                                                  '0',
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      fontSize:
                                                                          20.0,
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
                                                              );
                                                            },
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Total:',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                                  fontSize:
                                                                      16.0,
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
                                                          FutureBuilder<int>(
                                                            future:
                                                                contarProveedores(),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return const AdminSkeletonBlock(
                                                                  width: 32,
                                                                  height: 18,
                                                                );
                                                              }
                                                              final int
                                                                  cantidadProveedores =
                                                                  snapshot
                                                                      .data!;

                                                              return Text(
                                                                valueOrDefault<
                                                                    String>(
                                                                  cantidadProveedores
                                                                      .toString(),
                                                                  '0',
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      fontSize:
                                                                          20.0,
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
                                                              );
                                                            },
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 16.0)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 16.0, 0.0, 8.0),
                                                child: Builder(
                                                  builder: (context) {
                                                    final hayBusqueda = _model
                                                        .textController
                                                        .text
                                                        .isNotEmpty;
                                                    final filasBase = hayBusqueda
                                                        ? containerfiltroVwProfesionalesCompletoRowList
                                                        : containersinfiltroVwProfesionalesCompletoRowList;
                                                    final proveedoresDatos = filasBase
                                                        .where((e) =>
                                                            (_model.dropDownValue ==
                                                                    null ||
                                                                _model.dropDownValue ==
                                                                    '' ||
                                                                e.categoriaNombre ==
                                                                    _model
                                                                        .dropDownValue) &&
                                                            (_model.ciudadDropdownValue ==
                                                                    null ||
                                                                _model.ciudadDropdownValue ==
                                                                    '' ||
                                                                e.ciudad ==
                                                                    _model
                                                                        .ciudadDropdownValue))
                                                        .toList()
                                                        .unique((e) =>
                                                            e.profesionalId ??
                                                            '')
                                                        .toList();

                                                    return FlutterFlowDataTable<
                                                        VwProfesionalesCompletoRow>(
                                                      controller: _model
                                                          .paginatedDataTableController,
                                                      data: proveedoresDatos,
                                                      columnsBuilder:
                                                          (onSortChanged) => [
                                                        DataColumn2(
                                                          label:
                                                              DefaultTextStyle
                                                                  .merge(
                                                            softWrap: true,
                                                            child: Text(
                                                              'Fecha',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                              'Categoria',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                          label: Text(
                                                            'Ciudad',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .inter(),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      16.0,
                                                                ),
                                                          ),
                                                        ),
                                                        DataColumn2(
                                                          label:
                                                              DefaultTextStyle
                                                                  .merge(
                                                            softWrap: true,
                                                            child: Text(
                                                              'Fecha de creación',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                          fixedWidth: 190.0,
                                                        ),
                                                        DataColumn2(
                                                          label:
                                                              DefaultTextStyle
                                                                  .merge(
                                                            softWrap: true,
                                                            child: Text(
                                                              'Estado',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                          fixedWidth: 180.0,
                                                        ),
                                                        DataColumn2(
                                                          label:
                                                              DefaultTextStyle
                                                                  .merge(
                                                            softWrap: true,
                                                            child: Text(
                                                              'Acciones',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
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
                                                      dataRowBuilder:
                                                          (proveedoresDatosItem,
                                                                  proveedoresDatosIndex,
                                                                  selected,
                                                                  onSelectChanged) =>
                                                              DataRow(
                                                        color:
                                                            MaterialStateProperty
                                                                .all(
                                                          proveedoresDatosIndex %
                                                                      2 ==
                                                                  0
                                                              ? FlutterFlowTheme
                                                                      .of(
                                                                          context)
                                                                  .secondaryBackground
                                                              : FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                        ),
                                                        cells: [
                                                          TextoTablaCompleto(
                                                            valueOrDefault<
                                                                String>(
                                                              dateTimeFormat(
                                                                  "d/M/y",
                                                                  proveedoresDatosItem
                                                                      .ultimoAcceso),
                                                              'Sin fecha',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                              proveedoresDatosItem
                                                                  .nombreCompleto,
                                                              'Sin correo',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                              proveedoresDatosItem
                                                                  .categoriaNombre,
                                                              'Sin categoría',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                              proveedoresDatosItem
                                                                  .ciudad,
                                                              'Sin ciudad',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .inter(),
                                                                  fontSize:
                                                                      16.0,
                                                                ),
                                                          ),
                                                          TextoTablaCompleto(
                                                            valueOrDefault<
                                                                String>(
                                                              dateTimeFormat(
                                                                  "d/M/y",
                                                                  proveedoresDatosItem
                                                                      .fechaRegistro),
                                                              'Sin fecha',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
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
                                                          wrapWithModel(
                                                            model: _model
                                                                .dropdownProveedorEstadoModels
                                                                .getModel(
                                                              proveedoresDatosIndex
                                                                  .toString(),
                                                              proveedoresDatosIndex,
                                                            ),
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                DropdownProveedorEstadoWidget(
                                                              key: Key(
                                                                'Keykdq_${proveedoresDatosIndex.toString()}',
                                                              ),
                                                              estadoActual:
                                                                  valueOrDefault<
                                                                      String>(
                                                                proveedoresDatosItem
                                                                    .verificado,
                                                                'pendiente',
                                                              ),
                                                              index:
                                                                  proveedoresDatosIndex,
                                                              proveedorId:
                                                                  proveedoresDatosItem
                                                                          .profesionalId ??
                                                                      '',
                                                              actionnavegacion:
                                                                  () async {
                                                                if (Navigator.of(
                                                                        context)
                                                                    .canPop()) {
                                                                  context.pop();
                                                                }
                                                                context
                                                                    .pushNamed(
                                                                  RegistroProveedoresWidget
                                                                      .routeName,
                                                                  extra: <String,
                                                                      dynamic>{
                                                                    '__transition_info__':
                                                                        TransitionInfo(
                                                                      hasTransition:
                                                                          true,
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
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Builder(
                                                                builder:
                                                                    (context) =>
                                                                        FlutterFlowIconButton(
                                                                  borderRadius:
                                                                      10.0,
                                                                  buttonSize:
                                                                      35.0,
                                                                  fillColor: Color(
                                                                      0xFFB81C2C),
                                                                  icon: Icon(
                                                                    Icons.close,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .info,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (dialogContext) {
                                                                        return Dialog(
                                                                          elevation:
                                                                              0,
                                                                          insetPadding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 16.0,
                                                                              vertical: 16.0),
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
                                                                                RechazarProveedorWidget(
                                                                              proveedorId: proveedoresDatosItem.profesionalId ?? '',
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
// La lista se arma con consultas puntuales, no con un stream en vivo:
// hay que volver a pedirla despues de crear, aceptar o rechazar.
                                                                    safeSetState(
                                                                        () => _model
                                                                            .invalidarConsultas());
                                                                  },
                                                                ),
                                                              ),
                                                              Builder(
                                                                builder:
                                                                    (context) =>
                                                                        FlutterFlowIconButton(
                                                                  borderRadius:
                                                                      10.0,
                                                                  buttonSize:
                                                                      34.0,
                                                                  fillColor: Color(
                                                                      0xFF18AC4C),
                                                                  icon: Icon(
                                                                    Icons
                                                                        .check_sharp,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .info,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (dialogContext) {
                                                                        return Dialog(
                                                                          elevation:
                                                                              0,
                                                                          insetPadding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 16.0,
                                                                              vertical: 16.0),
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
                                                                                AceptarProveedorWidget(
                                                                              idproveedor: proveedoresDatosItem.profesionalId ?? '',
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
// La lista se arma con consultas puntuales, no con un stream en vivo:
// hay que volver a pedirla despues de crear, aceptar o rechazar.
                                                                    safeSetState(
                                                                        () => _model
                                                                            .invalidarConsultas());
                                                                  },
                                                                ),
                                                              ),
                                                              Builder(
                                                                builder:
                                                                    (context) =>
                                                                        FlutterFlowIconButton(
                                                                  borderRadius:
                                                                      10.0,
                                                                  buttonSize:
                                                                      34.0,
                                                                  fillColor: Color(
                                                                      0xFF606060),
                                                                  icon: Icon(
                                                                    Icons
                                                                        .search_rounded,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .info,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (dialogContext) {
                                                                        return Dialog(
                                                                          elevation:
                                                                              0,
                                                                          insetPadding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 16.0,
                                                                              vertical: 16.0),
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
                                                                                InformacionProveedorWidget(
                                                                              proveedorId: proveedoresDatosItem.profesionalId ?? '',
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
// La lista se arma con consultas puntuales, no con un stream en vivo:
// hay que volver a pedirla despues de crear, aceptar o rechazar.
                                                                    safeSetState(
                                                                        () => _model
                                                                            .invalidarConsultas());
                                                                  },
                                                                ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                width: 8.0)),
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
                                                      width: double.infinity,
                                                      minWidth: 1120.0,
                                                      height: MediaQuery.sizeOf(
                                                                  context)
                                                              .height *
                                                          1.0,
                                                      headingRowHeight: 56.0,
                                                      dataRowHeight: 56.0,
                                                      columnSpacing: 20.0,
                                                      headingRowColor:
                                                          Color(0xFFFBFAF9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      addHorizontalDivider:
                                                          false,
                                                      addTopAndBottomDivider:
                                                          false,
                                                      hideDefaultHorizontalDivider:
                                                          true,
                                                      addVerticalDivider: false,
                                                    );
                                                  },
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
                            ),
                          ],
                        ),
                      );
                    },
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
