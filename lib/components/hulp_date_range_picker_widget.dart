import '/components/modal_con_encabezado_fijo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class HulpDateRangePickerWidget extends StatelessWidget {
  const HulpDateRangePickerWidget({
    super.key,
    this.dateStart,
    this.dateEnd,
    required this.onDateRangeSelected,
    required this.onReset,
    this.placeholder = 'Rango de fecha',
    this.firstDate,
    this.lastDate,
    this.expandido = false,
  });

  final DateTime? dateStart;
  final DateTime? dateEnd;
  final void Function(DateTime start, DateTime end) onDateRangeSelected;
  final VoidCallback onReset;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool expandido;

  bool get _hasSelection => dateStart != null && dateEnd != null;

  String get _displayText {
    if (!_hasSelection) return placeholder;
    return '${dateTimeFormat("d/M/y", dateStart)} - ${dateTimeFormat("d/M/y", dateEnd)}';
  }

  Future<void> _openPicker(BuildContext context) async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => _HulpRangePickerDialog(
        initialStart: dateStart,
        initialEnd: dateEnd,
        firstDate: firstDate ?? DateTime(2024),
        lastDate: lastDate ?? DateTime(2050),
      ),
    );

    if (picked != null) {
      onDateRangeSelected(
        DateTime(picked.start.year, picked.start.month, picked.start.day),
        DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boton = InkWell(
      borderRadius: BorderRadius.circular(8.0),
      splashColor: Colors.transparent,
      hoverColor: FlutterFlowTheme.of(context).primary.withOpacity(0.04),
      onTap: () => _openPicker(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _hasSelection
                ? FlutterFlowTheme.of(context).primary
                : const Color(0xFFDFDFDF),
            width: _hasSelection ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: FlutterFlowTheme.of(context).primary,
                size: 18.0,
              ),
              Flexible(
                  child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                child: Text(
                  _displayText,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: _hasSelection
                            ? FlutterFlowTheme.of(context).primaryText
                            : FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (expandido) Expanded(child: boton) else boton,
        if (_hasSelection)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
            child: IconButton(
              tooltip: 'Limpiar fechas',
              onPressed: onReset,
              icon: const Icon(
                Icons.close,
                color: Color(0xFFE20E0E),
                size: 24.0,
              ),
            ),
          ),
      ],
    );
  }
}

// --- Compact range picker dialog --------------------------------------------

class _HulpRangePickerDialog extends StatefulWidget {
  const _HulpRangePickerDialog({
    this.initialStart,
    this.initialEnd,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_HulpRangePickerDialog> createState() => _HulpRangePickerDialogState();
}

class _HulpRangePickerDialogState extends State<_HulpRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _focusedMonth = DateTime(
      (_start ?? DateTime.now()).year,
      (_start ?? DateTime.now()).month,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) {
    if (_start == null || _end == null) return false;
    return !d.isBefore(_start!) && !d.isAfter(_end!);
  }

  void _onDayTap(DateTime d) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = d;
        _end = null;
      } else if (d.isBefore(_start!)) {
        _end = _start;
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  String get _monthLabel {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}';
  }

  String get _rangeLabel {
    if (_start != null && _end != null) {
      return '${dateTimeFormat("d MMM", _start)} - ${dateTimeFormat("d MMM y", _end)}';
    }
    if (_start != null) {
      return '${dateTimeFormat("d MMM y", _start)} - ...';
    }
    return 'Selecciona un rango';
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding: const EdgeInsets.all(24.0),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20.0),
        child: ModalConEncabezadoFijo(
          encabezado: Row(
            children: [
              Icon(Icons.date_range_rounded, color: primary, size: 22.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Rango de fechas',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                icon: const Icon(Icons.close, size: 20.0),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          cuerpo: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8.0),
              Text(
                _rangeLabel,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(),
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                    ),
              ),
              const SizedBox(height: 12.0),
              const Divider(height: 1.0),
              const SizedBox(height: 12.0),
              // Month nav
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: primary,
                    onPressed: _prevMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _monthLabel,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: primary,
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              // Weekday headers
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8.0),
              // Calendar grid
              _buildCalendarGrid(context, primary),
              const SizedBox(height: 16.0),
              // Actions
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _start = null;
                        _end = null;
                      });
                    },
                    child: Text('Limpiar',
                        style: TextStyle(
                            color: FlutterFlowTheme.of(context).error)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: (_start != null && _end != null)
                        ? () => Navigator.of(context)
                            .pop(DateTimeRange(start: _start!, end: _end!))
                        : null,
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, Color primary) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday = 1 ... Sunday = 7. We want Monday as first column.
    final leadingEmpty = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIdx) {
        return Row(
          children: List.generate(7, (colIdx) {
            final cellIdx = rowIdx * 7 + colIdx;
            final dayNum = cellIdx - leadingEmpty + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 36.0));
            }
            final date =
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            return Expanded(
              child: _buildDayCell(context, date, primary),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, Color primary) {
    final isStart = _start != null && _isSameDay(date, _start!);
    final isEnd = _end != null && _isSameDay(date, _end!);
    final inRange = _inRange(date);
    final isEdge = isStart || isEnd;
    final inRangeOnly = inRange && !isEdge;
    final isDisabled =
        date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

    final textColor = isDisabled
        ? FlutterFlowTheme.of(context).alternate
        : isEdge
            ? Colors.white
            : inRangeOnly
                ? primary
                : FlutterFlowTheme.of(context).primaryText;

    return InkWell(
      onTap: isDisabled ? null : () => _onDayTap(date),
      child: Container(
        height: 36.0,
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: isEdge
              ? primary
              : inRangeOnly
                  ? primary.withOpacity(0.12)
                  : null,
          borderRadius: isStart && (_end == null || isEnd)
              ? BorderRadius.circular(18.0)
              : isStart
                  ? const BorderRadius.horizontal(left: Radius.circular(18.0))
                  : isEnd
                      ? const BorderRadius.horizontal(
                          right: Radius.circular(18.0))
                      : inRangeOnly
                          ? BorderRadius.zero
                          : BorderRadius.circular(18.0),
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                    fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500),
                color: textColor,
                fontSize: 14.0,
                fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
