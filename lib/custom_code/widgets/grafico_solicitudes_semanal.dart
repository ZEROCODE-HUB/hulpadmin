// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

class GraficoSolicitudesSemanal extends StatefulWidget {
  const GraficoSolicitudesSemanal({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<GraficoSolicitudesSemanal> createState() =>
      _GraficoSolicitudesSemanalState();
}

class _GraficoSolicitudesSemanalState extends State<GraficoSolicitudesSemanal> {
  List<BarChartGroupData> barGroups = [];
  List<String> labels = [];
  bool isLoading = true;
  String error = '';
  int totalSolicitudes = 0;

  // Estados válidos para contar
  final List<String> estadosValidos = [
    'aceptadas',
    'iniciadas',
    'en camino',
    'en proceso',
    'finalizadas'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('=== INICIANDO CARGA SOLICITUDES SEMANAL ===');

      setState(() {
        isLoading = true;
        error = '';
      });

      final now = DateTime.now();
      print('Fecha actual: ${now.toIso8601String()}');

      List<DateTime> dates = [];
      List<String> labelsList = [];
      List<BarChartGroupData> groupsList = [];
      int total = 0;

      // Configurar últimos 7 días
      print('Configurando últimos 7 días');
      for (int i = 6; i >= 0; i--) {
        final dayDate = now.subtract(Duration(days: i));
        dates.add(dayDate);
        final dayLabel = _getDayLabel(dayDate);
        labelsList.add(dayLabel);
        print(
            'Día ${6 - i}: ${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')} - Etiqueta: $dayLabel');
      }

      print('=== INICIANDO CONSULTAS ===');

      for (int i = 0; i < dates.length; i++) {
        print('\n--- Consulta ${i + 1} de ${dates.length} ---');
        final count = await _getSolicitudesCount(dates[i]);
        total += count;

        groupsList.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: Color(0xFF10B981), // Verde como en la imagen
                width: 24,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );

        print('Resultado: $count solicitudes para ${labelsList[i]}');
      }

      print('\n=== RESULTADOS FINALES ===');
      print('Total solicitudes en la semana: $total');
      for (int i = 0; i < labelsList.length; i++) {
        print(
            '${labelsList[i]}: ${groupsList[i].barRods[0].toY.toInt()} solicitudes');
      }

      setState(() {
        barGroups = groupsList;
        labels = labelsList;
        totalSolicitudes = total;
        isLoading = false;
      });

      print('=== CARGA COMPLETADA ===');
    } catch (e) {
      print('ERROR EN _loadData: $e');
      setState(() {
        error = 'Error al cargar datos: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<int> _getSolicitudesCount(DateTime date) async {
    try {
      // Usar el mismo formato que funciona en los otros widgets
      DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endDate =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      String fechaBuscada =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      print('  Buscando solicitudes del: $fechaBuscada');
      print(
          '  Rango: ${startDate.toIso8601String()} hasta ${endDate.toIso8601String()}');
      print('  Estados válidos: ${estadosValidos.join(", ")}');

      final response = await SupaFlow.client
          .from('solicitudes_servicio')
          .select('id, estado, fecha')
          .gte('fecha', startDate.toIso8601String())
          .lte('fecha', endDate.toIso8601String());

      print('  Solicitudes encontradas (total): ${response?.length ?? 0}');

      // Filtrar por estados válidos en Dart
      List<dynamic> solicitudesFiltradas = [];
      if (response != null) {
        solicitudesFiltradas = response.where((solicitud) {
          String estado = solicitud['estado'] ?? '';
          return estadosValidos.contains(estado);
        }).toList();
      }

      print('  Solicitudes válidas: ${solicitudesFiltradas.length}');

      if (solicitudesFiltradas.isNotEmpty) {
        print('  Detalles:');
        Map<String, int> conteoEstados = {};
        for (var solicitud in solicitudesFiltradas) {
          String estado = solicitud['estado'] ?? 'sin estado';
          conteoEstados[estado] = (conteoEstados[estado] ?? 0) + 1;
          print(
              '    - Solicitud: ${solicitud['id']} - Estado: $estado - Fecha: ${solicitud['fecha']}');
        }
        conteoEstados.forEach((estado, cantidad) {
          print('    - $estado: $cantidad');
        });
      } else {
        print('  No se encontraron solicitudes válidas para este día');
      }

      return solicitudesFiltradas.length;
    } catch (e) {
      print('ERROR EN _getSolicitudesCount: $e');
      return 0;
    }
  }

  String _getDayLabel(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }

  double _getMaxY() {
    if (barGroups.isEmpty) return 100;
    double maxValue = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxValue) maxValue = rod.toY;
      }
    }
    return (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    double maxY = _getMaxY();
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 25;
    if (maxY <= 200) return 50;
    return (maxY / 4).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Total semanal',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                totalSolicitudes.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
                  )
                : error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 32, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              error,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : barGroups.isEmpty
                        ? Center(
                            child: Text(
                              'No hay datos disponibles',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceEvenly,
                              maxY: _getMaxY(),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final label = labels.length > groupIndex
                                        ? labels[groupIndex]
                                        : 'Día ${groupIndex + 1}';
                                    return BarTooltipItem(
                                      '$label\n${rod.toY.toInt()} solicitudes',
                                      TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0)
                                        return SizedBox.shrink();

                                      final index = value.toInt();
                                      if (index >= 0 && index < labels.length) {
                                        return Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            labels[index],
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      }
                                      return SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _calculateInterval(),
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  left: BorderSide(
                                      color: Colors.grey[300]!, width: 1),
                                  bottom: BorderSide(
                                      color: Colors.grey[300]!, width: 1),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: _calculateInterval(),
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              barGroups: barGroups,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
