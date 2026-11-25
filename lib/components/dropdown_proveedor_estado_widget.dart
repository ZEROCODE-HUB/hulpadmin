import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dropdown_proveedor_estado_model.dart';
export 'dropdown_proveedor_estado_model.dart';

class DropdownProveedorEstadoWidget extends StatefulWidget {
  const DropdownProveedorEstadoWidget({
    super.key,
    required this.estadoActual,
    required this.index,
    required this.proveedorId,
    required this.actionnavegacion,
  });

  final String? estadoActual;
  final int? index;
  final String? proveedorId;
  final Future Function()? actionnavegacion;

  @override
  State<DropdownProveedorEstadoWidget> createState() =>
      _DropdownProveedorEstadoWidgetState();
}

class _DropdownProveedorEstadoWidgetState
    extends State<DropdownProveedorEstadoWidget> {
  late DropdownProveedorEstadoModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropdownProveedorEstadoModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF6F5F3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).tertiary,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              if ((widget!.estadoActual == 'pendiente') ||
                  (widget!.estadoActual == 'sin documentos')) {
                _model.showState = !_model.showState;
                safeSetState(() {});
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_sharp,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget!.estadoActual == 'sin documentos'
                          ? Color(0xFFE9EBEC)
                          : (widget!.estadoActual == 'verificado'
                              ? Color(0xFFDFF9D2)
                              : (widget!.estadoActual == 'no verificado'
                                  ? Color(0xFFF9DCDF)
                                  : Color(0xFFE9EBEC))),
                      borderRadius: BorderRadius.circular(24.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: widget!.estadoActual == 'sin documentos'
                            ? Color(0xFF6C757D)
                            : (widget!.estadoActual == 'verificado'
                                ? Color(0xFF388212)
                                : (widget!.estadoActual == 'no verificado'
                                    ? Color(0xFFDC3545)
                                    : Color(0xFF6C757D))),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 2.0),
                      child: Text(
                        widget!.estadoActual == 'sin documentos'
                            ? 'Docs. faltantes'
                            : (widget!.estadoActual == 'verificado'
                                ? 'Aceptado'
                                : (widget!.estadoActual == 'no verificado'
                                    ? 'Cancelado'
                                    : 'Recibido')),
                        maxLines: 2,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: widget!.estadoActual == 'sin documentos'
                                  ? Color(0xFF6C757D)
                                  : (widget!.estadoActual == 'verificado'
                                      ? Color(0xFF388212)
                                      : (widget!.estadoActual == 'no verificado'
                                          ? Color(0xFFDC3545)
                                          : Color(0xFF6C757D))),
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
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
          if (_model.showState == true)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  final onGuardado = widget.actionnavegacion;
                  await UsuariosTable().update(
                    data: {
                      'verificado': widget!.estadoActual == 'sin documentos'
                          ? 'pendiente'
                          : 'sin documentos',
                    },
                    matchingRows: (rows) => rows.eqOrNull(
                      'id',
                      widget!.proveedorId,
                    ),
                  );
                  safeSetState(() => _model.showState = false);
                  await onGuardado?.call();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).secondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
                      child: Text(
                        widget!.estadoActual == 'sin documentos'
                            ? 'Recibido'
                            : 'Docs. faltantes',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
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
                      ),
                    ),
                  ].divide(SizedBox(width: 10.0)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
