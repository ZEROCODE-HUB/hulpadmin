import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/supabase/supabase.dart';
import '/components/detalle_solicitud_datos_widget.dart';
import '/components/hulp_modal_actions.dart';
import '/components/detalle_solicitud_precio_base_widget.dart';
import '/components/detalle_solicitud_tabs.dart';
import '/components/encabezado_solicitud_widget.dart';
import '/components/solicitud_finanzas_form.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/solicitud_payment_helpers.dart';
import 'detalle_solicitud_model.dart';
export 'detalle_solicitud_model.dart';

class DetalleSolicitudWidget extends StatefulWidget {
  const DetalleSolicitudWidget({
    super.key,
    required this.solicitudId,
    this.onEditar,
  });

  final String? solicitudId;
  final Future<void> Function()? onEditar;

  @override
  State<DetalleSolicitudWidget> createState() => _DetalleSolicitudWidgetState();
}

class _DetalleSolicitudWidgetState extends State<DetalleSolicitudWidget> {
  late DetalleSolicitudModel _model;
  late Future<List<VwSolicitudesServiciosCompletaRow>> _solicitudFuture;

  Future<List<VwSolicitudesServiciosCompletaRow>> _consultarSolicitud() =>
      VwSolicitudesServiciosCompletaTable().querySingleRow(
        queryFn: (query) => query.eqOrNull('solicitud_id', widget.solicitudId),
      );

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetalleSolicitudModel());
    _solicitudFuture = _consultarSolicitud();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _reintentarCarga() {
    safeSetState(() => _solicitudFuture = _consultarSolicitud());
  }

  Widget _acciones(BuildContext context) => hulpModalActionRow(
        actions: [
          hulpModalCloseButton(
            text: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          hulpModalPrimaryButton(
            context: context,
            text: 'Editar solicitud',
            onPressed:
                widget.onEditar == null ? null : () async => widget.onEditar!(),
          ),
        ],
      );

  Widget _encabezado(VwSolicitudesServiciosCompletaRow? solicitud) =>
      EncabezadoSolicitudWidget(
        titulo: 'Detalles de la solicitud',
        ticket: solicitud?.ticket,
        estado: solicitud?.estadoSolicitud,
        estadoInteractivo: false,
        pagoRecibido:
            solicitud == null ? null : isPaymentReceived(solicitud.estadoPago),
        onEstado: (_) {},
      );

  Widget _sinSolicitud(BuildContext context) => DetalleSolicitudTabs(
        encabezado: _encabezado(null),
        datos: const Center(child: Text('No se encontró esta solicitud.')),
        finanzas: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay un desglose financiero disponible.'),
        ),
        acciones: _acciones(context),
      );

  Widget _contenido(
    BuildContext context,
    VwSolicitudesServiciosCompletaRow solicitud,
  ) {
    final Widget finanzas = solicitud.finanzasVersion == 1
        ? SolicitudFinanzasForm(
            precioLista: solicitud.precioBase ?? 0,
            solicitudId: widget.solicitudId,
            soloLectura: true,
            disposicionCrear: true,
          )
        : DetalleSolicitudPrecioBaseWidget(
            precioBase: solicitud.precioBase,
          );

    return DetalleSolicitudTabs(
      encabezado: _encabezado(solicitud),
      solicitudId: solicitud.solicitudId,
      datos: DetalleSolicitudDatosWidget(
        solicitud: solicitud,
        mostrarChat: _model.showChat,
        onAlternarChat: () =>
            safeSetState(() => _model.showChat = !_model.showChat),
      ),
      finanzas: finanzas,
      acciones: _acciones(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final modalWidth = (screen.width - 32).clamp(280.0, 1200.0).toDouble();
    final modalHeight = (screen.height - 32).clamp(240.0, 1000.0).toDouble();
    final innerPadding = modalWidth < 520 ? 14.0 : 22.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: modalWidth,
          height: modalHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(innerPadding),
            child: FutureBuilder<List<VwSolicitudesServiciosCompletaRow>>(
              future: _solicitudFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo cargar la solicitud.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _reintentarCarga,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  );
                }

                final solicitud =
                    snapshot.data!.isEmpty ? null : snapshot.data!.first;
                return solicitud == null
                    ? _sinSolicitud(context)
                    : _contenido(context, solicitud);
              },
            ),
          ),
        ),
      ),
    );
  }
}
