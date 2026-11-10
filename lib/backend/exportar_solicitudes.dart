import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import '/backend/supabase/supabase.dart';

/// SpreadsheetML abre en Excel. Todos los importes salen de valores persistidos.
String solicitudesExcelXml(List<VwSolicitudesServiciosCompletaRow> rows) {
  String escape(Object? v) => (v?.toString() ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  String cell(Object? v) =>
      '<Cell><Data ss:Type="${v is num ? 'Number' : 'String'}">${escape(v)}</Data></Cell>';
  final content = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>'
      '<?mso-application progid="Excel.Sheet"?>'
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Solicitudes"><Table>');
  const columns = [
    'Ticket',
    'Cliente',
    'Servicio / jornada',
    'Ciudad',
    'Dirección',
    'Estado',
    'Pago',
    'Precio lista',
    'Precio pagado (acordado)',
    'Motivo',
    'Materiales',
    'Adelanto',
    'Motivo adelanto',
    'Pago proveedor',
    'Saldo a transferir',
    'Comisión Hulp + IVA',
    'Comisión neta Hulp',
    'IVA',
    'Comisión efectiva (%)',
    'Wompi',
    'Ajuste IVA',
    'Total cliente',
    'Requiere FE',
    'Descripción para proveedora',
    'Notas internas',
    'Notas del cliente',
    'Versión'
  ];
  content.write('<Row>${columns.map(cell).join()}</Row>');
  for (final row in rows) {
    final d = row.data;
    final v1 = row.finanzasVersion == 1;
    final values = <Object?>[
      row.ticket,
      row.clienteNombreCompleto,
      row.servicioNombre,
      row.solicitudCiudad,
      row.ubicacion,
      row.estadoSolicitud,
      row.estadoPago,
      row.precioBase,
      row.precioSolicitud,
      d['motivo_precio_pagado'],
      v1 ? row.materialesTotal : row.precioAdicionales,
      d['adelanto_proveedor'],
      d['adelanto_motivo'],
      d['pago_proveedor'],
      d['saldo_transferir'],
      d['comision_hulp_iva'],
      d['comision_neta_hulp'],
      d['iva_valor'],
      d['comision_efectiva'],
      d['wompi_valor'],
      d['ajuste_iva_valor'],
      v1 ? row.totalCliente : row.precioTotal,
      row.requiereFe == true ? 'Sí' : 'No',
      row.solicitudDescripcion,
      row.informacionAdicional,
      row.notasCliente,
      row.finanzasVersion ?? 'Histórica'
    ];
    content.write('<Row>${values.map(cell).join()}</Row>');
  }
  content.write('</Table></Worksheet></Workbook>');
  return content.toString();
}

Future<void> exportarSolicitudesExcel(
        List<VwSolicitudesServiciosCompletaRow> rows) =>
    FileSaver.instance.saveFile(
      name: 'solicitudes_${DateTime.now().toIso8601String().substring(0, 10)}',
      bytes: Uint8List.fromList(utf8.encode(solicitudesExcelXml(rows))),
      ext: 'xls',
      mimeType: MimeType.other,
    );
