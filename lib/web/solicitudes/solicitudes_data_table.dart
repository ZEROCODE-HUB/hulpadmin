import 'package:data_table_2/data_table_2.dart' show DataRow2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/supabase/supabase.dart';
import '/components/solicitud_status_badge_widget.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/solicitud_payment_helpers.dart';
import '/flutter_flow/direccion_solicitud_helpers.dart';

class SolicitudesDataTable extends StatelessWidget {
  const SolicitudesDataTable({
    super.key,
    required this.data,
    required this.controller,
    required this.onStatusTap,
    required this.onDelete,
    required this.onViewDetails,
    required this.onEdit,
    required this.onMarkPaymentReceived,
    required this.updatingPaymentIds,
  });

  final List<VwSolicitudesServiciosCompletaRow> data;
  final FlutterFlowDataTableController<VwSolicitudesServiciosCompletaRow>
      controller;
  final void Function(BuildContext anchorContext,
      VwSolicitudesServiciosCompletaRow item, int index) onStatusTap;
  final void Function(VwSolicitudesServiciosCompletaRow item) onDelete;
  final void Function(VwSolicitudesServiciosCompletaRow item) onViewDetails;
  final void Function(VwSolicitudesServiciosCompletaRow item) onEdit;
  final void Function(VwSolicitudesServiciosCompletaRow item)
      onMarkPaymentReceived;
  final Set<String> updatingPaymentIds;

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
        data: ScrollbarTheme.of(context).copyWith(
          thumbVisibility: const WidgetStatePropertyAll(true),
        ),
        child: FlutterFlowDataTable<VwSolicitudesServiciosCompletaRow>(
          controller: controller,
          data: data,
          columnsBuilder: (onSortChanged) => _buildColumns(context),
          dataRowBuilder: (item, index, selected, onSelectChanged) =>
              _buildRow(context, item, index),
          paginated: true,
          selectable: false,
          hidePaginator: false,
          showFirstLastButtons: true,
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          minWidth: 1800.0,
          headingRowHeight: 56.0,
          dataRowHeight: 60.0,
          columnSpacing: 20.0,
          headingRowColor: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(20.0),
          addHorizontalDivider: false,
          addTopAndBottomDivider: false,
          hideDefaultHorizontalDivider: true,
          addVerticalDivider: false,
        ));
  }

  List<DataColumn2> _buildColumns(BuildContext context) {
    final headerStyle = FlutterFlowTheme.of(context).bodyMedium.override(
          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
          fontSize: 16.0,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w600,
        );

    return [
      _col('Ticket', headerStyle),
      _col('Estado', headerStyle, fixedWidth: 160.0),
      _col('Fecha y hora', headerStyle),
      _col('Usu. Solicitante', headerStyle, fixedWidth: 210.0),
      _col('Ciudad', headerStyle),
      _col('Direccion', headerStyle, fixedWidth: 280.0),
      _col('Categoria', headerStyle),
      _col('Precio', headerStyle),
      _col('Pago', headerStyle, fixedWidth: 160.0),
      _col('ID Proveedor', headerStyle),
      _col('Acciones', headerStyle, fixedWidth: 140.0),
    ];
  }

  DataColumn2 _col(String label, TextStyle style, {double? fixedWidth}) {
    return DataColumn2(
      label: DefaultTextStyle.merge(
        softWrap: true,
        child: Text(label, style: style),
      ),
      fixedWidth: fixedWidth,
    );
  }

  DataRow _buildRow(
    BuildContext context,
    VwSolicitudesServiciosCompletaRow item,
    int index,
  ) {
    final bodyStyle = FlutterFlowTheme.of(context).bodyMedium.override(
          font: GoogleFonts.inter(),
          letterSpacing: 0.0,
          lineHeight: 1.4,
        );
    final ciudad = item.solicitudCiudad?.trim() ?? '';
    final direccion = direccionSolicitudVisible(item.ubicacion, ciudad);

    // La columna mide 280 px y reserva 20 px para el espacio entre celdas.
    // La fila crece según el texto real, incluidos saltos y escala de fuente.
    final medicionDireccion = TextPainter(
      text: TextSpan(text: direccion, style: bodyStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 260.0);
    final alturaFila = (medicionDireccion.height + 24.0)
        .clamp(60.0, double.infinity)
        .toDouble();
    medicionDireccion.dispose();

    return DataRow2(
      specificRowHeight: alturaFila,
      color: WidgetStateProperty.all(
        FlutterFlowTheme.of(context).secondaryBackground,
      ),
      cells: [
        // Ticket
        DataCell(_textoCelda(
          '#${valueOrDefault<String>(item.ticket?.toString(), '0000')}',
          style: bodyStyle.override(
            font: GoogleFonts.inter(),
            color: const Color(0xFF4A4A4A),
            fontSize: 16.0,
          ),
        )),
        // Estado
        DataCell(Builder(
            builder: (anchorContext) => SolicitudStatusBadgeWidget(
                  estado: item.estadoSolicitud ?? '',
                  showArrow: true,
                  onTap: () => onStatusTap(anchorContext, item, index),
                ))),
        // Fecha y hora
        DataCell(_textoCelda(
          valueOrDefault<String>(
            '${dateTimeFormat("jm", item.hora?.time)} -  ${dateTimeFormat("d/M/y", item.fecha)}',
            'sin fecha',
          ),
          style: bodyStyle,
        )),
        // Usuario solicitante
        DataCell(_textoCelda(
          nombreClienteVisible(item.clienteNombreCompleto),
          style: bodyStyle,
        )),
        // Ciudad (REQ-006 v1.0.0)
        DataCell(_textoCelda(
          ciudad.isEmpty ? 'Sin ciudad' : ciudad,
          style: bodyStyle,
        )),
        // Direccion
        DataCell(InkWell(
          splashColor: Colors.transparent,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: item.ubicacion ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Copiado al portapapeles',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      fontSize: 14.0)),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).success,
            ));
          },
          child: _textoCelda(direccion, style: bodyStyle),
        )),
        // Categoria
        DataCell(_textoCelda(
          valueOrDefault<String>(item.categoriaNombre, 'Sin datos'),
          style: bodyStyle,
        )),
        // Precio
        DataCell(_textoCelda(
          valueOrDefault<String>(
            '\$ ${valueOrDefault<String>(item.precioTotal?.toString(), '0')}',
            'Sin datos',
          ),
          style: bodyStyle.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.w500),
            color: const Color(0xFF0D70E7),
            fontWeight: FontWeight.w500,
          ),
        )),
        // Estado del pago y acción directa para marcarlo recibido.
        DataCell(_buildPaymentCell(context, item, bodyStyle)),
        // ID Proveedor
        DataCell(_textoCelda(
          valueOrDefault<String>(
              item.proveedorIdUsuario?.toString(), 'Sin datos'),
          style: bodyStyle,
        )),
        // Acciones
        DataCell(Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            FlutterFlowIconButton(
              borderRadius: 10.0,
              buttonSize: 35.0,
              fillColor: const Color(0xFFB81C2C),
              icon: Icon(Icons.close,
                  color: FlutterFlowTheme.of(context).info, size: 18.0),
              onPressed: () => onDelete(item),
            ),
            FlutterFlowIconButton(
              borderRadius: 10.0,
              buttonSize: 34.0,
              fillColor: const Color(0xFF606060),
              icon: Icon(Icons.search_rounded,
                  color: FlutterFlowTheme.of(context).info, size: 18.0),
              onPressed: () => onViewDetails(item),
            ),
            FlutterFlowIconButton(
              borderRadius: 10.0,
              buttonSize: 34.0,
              fillColor: FlutterFlowTheme.of(context).warning,
              icon: Icon(Icons.edit,
                  color: FlutterFlowTheme.of(context).info, size: 18.0),
              onPressed: () => onEdit(item),
            ),
          ].divide(const SizedBox(width: 3.0)),
        )),
      ],
    );
  }

  /// Todas las celdas muestran su texto completo y conservan el tooltip.
  Widget _textoCelda(String texto, {required TextStyle style}) {
    return Tooltip(
      message: texto,
      constraints: const BoxConstraints(maxWidth: 480.0),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 20),
      child: Text(
        texto,
        style: style,
        maxLines: null,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }

  Widget _buildPaymentCell(
    BuildContext context,
    VwSolicitudesServiciosCompletaRow item,
    TextStyle bodyStyle,
  ) {
    final status = item.estadoPago;
    final solicitudId = item.solicitudId;
    final paymentReceived = isPaymentReceived(status);

    if (!paymentReceived && !isPaymentPending(status)) {
      return _textoCelda(paymentStatusLabel(status), style: bodyStyle);
    }

    final isUpdating =
        solicitudId != null && updatingPaymentIds.contains(solicitudId);

    return Tooltip(
      message: paymentReceived
          ? 'Pago recibido'
          : isUpdating
              ? 'Guardando pago'
              : 'Marcar pago como recibido',
      child: InkWell(
        onTap: paymentReceived || solicitudId == null || isUpdating
            ? null
            : () => onMarkPaymentReceived(item),
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24.0,
                height: 24.0,
                decoration: BoxDecoration(
                  color: paymentReceived
                      ? const Color(0xFF2E6D52)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: paymentReceived
                        ? const Color(0xFF2E6D52)
                        : const Color(0xFF8B8B8B),
                    width: 1.5,
                  ),
                ),
                child: isUpdating
                    ? const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : paymentReceived
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18.0)
                        : null,
              ),
              const SizedBox(width: 8.0),
              Flexible(
                  child: _textoCelda(
                isUpdating ? 'Guardando...' : paymentStatusLabel(status),
                style: bodyStyle.copyWith(
                  color: paymentReceived
                      ? const Color(0xFF2E6D52)
                      : const Color(0xFF6F6F6F),
                  fontWeight:
                      paymentReceived ? FontWeight.w700 : FontWeight.w500,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
