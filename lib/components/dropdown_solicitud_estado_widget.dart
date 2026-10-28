import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/finalizar_servicio2_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dropdown_solicitud_estado_model.dart';
export 'dropdown_solicitud_estado_model.dart';

class DropdownSolicitudEstadoWidget extends StatefulWidget {
  const DropdownSolicitudEstadoWidget({
    super.key,
    required this.estadoActual,
    required this.index,
    required this.solicitudId,
    required this.actionnavegacion,
    this.userid,
  });

  final String? estadoActual;
  final int? index;
  final String? solicitudId;
  final Future Function()? actionnavegacion;
  final String? userid;

  @override
  State<DropdownSolicitudEstadoWidget> createState() =>
      _DropdownSolicitudEstadoWidgetState();
}

class _DropdownSolicitudEstadoWidgetState
    extends State<DropdownSolicitudEstadoWidget> {
  late DropdownSolicitudEstadoModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DropdownSolicitudEstadoModel());

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
                      color: widget!.estadoActual == 'entrantes'
                          ? Color(0xFFE9EBEC)
                          : (widget!.estadoActual == 'aceptadas'
                              ? Color(0xFFD6EAFF)
                              : (widget!.estadoActual == 'finalizadas'
                                  ? Color(0xFFDFF9D2)
                                  : ((widget!.estadoActual == 'canceladas') ||
                                          (widget!.estadoActual ==
                                              'reagendadas')
                                      ? Color(0xFFF9DCDF)
                                      : Color(0xFFFFF5D6)))),
                      borderRadius: BorderRadius.circular(24.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: widget!.estadoActual == 'entrantes'
                            ? Color(0xFF6C757D)
                            : (widget!.estadoActual == 'aceptadas'
                                ? Color(0xFF007BFF)
                                : (widget!.estadoActual == 'finalizadas'
                                    ? Color(0xFF388212)
                                    : ((widget!.estadoActual == 'canceladas') ||
                                            (widget!.estadoActual ==
                                                'reagendadas')
                                        ? Color(0xFFDC3545)
                                        : Color(0xFFD6A100)))),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 2.0),
                      child: Text(
                        widget!.estadoActual == 'entrantes'
                            ? 'Pendiente'
                            : (widget!.estadoActual == 'aceptadas'
                                ? 'Activo'
                                : (widget!.estadoActual == 'canceladas'
                                    ? 'Cancelado'
                                    : (widget!.estadoActual == 'finalizadas'
                                        ? 'Finalizado'
                                        : (widget!.estadoActual == 'reagendadas'
                                            ? 'Reagendada'
                                            : 'En curso')))),
                        maxLines: 2,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: widget!.estadoActual == 'entrantes'
                                  ? Color(0xFF6C757D)
                                  : (widget!.estadoActual == 'aceptadas'
                                      ? Color(0xFF007BFF)
                                      : (widget!.estadoActual == 'finalizadas'
                                          ? Color(0xFF388212)
                                          : ((widget!.estadoActual ==
                                                      'canceladas') ||
                                                  (widget!.estadoActual ==
                                                      'reagendadas')
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
                    visible: (widget!.estadoActual != listaOpcionesItem) &&
                        ((listaOpcionesItem != 'iniciadas') &&
                            (listaOpcionesItem != 'en camino')),
                    child: Builder(
                      builder: (context) => Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            if (listaOpcionesItem == 'finalizadas') {
                              await showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return Dialog(
                                    elevation: 0,
                                    insetPadding: EdgeInsets.zero,
                                    backgroundColor: Colors.transparent,
                                    alignment: AlignmentDirectional(0.0, 0.0)
                                        .resolve(Directionality.of(context)),
                                    child: FinalizarServicio2Widget(
                                      servicioId: widget!.solicitudId!,
                                    ),
                                  );
                                },
                              );
                            } else {
                              await SolicitudesServicioTable().update(
                                data: {
                                  'estado': listaOpcionesItem,
                                },
                                matchingRows: (rows) => rows.eqOrNull(
                                  'id',
                                  widget!.solicitudId,
                                ),
                              );
                            }

                            await SenNotificationUserHulpCall.call(
                              userIdSupabase: widget!.userid,
                              title: 'Su solicitud esta ${listaOpcionesItem}',
                              message: 'Haga click aqui para entrar',
                            );

                            await widget.actionnavegacion?.call();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10.0,
                                height: 10.0,
                                decoration: BoxDecoration(
                                  color: listaOpcionesItem == 'entrantes'
                                      ? Color(0xFFE9EBEC)
                                      : (listaOpcionesItem == 'aceptadas'
                                          ? Color(0xFFD6EAFF)
                                          : (listaOpcionesItem == 'finalizadas'
                                              ? Color(0xFFDFF9D2)
                                              : ((listaOpcionesItem ==
                                                          'canceladas') ||
                                                      (listaOpcionesItem ==
                                                          'reagendadas')
                                                  ? Color(0xFFF9DCDF)
                                                  : Color(0xFFFFF5D6)))),
                                  borderRadius: BorderRadius.circular(24.0),
                                  border: Border.all(
                                    color: listaOpcionesItem == 'entrantes'
                                        ? Color(0xFF6C757D)
                                        : (listaOpcionesItem == 'aceptadas'
                                            ? Color(0xFF007BFF)
                                            : (listaOpcionesItem ==
                                                    'finalizadas'
                                                ? Color(0xFF388212)
                                                : ((listaOpcionesItem ==
                                                            'canceladas') ||
                                                        (listaOpcionesItem ==
                                                            'reagendadas')
                                                    ? Color(0xFFDC3545)
                                                    : Color(0xFFD6A100)))),
                                  ),
                                ),
                              ),
                              Flexible(child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 4.0, 0.0, 4.0),
                                child: Text(
                                  listaOpcionesItem == 'entrantes'
                                      ? 'Pendiente'
                                      : (listaOpcionesItem == 'aceptadas'
                                          ? 'Activo'
                                          : (listaOpcionesItem == 'canceladas'
                                              ? 'Cancelado'
                                              : (listaOpcionesItem ==
                                                      'finalizadas'
                                                  ? 'Finalizado'
                                                  : (listaOpcionesItem ==
                                                          'reagendadas'
                                                      ? 'Reagendada'
                                                      : 'En curso')))),
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
                                ),
                              )),
                            ].divide(SizedBox(width: 10.0)),
                          ),
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
