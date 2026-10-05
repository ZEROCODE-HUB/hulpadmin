import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/web/menu_seleccion/menu_seleccion_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'menu_model.dart';
export 'menu_model.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  late MenuModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      width: valueOrDefault<double>(
        FFAppState().MenuAbierto ? 280.0 : 112.0,
        280.0,
      ),
      height: MediaQuery.sizeOf(context).height * 1.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary,
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://zexegravzidwloxeimxx.supabase.co/storage/v1/object/public/fotoservocops/servicios/Logo-3.png',
                          width: valueOrDefault<double>(
                            FFAppState().MenuAbierto ? 82.0 : 60.0,
                            60.0,
                          ),
                          height: valueOrDefault<double>(
                            FFAppState().MenuAbierto ? 42.0 : 28.0,
                            28.0,
                          ),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                        if (!FFAppState().MenuAbierto)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 0.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                FFAppState().MenuAbierto = true;
                                safeSetState(() {});
                              },
                              child: Icon(
                                Icons.chevron_right,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                size: 24.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (FFAppState().MenuAbierto)
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          FFAppState().MenuAbierto = false;
                          safeSetState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          size: 24.0,
                        ),
                      ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40.0,
                          height: 40.0,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.network(
                            valueOrDefault<String>(
                              FFAppState().user.fotoUrl,
                              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (FFAppState().MenuAbierto)
                          Text(
                            FFAppState().user.nombres.maybeHandleOverflow(
                                  maxChars: 13,
                                  replacement: '…',
                                ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                      ].divide(SizedBox(width: 12.0)),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        wrapWithModel(
                          model: _model.menuSeleccionModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Panel de control',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/j0eja7e3h9q3/Dashboard.png',
                            action: () async {
                              context.pushNamed(
                                DashboardWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Solicitudes',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/tnechqj7p09z/mark_email_unread.png',
                            action: () async {
                              context.pushNamed(
                                SolicitudesWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Soporte',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/dl7p2acq358w/support_agent.png',
                            action: () async {
                              context.pushNamed(
                                SoporteWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Registro Proveedores',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/to1bcnobshpm/talento_hulp.png',
                            action: () async {
                              if (Navigator.of(context).canPop()) {
                                context.pop();
                              }
                              context.pushNamed(
                                RegistroProveedoresWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel5,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Categorías',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/jl14vgg1blbo/category.png',
                            action: () async {
                              context.pushNamed(
                                CategoriasWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel9,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Ciudades',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/jl14vgg1blbo/category.png',
                            action: () async {
                              context.pushNamed(
                                CiudadesWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              UsuariosWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 300),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.menuSeleccionModel6,
                            updateCallback: () => safeSetState(() {}),
                            child: MenuSeleccionWidget(
                              textseleccion: 'Usuarios',
                              imagen:
                                  'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/4ytkvlil6egm/account_circle.png',
                              action: () async {
                                context.pushNamed(
                                  UsuariosWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 0),
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel7,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Proveedores',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/vt3r5xmh9fo5/person_apron.png',
                            action: () async {
                              context.pushNamed(
                                ProveedoresWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                        wrapWithModel(
                          model: _model.menuSeleccionModel8,
                          updateCallback: () => safeSetState(() {}),
                          child: MenuSeleccionWidget(
                            textseleccion: 'Rendimiento',
                            imagen:
                                'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/dm21gi4z074w/Rendimiento.png',
                            action: () async {
                              context.pushNamed(
                                RendimientoWidget.routeName,
                                extra: <String, dynamic>{
                                  '__transition_info__': TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 0),
                                  ),
                                },
                              );
                            },
                          ),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: MouseRegion(
                    opaque: false,
                    cursor: MouseCursor.defer ?? MouseCursor.defer,
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        GoRouter.of(context).prepareAuthEvent();
                        await authManager.signOut();
                        GoRouter.of(context).clearRedirectLocation();

                        context.goNamedAuth(
                            LoginWebWidget.routeName, context.mounted);
                      },
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        decoration: BoxDecoration(
                          color: _model.mouseRegionHovered!
                              ? FlutterFlowTheme.of(context).customColor1
                              : Color(0x00000000),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 12.0, 12.0, 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/hulp-web-92cm9v/assets/3pqtw21ue2e6/Logout.png',
                                  width: 28.0,
                                  height: 28.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (FFAppState().MenuAbierto)
                                Text(
                                  'Cerrar sesión',
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
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ),
                      ),
                    ),
                    onEnter: ((event) async {
                      safeSetState(() => _model.mouseRegionHovered = true);
                    }),
                    onExit: ((event) async {
                      safeSetState(() => _model.mouseRegionHovered = false);
                    }),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 4.0),
                  child: Text(
                    FFAppState().MenuAbierto
                        ? 'v1.0.17 · 2026-09-24'
                        : 'v1.0.17',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.6),
                          fontSize: 11.0,
                          letterSpacing: 0.0,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
