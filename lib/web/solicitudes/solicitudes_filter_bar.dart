import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/hulp_date_range_picker_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;

String _normKey(String? value) {
  var text = value?.trim().toLowerCase() ?? '';
  for (final pair in const [
    ['á', 'a'],
    ['é', 'e'],
    ['í', 'i'],
    ['ó', 'o'],
    ['ú', 'u'],
    ['ü', 'u'],
    ['ñ', 'n'],
  ]) {
    text = text.replaceAll(pair[0], pair[1]);
  }
  return text;
}

String? _resolveMenuValue(String? selected, List<String> options) {
  if (selected == null || selected.trim().isEmpty) return '';
  if (options.contains(selected)) return selected;
  final key = _normKey(selected);
  for (final option in options) {
    if (_normKey(option) == key) return option;
  }
  return '';
}

class SolicitudesFilterBar extends StatelessWidget {
  const SolicitudesFilterBar({
    super.key,
    required this.estadoOptions,
    required this.servicioOptions,
    required this.ciudadOptions,
    required this.dropDownValue1,
    required this.dropDownValue2,
    required this.dropDownValue3,
    required this.dateStart,
    required this.dateEnd,
    required this.resultCount,
    required this.onEstadoChanged,
    required this.onServicioChanged,
    required this.onCiudadChanged,
    required this.onDateRangeSelected,
    required this.onDateReset,
  });

  final List<String> estadoOptions;
  final List<String> servicioOptions;
  final List<String> ciudadOptions;
  final String? dropDownValue1;
  final String? dropDownValue2;
  final String? dropDownValue3;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final int resultCount;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<String?> onServicioChanged;
  final ValueChanged<String?> onCiudadChanged;
  final void Function(DateTime start, DateTime end) onDateRangeSelected;
  final VoidCallback onDateReset;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = FlutterFlowTheme.of(context).bodyMedium.override(
          font: GoogleFonts.inter(),
          fontSize: 15.0,
          letterSpacing: 0.0,
        );
    final countStyle = bodyStyle.copyWith(color: const Color(0xFF0B6244));
    final counter = Text.rich(
      TextSpan(children: [
        const TextSpan(text: 'Número de solicitudes: '),
        TextSpan(
          text: resultCount.toString(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ]),
      style: countStyle,
      maxLines: 1,
      softWrap: false,
    );

    Widget estado() => _buildDropdown(
          context,
          title: 'Estado',
          options: estadoOptions,
          selected: dropDownValue1,
          onChanged: onEstadoChanged,
          bodyStyle: bodyStyle,
          optionLabels: _estadoLabels(estadoOptions),
          allLabel: 'Todos',
        );
    Widget servicio() => _buildDropdown(
          context,
          title: 'Servicio',
          options: servicioOptions,
          selected: dropDownValue2,
          onChanged: onServicioChanged,
          bodyStyle: bodyStyle,
          allLabel: 'Todos',
        );
    Widget ciudad() => _buildDropdown(
          context,
          title: 'Ciudad',
          options: ciudadOptions,
          selected: dropDownValue3,
          onChanged: onCiudadChanged,
          bodyStyle: bodyStyle,
          allLabel: 'Todas',
        );
    Widget fecha() => HulpDateRangePickerWidget(
          expandido: true,
          showDropdownIcon: true,
          dateStart: dateStart,
          dateEnd: dateEnd,
          onDateRangeSelected: onDateRangeSelected,
          onReset: onDateReset,
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x7C766C4D), width: 0.7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: LayoutBuilder(builder: (context, size) {
        if (size.maxWidth >= 720) {
          return Row(children: [
            Text(
              'Filtrar:',
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 19, child: estado()),
            const SizedBox(width: 8),
            Expanded(flex: 21, child: servicio()),
            const SizedBox(width: 8),
            Expanded(flex: 19, child: ciudad()),
            const SizedBox(width: 8),
            Expanded(flex: 22, child: fecha()),
            const SizedBox(width: 12),
            counter,
          ]);
        }

        final twoColumns = size.maxWidth >= 620;
        final fieldWidth =
            twoColumns ? (size.maxWidth - 12) / 2 : size.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text(
                  'Filtrar:',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                counter,
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: fieldWidth, child: estado()),
                SizedBox(width: fieldWidth, child: servicio()),
                SizedBox(width: fieldWidth, child: ciudad()),
                SizedBox(width: fieldWidth, child: fecha()),
              ],
            ),
          ],
        );
      }),
    );
  }

  Map<String, String> _estadoLabels(List<String> options) {
    if (options.isEmpty) return const {};
    final labels = functions.getStatus(options);
    return {
      for (var index = 0; index < options.length; index++)
        options[index]: labels[index],
    };
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
    required TextStyle bodyStyle,
    required String allLabel,
    Map<String, String> optionLabels = const {},
  }) {
    final selectedValue = _resolveMenuValue(selected, options);
    final fullOptions = ['', ...options];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 5, 0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              itemHeight: null,
              value: selectedValue,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 23,
              ),
              style: bodyStyle,
              selectedItemBuilder: (context) => [
                _selectedLabel('$title: $allLabel', bodyStyle),
                for (final option in options)
                  _selectedLabel(
                    '$title: ${optionLabels[option] ?? option}',
                    bodyStyle,
                  ),
              ],
              items: fullOptions
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option.isEmpty
                              ? allLabel
                              : (optionLabels[option] ?? option),
                          style: bodyStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) => onChanged(value == '' ? null : value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedLabel(String text, TextStyle style) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
}
