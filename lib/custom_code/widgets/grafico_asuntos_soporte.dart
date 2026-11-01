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

class GraficoAsuntosSoporte extends StatefulWidget {
  const GraficoAsuntosSoporte({
    super.key,
    this.width,
    this.height,
    required this.rango,
  });

  final double? width;
  final double? height;
  final String rango; // "semanal", "mensual", "anual"

  @override
  State<GraficoAsuntosSoporte> createState() => _GraficoAsuntosSoporteState();
}

class _GraficoAsuntosSoporteState extends State<GraficoAsuntosSoporte> {
  List<BarChartGroupData> barGroups = [];
  List<String> labels = [];
  List<int> valores = [];
  bool isLoading = true;
  String error = '';
  int totalTickets = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('=== INICIANDO CARGA ASUNTOS SOPORTE ===');
      print('Rango: ${widget.rango}');

      setState(() {
        isLoading = true;
        error = '';
      });

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      // Configurar fechas según el rango
      switch (widget.rango.toLowerCase()) {
        case 'semanal':
          startDate = now.subtract(Duration(days: 6));
          startDate =
              DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          print('Rango semanal: últimos 7 días');
          break;
        case 'mensual':
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          endDate = DateTime(now.year, now.month + 1, 1, 0, 0, 0)
              .subtract(Duration(milliseconds: 1));
          print('Rango mensual: mes actual completo');
          break;
        case 'anual':
          startDate = DateTime(now.year, 1, 1, 0, 0, 0);
          endDate = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          print('Rango anual: año actual completo');
          break;
        default:
          throw Exception('Rango no válido: ${widget.rango}');
      }

      print('Fecha inicio: ${startDate.toIso8601String()}');
      print('Fecha fin: ${endDate.toIso8601String()}');

      // Consultar tickets de soporte
      final response = await SupaFlow.client
          .from('soporte')
          .select('id, asunto, fecha_hora, estado')
          .gte('fecha_hora', startDate.toIso8601String())
          .lte('fecha_hora', endDate.toIso8601String())
          .order('fecha_hora', ascending: false);

      print('Tickets encontrados: ${response?.length ?? 0}');

      if (response == null || response.isEmpty) {
        setState(() {
          barGroups = [];
          labels = [];
          valores = [];
          totalTickets = 0;
          isLoading = false;
        });
        print('No se encontraron tickets en el rango especificado');
        return;
      }

      // Agrupar por asunto y contar frecuencias
      Map<String, int> asuntosCount = {};

      for (var ticket in response) {
        String asunto = ticket['asunto']?.toString().trim() ?? 'Sin asunto';

        // Limitar longitud del asunto para mejor visualización
        if (asunto.length > 25) {
          asunto = asunto.substring(0, 22) + '...';
        }

        asuntosCount[asunto] = (asuntosCount[asunto] ?? 0) + 1;
        print(
            'Ticket: ${ticket['id']} - Asunto: $asunto - Fecha: ${ticket['fecha_hora']} - Estado: ${ticket['estado']}');
      }

      // Ordenar por frecuencia (mayor a menor) y tomar los top 8
      var sortedAsuntos = asuntosCount.entries.toList();
      sortedAsuntos.sort((a, b) => b.value.compareTo(a.value));

      // Tomar máximo 8 asuntos para mejor visualización
      var topAsuntos = sortedAsuntos.take(8).toList();

      List<String> labelsList = [];
      List<int> valoresList = [];
      List<BarChartGroupData> groupsList = [];
      int total = response.length;

      for (int i = 0; i < topAsuntos.length; i++) {
        var entry = topAsuntos[i];
        labelsList.add(entry.key);
        valoresList.add(entry.value);

        groupsList.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Color(0xFF10B981), // Verde como en la imagen
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );

        print('${entry.key}: ${entry.value} tickets');
      }

      print('\n=== RESULTADOS FINALES ===');
      print('Total tickets de soporte: $total');
      print('Asuntos únicos: ${asuntosCount.length}');
      print('Top asuntos mostrados: ${topAsuntos.length}');

      setState(() {
        barGroups = groupsList;
        labels = labelsList;
        valores = valoresList;
        totalTickets = total;
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

  double _getMaxY() {
    if (barGroups.isEmpty) return 10;
    double maxValue = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxValue) maxValue = rod.toY;
      }
    }
    return maxValue < 10 ? 10 : (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    double maxY = _getMaxY();

    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;

    return (maxY / 5).ceilToDouble();
  }

  String _getTitleByRange() {
    switch (widget.rango.toLowerCase()) {
      case 'semanal':
        return 'Total semanal';
      case 'mensual':
        return 'Total mensual';
      case 'anual':
        return 'Total anual';
      default:
        return 'Total';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 400,
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
                _getTitleByRange(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                totalTickets.toString(),
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
                        : _buildHorizontalBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular dimensiones
        final totalHeight = constraints.maxHeight;
        final numberOfItems = labels.length;

        // Altura mínima por item para evitar que se apeguen
        final minItemHeight = 35.0;
        final maxItemHeight = 60.0;

        // Calcular altura óptima por item
        double itemHeight =
            (totalHeight - 40) / numberOfItems; // -40 para padding
        itemHeight = itemHeight.clamp(minItemHeight, maxItemHeight);

        // Espacio entre items
        final spacing = (totalHeight - 40 - (itemHeight * numberOfItems)) /
            (numberOfItems + 1);
        final finalSpacing = spacing.clamp(8.0, 20.0);

        return SingleChildScrollView(
          child: Container(
            height: (itemHeight * numberOfItems) +
                (finalSpacing * (numberOfItems + 1)),
            child: Column(
              children: [
                SizedBox(height: finalSpacing),
                ...List.generate(numberOfItems, (index) {
                  return Column(
                    children: [
                      Container(
                        height: itemHeight,
                        child: Row(
                          children: [
                            // Etiqueta (lado izquierdo)
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: EdgeInsets.only(right: 12),
                                child: Text(
                                  labels[index],
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Barra (centro)
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 20,
                                child: Stack(
                                  children: [
                                    // Fondo de la barra
                                    Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    // Barra de progreso
                                    Container(
                                      height: 20,
                                      width: (valores[index] / _getMaxY()) *
                                          (constraints.maxWidth *
                                              0.4), // 40% del ancho disponible
                                      decoration: BoxDecoration(
                                        color: Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Valor (lado derecho)
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  valores[index].toString(),
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < numberOfItems - 1)
                        SizedBox(height: finalSpacing),
                    ],
                  );
                }),
                SizedBox(height: finalSpacing),
              ],
            ),
          ),
        );
      },
    );
  }
}
