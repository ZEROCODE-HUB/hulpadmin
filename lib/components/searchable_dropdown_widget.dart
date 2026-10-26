import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/dialog_helpers.dart';

/// Dropdown con búsqueda integrada. Se abre como un dialog al tocar.
/// Visualmente idéntico a un TextFormField del formulario.
class SearchableDropdown extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.values,
    required this.labels,
    this.selectedValue,
    required this.onChanged,
    required this.hint,
    this.searchHint = 'Buscar...',
    this.searchTexts,
    this.details,
  }) : assert(values.length == labels.length),
        assert(searchTexts == null || values.length == searchTexts.length),
        assert(details == null || values.length == details.length);

  final List<String> values;
  final List<String> labels;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String hint;
  final String searchHint;
  final List<String>? searchTexts;
  final List<String>? details;

  String? get _selectedLabel {
    if (selectedValue == null || selectedValue!.isEmpty) return null;
    final idx = values.indexOf(selectedValue!);
    return idx >= 0 ? labels[idx] : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = _selectedLabel;
    return InkWell(
      onTap: () => _openDialog(context),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 13.0, 12.0, 13.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: theme.alternate, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label ?? hint,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: label != null ? theme.primaryText : const Color(0xFF8A8A8A),
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: theme.secondaryText, size: 24.0),
          ],
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final result = await showMapSafeDialog<String>(
      context: context,
      builder: (_) => _SearchDropdownDialog(
        values: values,
        labels: labels,
        selectedValue: selectedValue,
        searchHint: searchHint,
        searchTexts: searchTexts,
        details: details,
      ),
    );
    if (result != null) onChanged(result.isEmpty ? null : result);
  }
}

class _SearchDropdownDialog extends StatefulWidget {
  const _SearchDropdownDialog({
    required this.values,
    required this.labels,
    this.selectedValue,
    required this.searchHint,
    this.searchTexts,
    this.details,
  });

  final List<String> values;
  final List<String> labels;
  final String? selectedValue;
  final String searchHint;
  final List<String>? searchTexts;
  final List<String>? details;

  @override
  State<_SearchDropdownDialog> createState() => _SearchDropdownDialogState();
}

class _SearchDropdownDialogState extends State<_SearchDropdownDialog> {
  late final TextEditingController _ctrl;
  late List<int> _indices;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _indices = List.generate(widget.labels.length, (i) => i);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final normalizedQuery = _normalizeText(q);
    final digitQuery = _onlyDigits(q);
    setState(() {
      _indices = List.generate(widget.labels.length, (i) => i)
          .where((i) {
            final searchableText = widget.searchTexts?[i] ?? widget.labels[i];
            if (_normalizeText(searchableText).contains(normalizedQuery)) {
              return true;
            }
            return digitQuery.isNotEmpty &&
                _onlyDigits(searchableText).contains(digitQuery);
          })
          .toList();
    });
  }

  String _normalizeText(String value) => value.trim().toLowerCase();

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Dialog(
      backgroundColor: theme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480.0,
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _filter,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.searchHint,
                        hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF8A8A8A), fontSize: 15.0),
                        prefixIcon: Icon(Icons.search,
                            size: 20.0, color: theme.secondaryText),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.alternate, width: 0.5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.primary, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFBFAF9),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 10.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20.0, color: theme.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: theme.alternate),
            // Lista filtrada
            Flexible(
              child: _indices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Sin resultados',
                        style: GoogleFonts.inter(
                            color: theme.secondaryText, fontSize: 14.0),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _indices.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.3,
                          indent: 16,
                          color: theme.alternate),
                      itemBuilder: (_, i) {
                        final idx = _indices[i];
                        final isSelected =
                            widget.values[idx] == widget.selectedValue;
                        final detail = widget.details?[idx].trim() ?? '';
                        return InkWell(
                          onTap: () =>
                              Navigator.pop(context, widget.values[idx]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 14.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.labels[idx],
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? theme.primary
                                              : theme.primaryText,
                                          fontSize: 15.0,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (detail.isNotEmpty) ...[
                                        const SizedBox(height: 3.0),
                                        Text(
                                          detail,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: theme.secondaryText,
                                            fontSize: 13.0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: theme.primary, size: 18.0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
