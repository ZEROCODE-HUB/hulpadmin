import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dropdown_soporte_model.dart';
export 'dropdown_soporte_model.dart';

class DropdownSoporteWidget extends StatefulWidget {
  const DropdownSoporteWidget({
    super.key,
    required this.estadoActual,
    required this.index,
    required this.soporteId,
    required this.actionnavegacion,
  });

  final String? estadoActual;
  final int? index;
  final String? soporteId;
  final Future Function()? actionnavegacion;

  @override
  State<DropdownSoporteWidget> createState() => _DropdownSoporteWidgetState();
}

class _DropdownSoporteWidgetState extends State<DropdownSoporteWidget> {
  late DropdownSoporteModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropdownSoporteModel());

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
      width: 160.0,
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
              Navigator.pop(context);
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
                      color: widget!.estadoActual == 'pendiente'
                          ? Color(0xFFE9EBEC)
                          : (widget!.estadoActual == 'en proceso'
                              ? Color(0xFFD6EAFF)
                              : (widget!.estadoActual == 'completado'
                                  ? Color(0xFFDFF9D2)
                                  : (widget!.estadoActual == 'rechazado'
                                      ? Color(0xFFF9DCDF)
                                      : Color(0xFFFFF5D6)))),
                      borderRadius: BorderRadius.circular(24.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: widget!.estadoActual == 'pendiente'
                            ? Color(0xFF6C757D)
                            : (widget!.estadoActual == 'en proceso'
                                ? Color(0xFF007BFF)
                                : (widget!.estadoActual == 'completado'
                                    ? Color(0xFF388212)
                                    : (widget!.estadoActual == 'rechazado'
                                        ? Color(0xFFDC3545)
                                        : Color(0xFFD6A100)))),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 2.0),
                      child: Text(
                        (widget.estadoActual?.trim().isEmpty ?? true)
                            ? 'Sin estado'
                            : widget!.estadoActual == 'pendiente'
                            ? 'Pendiente'
                            : (widget!.estadoActual == 'en proceso'
                                ? 'En proceso'
                                : (widget!.estadoActual == 'rechazado'
                                    ? 'Rechazado'
                                    : (widget!.estadoActual == 'completado'
                                        ? 'Completado'
                                        : 'Escalado'))),
                        maxLines: 2,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: widget!.estadoActual == 'pendiente'
                                  ? Color(0xFF6C757D)
                                  : (widget!.estadoActual == 'en proceso'
                                      ? Color(0xFF007BFF)
                                      : (widget!.estadoActual == 'completado'
                                          ? Color(0xFF388212)
                                          : (widget!.estadoActual == 'rechazado'
                                              ? Color(0xFFDC3545)
                                              : Color(0xFFD6A100)))),
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
          Builder(
            builder: (context) {
              final listaOpciones = _model.opciones.toList();

              return Column(
                mainAxisSize: MainAxisSize.max,
                children:
                    List.generate(listaOpciones.length, (listaOpcionesIndex) {
                  final listaOpcionesItem = listaOpciones[listaOpcionesIndex];
                  return Visibility(
                    visible: widget!.estadoActual != listaOpcionesItem,
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          await SoporteTable().update(
                            data: {
                              'estado': listaOpcionesItem,
                            },
                            matchingRows: (rows) => rows.eqOrNull(
                              'id',
                              widget!.soporteId,
                            ),
                          );
                          await widget.actionnavegacion?.call();

                          safeSetState(() {});
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: listaOpcionesItem == 'pendiente'
                                    ? Color(0xFFE9EBEC)
                                    : (listaOpcionesItem == 'en proceso'
                                        ? Color(0xFFD6EAFF)
                                        : (listaOpcionesItem == 'completado'
                                            ? Color(0xFFDFF9D2)
                                            : (listaOpcionesItem == 'rechazado'
                                                ? Color(0xFFF9DCDF)
                                                : Color(0xFFFFF5D6)))),
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color: listaOpcionesItem == 'pendiente'
                                      ? Color(0xFF6C757D)
                                      : (listaOpcionesItem == 'en proceso'
                                          ? Color(0xFF007BFF)
                                          : (listaOpcionesItem == 'completado'
                                              ? Color(0xFF388212)
                                              : (listaOpcionesItem ==
                                                      'rechazado'
                                                  ? Color(0xFFDC3545)
                                                  : Color(0xFFD6A100)))),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 4.0, 0.0, 4.0),
                              child: Text(
                                listaOpcionesItem == 'pendiente'
                                    ? 'Pendiente'
                                    : (listaOpcionesItem == 'en proceso'
                                        ? 'En proceso'
                                        : (listaOpcionesItem == 'rechazado'
                                            ? 'Cancelado'
                                            : (listaOpcionesItem == 'completado'
                                                ? 'Completado'
                                                : 'Escalado'))),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
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
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
