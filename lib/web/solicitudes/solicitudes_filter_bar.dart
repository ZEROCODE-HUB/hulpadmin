import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/hulp_date_range_picker_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;

String _normKey(String? s) {
  var t = s?.trim() ?? '';
  if (t.isEmpty) return '';
  t = t.toLowerCase();
  for (final p in const [
    ['á', 'a'],
    ['é', 'e'],
    ['í', 'i'],
    ['ó', 'o'],
    ['ú', 'u'],
    ['ü', 'u'],
    ['ñ', 'n'],
  ]) {
    t = t.replaceAll(p[0], p[1]);
  }
  return t;
}

/// Valor que entiende [DropdownButtonFormField]: debe coincidir con un [DropdownMenuItem.value].
String? _resolveMenuValue(String? selected, List<String> options) {
  if (selected == null || selected.trim().isEmpty) return null;
  if (options.contains(selected)) return selected;
  final key = _normKey(selected);
  for (final o in options) {
    if (_normKey(o) == key) return o;
  }
  return null;
}

class SolicitudesFilterBar extends StatelessWidget {
  const SolicitudesFilterBar({
    super.key,
    required this.estadoOptions,
    required this.categoriaOptions,
    required this.dropDownValue1,
    required this.dropDownValue2,
    required this.dateStart,
    required this.dateEnd,
    required this.resultCount,
    required this.onEstadoChanged,
    required this.onCategoriaChanged,
    required this.onEstadoReset,
    required this.onCategoriaReset,
    required this.onDateRangeSelected,
    required this.onDateReset,
  });

  final List<String> estadoOptions;
  final List<String> categoriaOptions;
  final String? dropDownValue1;
  final String? dropDownValue2;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final int resultCount;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final VoidCallback onEstadoReset;
  final VoidCallback onCategoriaReset;
  final void Function(DateTime start, DateTime end) onDateRangeSelected;
  final VoidCallback onDateReset;

  bool get _hasEstado => dropDownValue1 != null && dropDownValue1 != '';
  bool get _hasCategoria => dropDownValue2 != null && dropDownValue2 != '';

  @override
  Widget build(BuildContext context) {
    final bodyStyle = FlutterFlowTheme.of(context).bodyMedium.override(
          font: GoogleFonts.inter(),
          fontSize: 16.0,
          letterSpacing: 0.0,
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7C766C4D), width: 0.5),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(builder: (context, size) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final label = Text('Filtrar por:', style: bodyStyle);
        final counter = Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Numero de solicitudes: '),
              TextSpan(
                  text: resultCount.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 20)),
            ]),
            style: bodyStyle.copyWith(color: const Color(0xFF0B6244)));
        Widget estado(double width) => SizedBox(
            width: width,
            child: Row(children: [
              Expanded(child: _buildEstadoDropdown(context, bodyStyle)),
              if (_hasEstado)
                _buildResetButton(onEstadoReset, 'Limpiar estado'),
            ]));
        Widget categoria(double width) => SizedBox(
            width: width,
            child: Row(children: [
              Expanded(child: _buildCategoriaDropdown(context, bodyStyle)),
              if (_hasCategoria)
                _buildResetButton(onCategoriaReset, 'Limpiar categoría'),
            ]));
        Widget fecha(double width) => SizedBox(
            width: width,
            child: HulpDateRangePickerWidget(
                expandido: true,
                dateStart: dateStart,
                dateEnd: dateEnd,
                onDateRangeSelected: onDateRangeSelected,
                onReset: onDateReset));

        if (size.maxWidth < 750) {
          final twoColumns =
              size.maxWidth >= 292 * scale.clamp(1, double.infinity);
          final fieldWidth =
              twoColumns ? (size.maxWidth - 12) / 2 : size.maxWidth;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: label),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  estado(fieldWidth),
                  categoria(fieldWidth),
                ]),
                const SizedBox(height: 12),
                Center(child: fecha(size.maxWidth.clamp(0, 320))),
                const SizedBox(height: 12),
                Center(child: counter),
              ]);
        }
        double anchoTexto(InlineSpan text) {
          final painter = TextPainter(
            text: text,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final estadoWidth = 200.0 + (_hasEstado ? 48 : 0);
        final categoriaWidth = 200.0 + (_hasCategoria ? 48 : 0);
        final fechaWidth = dateStart != null && dateEnd != null ? 320.0 : 200.0;
        final singleRowWidth = estadoWidth +
            categoriaWidth +
            fechaWidth +
            52 +
            anchoTexto(TextSpan(text: 'Filtrar por:', style: bodyStyle)) +
            anchoTexto(
                TextSpan(style: counter.style, children: [counter.textSpan!]));
        if (size.maxWidth >= singleRowWidth) {
          return Row(children: [
            label,
            const SizedBox(width: 12),
            estado(estadoWidth),
            const SizedBox(width: 12),
            categoria(categoriaWidth),
            const SizedBox(width: 12),
            fecha(fechaWidth),
            const SizedBox(width: 16),
            const Spacer(),
            counter,
          ]);
        }
        // Keep all three filters together; move the label and count above them.
        final maxFieldWidth = (size.maxWidth - fechaWidth - 24) / 2;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [label, counter]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                estado(estadoWidth.clamp(0.0, maxFieldWidth)),
                const SizedBox(width: 12),
                categoria(categoriaWidth.clamp(0.0, maxFieldWidth)),
                const SizedBox(width: 12),
                fecha(fechaWidth),
              ]),
            ]);
      }),
    );
  }

  Widget _buildEstadoDropdown(BuildContext context, TextStyle bodyStyle) {
    final opts = List<String>.from(estadoOptions);
    final labels = functions.getStatus(opts);
    final labelFor = <String, String>{
      for (var i = 0; i < opts.length; i++) opts[i]: labels[i],
    };
    final selected = _resolveMenuValue(dropDownValue1, opts);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFDFDFDF), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 4.0, 0.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              itemHeight: null,
              value: opts.isEmpty ? null : selected,
              hint: Text('Estado', style: bodyStyle),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 24.0),
              style: bodyStyle,
              items: opts
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        labelFor[e] ?? e,
                        style: bodyStyle,
                        softWrap: true,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: opts.isEmpty ? null : onEstadoChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaDropdown(BuildContext context, TextStyle bodyStyle) {
    final opts = List<String>.from(categoriaOptions);
    final selected = _resolveMenuValue(dropDownValue2, opts);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFDFDFDF), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 4.0, 0.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              itemHeight: null,
              value: opts.isEmpty ? null : selected,
              hint: Text('Categoria', style: bodyStyle),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 24.0),
              style: bodyStyle,
              items: opts
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: bodyStyle,
                        softWrap: true,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: opts.isEmpty ? null : onCategoriaChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(VoidCallback onTap, String tooltip) {
    return IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: const Icon(Icons.close, color: Color(0xFFE20E0E), size: 24));
  }
}
