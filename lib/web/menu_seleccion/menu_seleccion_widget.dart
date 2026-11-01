import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'menu_seleccion_model.dart';
export 'menu_seleccion_model.dart';

class MenuSeleccionWidget extends StatefulWidget {
  const MenuSeleccionWidget({
    super.key,
    required this.textseleccion,
    required this.imagen,
    required this.action,
    this.movil = false,
  });

  final String? textseleccion;
  final String? imagen;
  final Future Function()? action;
  final bool movil;

  @override
  State<MenuSeleccionWidget> createState() => _MenuSeleccionWidgetState();
}

class _MenuSeleccionWidgetState extends State<MenuSeleccionWidget> {
  late MenuSeleccionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuSeleccionModel());

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

    return MouseRegion(
      opaque: false,
      cursor: MouseCursor.defer ?? MouseCursor.defer,
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          FFAppState().seleccionMenu = widget!.textseleccion!;
          _model.updatePage(() {});
          if (widget.movil) Scaffold.of(context).closeDrawer();
          await widget.action?.call();
        },
        child: Container(
          decoration: BoxDecoration(
            color: valueOrDefault<Color>(
              () {
                if (_model.mouseRegionHovered!) {
                  return FlutterFlowTheme.of(context).customColor1;
                } else if (FFAppState().seleccionMenu ==
                    widget!.textseleccion) {
                  return FlutterFlowTheme.of(context).customColor1;
                } else {
                  return FlutterFlowTheme.of(context).primary;
                }
              }(),
              FlutterFlowTheme.of(context).primary,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget!.imagen!,
                    width: 27.0,
                    height: 27.0,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 27, height: 27),
                  ),
                ),
                if (widget.movil || FFAppState().MenuAbierto)
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                      child: Text(
                        valueOrDefault<String>(
                          widget!.textseleccion,
                          'Opción',
                        ),
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.normal,
                                fontStyle: FlutterFlowTheme.of(context)
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
                    ),
                  ),
              ],
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
    );
  }
}
