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

/// d'
class GraficoSolicitudesPagadasSemanal extends StatefulWidget {
  const GraficoSolicitudesPagadasSemanal({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<GraficoSolicitudesPagadasSemanal> createState() =>
      _GraficoSolicitudesPagadasSemanalState();
}

class _GraficoSolicitudesPagadasSemanalState
    extends State<GraficoSolicitudesPagadasSemanal> {
  List<BarChartGroupData> barGroups = [];
  List<String> labels = [];
  List<double> ingresosPorDia = [];
  bool isLoading = true;
  String error = '';
  int totalSolicitudes = 0;
  double totalIngresos = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('=== INICIANDO CARGA SOLICITUDES PAGADAS SEMANAL ===');

      setState(() {
        isLoading = true;
        error = '';
      });

      final now = DateTime.now();
      print('Fecha actual: ${now.toIso8601String()}');

      // Calcular el lunes de la semana actual
      final monday = _getMonday(now);
      print('Lunes de la semana actual: ${monday.toIso8601String()}');

      List<DateTime> dates = [];
      List<String> labelsList = [];
      List<BarChartGroupData> groupsList = [];
      List<double> ingresosLista = [];
      int total = 0;

      // Configurar días de lunes a domingo de la semana actual
      print('Configurando días de lunes a domingo');
      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        dates.add(dayDate);
        final dayLabel = _getDayLabel(dayDate);
        labelsList.add(dayLabel);
        print(
            'Día ${i + 1}: ${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')} - Etiqueta: $dayLabel');
      }

      print('=== INICIANDO CONSULTAS ===');

      for (int i = 0; i < dates.length; i++) {
        print('\n--- Consulta ${i + 1} de ${dates.length} ---');
        final result = await _getSolicitudesData(dates[i]);
        final count = result['count'] as int;
        final ingresos = result['ingresos'] as double;

        total += count;
        totalIngresos += ingresos;
        ingresosLista.add(ingresos);

        groupsList.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: ingresos, // Usar ingresos en lugar de cantidad
                color: Color(0xFF10B981), // Verde como en la imagen
                width: 32,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );

        print(
            'Resultado: $count solicitudes, ingresos: ${ingresos.toStringAsFixed(2)} para ${labelsList[i]}');
      }

      print('\n=== RESULTADOS FINALES ===');
      print('Total solicitudes pagadas en la semana: $total');
      print('Total ingresos en la semana: ${totalIngresos.toStringAsFixed(2)}');
      for (int i = 0; i < labelsList.length; i++) {
        print(
            '${labelsList[i]}: ${groupsList[i].barRods[0].toY.toStringAsFixed(2)} ingresos');
      }

      setState(() {
        barGroups = groupsList;
        labels = labelsList;
        ingresosPorDia = ingresosLista;
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

  DateTime _getMonday(DateTime date) {
    // Obtener el lunes de la semana actual
    int dayOfWeek = date.weekday; // 1 = lunes, 7 = domingo
    DateTime monday = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<Map<String, dynamic>> _getSolicitudesData(DateTime date) async {
    try {
      DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endDate =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      String fechaBuscada =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      print('  Buscando solicitudes pagadas del: $fechaBuscada');
      print(
          '  Rango: ${startDate.toIso8601String()} hasta ${endDate.toIso8601String()}');

      final response = await SupaFlow.client
          .from('solicitudes_servicio')
          .select('id, estado_pago, creado_en, precio')
          .eq('estado_pago', 'pagado')
          .gte('creado_en', startDate.toIso8601String())
          .lte('creado_en', endDate.toIso8601String());

      print('  Solicitudes pagadas encontradas: ${response?.length ?? 0}');

      double totalIngresosDia = 0;
      if (response != null && response.isNotEmpty) {
        print('  Detalles:');
        for (var solicitud in response) {
          double precio = 0;
          try {
            precio = (solicitud['precio'] ?? 0).toDouble();
            totalIngresosDia += precio;
          } catch (e) {
            print(
                '    - Error al convertir precio: ${solicitud['precio']} - $e');
          }
          print(
              '    - Solicitud: ${solicitud['id']} - Precio: $precio - Creado en: ${solicitud['creado_en']}');
        }
        print(
            '  Total ingresos del día: ${totalIngresosDia.toStringAsFixed(2)}');
      } else {
        print('  No se encontraron solicitudes pagadas para este día');
      }

      return {
        'count': response?.length ?? 0,
        'ingresos': totalIngresosDia,
      };
    } catch (e) {
      print('ERROR EN _getSolicitudesData: $e');
      return {
        'count': 0,
        'ingresos': 0.0,
      };
    }
  }

  String _getDayLabel(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }

  double _getMaxY() {
    if (barGroups.isEmpty) return 1000;
    double maxValue = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxValue) maxValue = rod.toY;
      }
    }
    // Asegurar que el máximo permita ver bien los datos
    return maxValue < 1000 ? 1000 : (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    double maxY = _getMaxY();
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    if (maxY <= 50000) return 10000;
    if (maxY <= 100000) return 20000;
    return (maxY / 5).ceilToDouble();
  }

  String _formatCurrency(double amount) {
    // Formato de moneda boliviana
    if (amount >= 1000000) {
      return 'S${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (amount >= 1000) {
      return 'S${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return 'S${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                _formatCurrency(totalIngresos),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
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
                                color: Color(0xFF9CA3AF),
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
                                      '$label\n${_formatCurrency(rod.toY)}',
                                      TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                                    reservedSize: 32,
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
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
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
                                      if (value % _calculateInterval() != 0)
                                        return SizedBox.shrink();

                                      int intValue = value.toInt();
                                      String label;

                                      if (intValue >= 1000000) {
                                        label = (intValue / 1000000)
                                                .toStringAsFixed(0) +
                                            'M';
                                      } else if (intValue >= 1000) {
                                        label = (intValue / 1000)
                                                .toStringAsFixed(0) +
                                            'K';
                                      } else {
                                        label = intValue.toString();
                                      }

                                      return Text(
                                        label,
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: _calculateInterval(),
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Color(0xFFF3F4F6),
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
