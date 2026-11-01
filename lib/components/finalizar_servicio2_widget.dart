import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'seleccionar_profesional_widget.dart';
import 'finalizar_servicio2_model.dart';
export 'finalizar_servicio2_model.dart';

class FinalizarServicio2Widget extends StatefulWidget {
  const FinalizarServicio2Widget({
    super.key,
    required this.servicioId,
  });

  final String? servicioId;

  @override
  State<FinalizarServicio2Widget> createState() =>
      _FinalizarServicio2WidgetState();
}

class _FinalizarServicio2WidgetState extends State<FinalizarServicio2Widget> {
  late FinalizarServicio2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FinalizarServicio2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  void _avisar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryBackground,
          ),
        ),
        duration: Duration(milliseconds: 3000),
        backgroundColor: esError
            ? FlutterFlowTheme.of(context).error
            : FlutterFlowTheme.of(context).primary,
      ),
    );
  }

  String _mensajeErrorPago(dynamic respuesta, String alternativa) {
    if (respuesta is! Map) return alternativa;

    var mensaje = alternativa;
    for (final valor in [
      respuesta['error'],
      respuesta['statusMessage'],
      respuesta['message'],
    ]) {
      if (valor is String && valor.trim().isNotEmpty) {
        mensaje = valor.trim();
        break;
      }
    }

    final codigo = int.tryParse('${respuesta['statusCode'] ?? ''}');
    if (codigo != null && codigo >= 100 && codigo <= 599) {
      return '$mensaje (HTTP $codigo)';
    }
    return mensaje;
  }

  /// Resuelve con que profesional se cierra la solicitud.
  ///
  /// Si ya tiene uno asignado se respeta y no se molesta al administrador. Si
  /// no lo tiene —lo que ocurre en toda solicitud cuyo proveedor fue dado de
  /// baja, porque al borrarlo su `profesional_id` queda a nulo— se abre el
  /// selector, que ademas permite finalizar sin asignar a nadie.
  ///
  /// Devuelve `false` si el administrador cancela: entonces no se finaliza.
  Future<bool> _resolverProfesional(SolicitudesServicioRow solicitud) async {
    final asignado = solicitud.profesionalId;
    if (asignado != null && asignado.isNotEmpty) {
      _model.profesionalResuelto = asignado;
      return true;
    }

    if (!mounted) return false;
    final seleccion = await mostrarSelectorDeProfesional(
      context,
      servicioId: solicitud.servicioId,
      servicioNombre: solicitud.servicioNombre,
    );
    if (seleccion == null) return false;

    _model.profesionalResuelto = seleccion.profesionalId;
    return true;
  }

  bool _finalizando = false;

  Future<void> _finalizarServicio({required bool conCobro}) async {
    if (_finalizando) return;
    if (widget.servicioId == null || widget.servicioId!.isEmpty) {
      _avisar('No se encontró la solicitud.', esError: true);
      return;
    }
    setState(() => _finalizando = true);
    try {
      final solicitudes = await SolicitudesServicioTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.servicioId),
      );
      final solicitud = solicitudes.firstOrNull;
      if (solicitud == null) {
        _avisar('No se encontró la solicitud.', esError: true);
        return;
      }
      if (!await _resolverProfesional(solicitud)) return;
      await SolicitudesServicioTable().update(
        data: {
          'estado': 'finalizadas',
          'profesional_id': _model.profesionalResuelto,
        },
        matchingRows: (rows) => rows.eqOrNull('id', solicitud.id),
      );
      final resultado = conCobro
          ? await _cobrarAlFinalizar(solicitud)
          : 'Se conservó el estado del pago; no se realizó ningún cobro.';
      if (!mounted) return;
      _avisar('Servicio finalizado. $resultado');
      Navigator.pop(context);
    } catch (e) {
      _avisar('No se pudo finalizar el servicio: $e', esError: true);
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  Future<String> _cobrarAlFinalizar(SolicitudesServicioRow solicitud) async {
    // Una solicitud pagada solo necesita el cierre operativo.
    if (solicitud.estadoPago == 'pagado') {
      return 'El pago ya estaba registrado; no se realizó otro cobro.';
    }

    var aprobado = false;
    try {
      final metodos = await MetodosPagoTable().queryRows(
        queryFn: (q) => q.eqOrNull('usuario_id', solicitud.usuarioId)
            .eqOrNull('es_predeterminado', true),
      );
      int fuente;
      String metodo;
      if (metodos.isNotEmpty) {
        fuente = metodos.first.paymentSourceId;
        metodo = metodos.first.tipo;
      } else {
        final tarjetas = await TarjetasGuardadasTable().queryRows(
          queryFn: (q) => q.eqOrNull('usuario_id', solicitud.usuarioId),
        );
        if (tarjetas.isEmpty) {
          return 'No se realizó un cobro: el cliente no tiene método de pago. '
              'Se conservó el estado del pago.';
        }
        fuente = int.tryParse(tarjetas.first.paymentSourceId) ?? 0;
        metodo = 'CARD';
      }
      if (fuente <= 0) {
        return 'No se realizó un cobro: el método de pago no es válido. '
            'Se conservó el estado del pago.';
      }
      final tokens = await actions.getAcceptanceToken(
        FFDevEnvironmentValues().publicKey,
        FFDevEnvironmentValues().isProduction,
      );
      if (tokens is! Map || tokens['success'] != true) {
        return 'Pago sin confirmar. ${_mensajeErrorPago(tokens, 'No se pudieron obtener los tokens de pago.')}';
      }
      final pago = await actions.createTransaction(
        FFDevEnvironmentValues().privateKey,
        FFDevEnvironmentValues().publicKey,
        fuente,
        tokens['acceptanceToken']?.toString() ?? '',
        (((solicitud.precioBase ?? solicitud.precio) +
            (solicitud.precioAdicionales ?? 0)) * 100).round(),
        'COP',
        '', // El backend obtiene el correo del cliente.
        '${solicitud.id}-${DateTime.now().millisecondsSinceEpoch}',
        FFDevEnvironmentValues().integrityKey,
        FFDevEnvironmentValues().isProduction,
        personalDataAuthToken: tokens['personalDataAuthToken']?.toString() ?? '',
      );
      if (pago is! Map || pago['success'] != true || pago['status'] != 'APPROVED') {
        return 'Pago sin confirmar. ${_mensajeErrorPago(pago, 'El cobro no fue aprobado.')}';
      }
      aprobado = true;
      await TransaccionesTable().insert({
        'solicitud_id': solicitud.id,
        'usuario_id': solicitud.usuarioId,
        'monto': (pago['amount'] as num) / 100,
        'moneda': 'COP',
        'proveedor_pago': 'WOMPI',
        'metodo_pago': metodo,
        'numero_transaccion': pago['transactionId']?.toString(),
        'referencia_externa': pago['reference']?.toString(),
        'datos_pago': pago['fullData'],
        'fecha_pago': supaSerialize<DateTime>(getCurrentTimestamp),
        'fecha_registro': supaSerialize<DateTime>(getCurrentTimestamp),
      });
      await SolicitudesServicioTable().update(
        data: {'estado_pago': 'pagado'},
        matchingRows: (rows) => rows.eqOrNull('id', solicitud.id),
      );
      return 'Pago aprobado y registrado.';
    } catch (e) {
      if (aprobado) {
        return 'Wompi aprobó el cobro, pero no se pudo completar su registro: $e. '
            'Verifica el pago antes de intentar otro cobro.';
      }
      return 'Pago sin confirmar: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 540.0,
          ),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: 0.0,
                      child: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                    ),
                    Text(
                      'Proveedores',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            fontSize: 22.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: const EdgeInsets.all(12),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                  child: Image.asset(
                    'assets/images/Iconos_de_estado.png',
                    width: 80.0,
                    height: 80.0,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                  child: Text(
                    'Finalizar servicio',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 18.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 16.0, 10.0, 0.0),
                    child: Text(
                      'Recuerda que al finalizar el servicio, también estás aceptando los términos y condiciones.\n\nEsta acción es definitiva y no se puede revertir.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 16.0,
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
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                  child: FFButtonWidget(
                    onPressed: _finalizando
                        ? null
                        : () => _finalizarServicio(conCobro: true),
                    text: 'Finalizar servicio con metodos de pago',
                    options: FFButtonOptions(
                      height: 40.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 14.0, 0.0, 0.0),
                  child: FFButtonWidget(
                    onPressed: _finalizando
                        ? null
                        : () => _finalizarServicio(conCobro: false),
                    text: 'Finalizar servicio sin metodos de pago',
                    options: FFButtonOptions(
                      height: 40.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
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
