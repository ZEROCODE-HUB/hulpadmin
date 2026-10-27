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

class GraficoSolicitudesTendencia extends StatefulWidget {
  const GraficoSolicitudesTendencia({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<GraficoSolicitudesTendencia> createState() =>
      _GraficoSolicitudesTendenciaState();
}

class _GraficoSolicitudesTendenciaState
    extends State<GraficoSolicitudesTendencia> {
  List<FlSpot> spots = [];
  List<String> labels = [];
  bool isLoading = true;
  String error = '';
  double maxValue = 0;

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
      print('=== INICIANDO CARGA SOLICITUDES TENDENCIA ===');

      setState(() {
        isLoading = true;
        error = '';
      });

      final now = DateTime.now();
      print('Fecha actual: ${now.toIso8601String()}');

      List<DateTime> startDates = [];
      List<DateTime> endDates = [];
      List<String> labelsList = [];
      List<FlSpot> spotsList = [];
      double maxVal = 0;

      // Configurar últimos 4 semestres
      print('Configurando últimos 4 semestres');

      // Determinar el año actual y semestre actual
      int currentYear = now.year;
      int currentSemester = now.month <= 6 ? 1 : 2;

      // Generar los últimos 4 semestres hacia atrás
      for (int i = 3; i >= 0; i--) {
        int year = currentYear;
        int semester = currentSemester;

        // Calcular el semestre y año correspondiente
        int totalSemesters = currentSemester + (currentYear * 2);
        int targetSemester = totalSemesters - i;

        year = (targetSemester - 1) ~/ 2;
        semester = ((targetSemester - 1) % 2) + 1;

        DateTime startDate, endDate;
        String label;

        if (semester == 1) {
          // Primer semestre: Enero - Junio
          startDate = DateTime(year, 1, 1, 0, 0, 0);
          endDate = DateTime(year, 6, 30, 23, 59, 59, 999);
          label = 'S1 $year';
        } else {
          // Segundo semestre: Julio - Diciembre
          startDate = DateTime(year, 7, 1, 0, 0, 0);
          endDate = DateTime(year, 12, 31, 23, 59, 59, 999);
          label = 'S2 $year';
        }

        startDates.add(startDate);
        endDates.add(endDate);
        labelsList.add(label);

        print(
            'Semestre ${3 - i}: $label - ${startDate.toIso8601String()} hasta ${endDate.toIso8601String()}');
      }

      print('=== INICIANDO CONSULTAS ===');

      for (int i = 0; i < startDates.length; i++) {
        print('\n--- Consulta ${i + 1} de ${startDates.length} ---');
        final count = await _getSolicitudesCountSemestre(
            startDates[i], endDates[i], labelsList[i]);

        spotsList.add(FlSpot(i.toDouble(), count.toDouble()));
        if (count > maxVal) maxVal = count.toDouble();

        print('Resultado: $count solicitudes para ${labelsList[i]}');
      }

      print('\n=== RESULTADOS FINALES ===');
      print('Valor máximo: $maxVal');
      for (int i = 0; i < labelsList.length; i++) {
        print('${labelsList[i]}: ${spotsList[i].y.toInt()} solicitudes');
      }

      setState(() {
        spots = spotsList;
        labels = labelsList;
        maxValue = maxVal;
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

  Future<int> _getSolicitudesCountSemestre(
      DateTime startDate, DateTime endDate, String semestre) async {
    try {
      print('  Buscando solicitudes del semestre: $semestre');
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
        print('  Detalles por estado:');
        Map<String, int> conteoEstados = {};
        for (var solicitud in solicitudesFiltradas) {
          String estado = solicitud['estado'] ?? 'sin estado';
          conteoEstados[estado] = (conteoEstados[estado] ?? 0) + 1;
        }
        conteoEstados.forEach((estado, cantidad) {
          print('    - $estado: $cantidad');
        });
      }

      return solicitudesFiltradas.length;
    } catch (e) {
      print('ERROR EN _getSolicitudesCountSemestre: $e');
      return 0;
    }
  }

  double _getMaxY() {
    if (spots.isEmpty) return 400;
    return (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    double maxY = _getMaxY();
    if (maxY <= 100) return 25;
    if (maxY <= 200) return 50;
    if (maxY <= 400) return 100;
    if (maxY <= 800) return 200;
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
                'Tendencia semestral',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                maxValue.toInt().toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE11D48), // Rosa/rojo como en la imagen
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE11D48),
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
                    : spots.isEmpty
                        ? Center(
                            child: Text(
                              'No hay datos disponibles',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                drawHorizontalLine: true,
                                horizontalInterval: _calculateInterval(),
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  );
                                },
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
                                              fontSize:
                                                  11, // Más pequeño para acomodar las etiquetas
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
                                    reservedSize: 50,
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
                              minX: 0,
                              maxX: (labels.length - 1).toDouble(),
                              minY: 0,
                              maxY: _getMaxY(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Color(
                                      0xFFE11D48), // Rosa/rojo como en la imagen
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: Color(0xFFE11D48),
                                        strokeWidth: 0,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Color(0xFFE11D48).withOpacity(0.1),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      final index = touchedSpot.spotIndex;
                                      final value = touchedSpot.y.toInt();
                                      final label = index < labels.length
                                          ? labels[index]
                                          : 'Semestre ${index + 1}';

                                      return LineTooltipItem(
                                        '$label\n$value solicitudes',
                                        TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
