import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Parses the only supported manual-entry format: `h:mmam` or `h:mmpm`.
DateTime? parseHoraSolicitud(String value) {
  final match = RegExp(r'^([1-9]|1[0-2]):([0-5][0-9])(am|pm)$')
      .firstMatch(value);
  if (match == null) return null;

  final hour12 = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final isPm = match.group(3) == 'pm';
  final hour24 = (hour12 % 12) + (isPm ? 12 : 0);
  return DateTime(1970, 1, 1, hour24, minute);
}

String formatHoraSolicitud(DateTime? time) {
  if (time == null) return '';
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour < 12 ? 'am' : 'pm';
  return '$hour12:$minute$suffix';
}

class FechaHoraSolicitudWidget extends StatefulWidget {
  const FechaHoraSolicitudWidget({
    super.key,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.showInstructions = true,
    this.timeLabel = '2 · Escribir la hora',
    this.initialDate,
    this.initialTime,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? initialDate;
  final DateTime? initialTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<DateTime?> onTimeChanged;
  final bool showInstructions;
  final String timeLabel;

  @override
  State<FechaHoraSolicitudWidget> createState() =>
      FechaHoraSolicitudWidgetState();
}

class FechaHoraSolicitudWidgetState extends State<FechaHoraSolicitudWidget> {
  static const _months = [
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
  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  late final TextEditingController _timeController;
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  bool _showValidationErrors = false;
  String? _timeError;

  DateTime get _firstDate =>
      DateUtils.dateOnly(widget.firstDate ?? DateTime(1900));
  DateTime get _lastDate =>
      DateUtils.dateOnly(widget.lastDate ?? DateTime(2050));

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate == null
        ? null
        : DateUtils.dateOnly(widget.initialDate!);
    final initialMonth = _selectedDate ?? DateTime.now();
    _visibleMonth = DateTime(initialMonth.year, initialMonth.month);
    _timeController = TextEditingController(
      text: formatHoraSolicitud(widget.initialTime),
    );
  }

  @override
  void didUpdateWidget(covariant FechaHoraSolicitudWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDate = oldWidget.initialDate == null
        ? null
        : DateUtils.dateOnly(oldWidget.initialDate!);
    final newDate = widget.initialDate == null
        ? null
        : DateUtils.dateOnly(widget.initialDate!);
    if (oldDate != newDate) {
      _selectedDate = newDate;
      if (newDate != null) {
        _visibleMonth = DateTime(newDate.year, newDate.month);
      }
    }

    final oldTime = oldWidget.initialTime;
    final newTime = widget.initialTime;
    if (oldTime?.hour != newTime?.hour || oldTime?.minute != newTime?.minute) {
      final formatted = formatHoraSolicitud(newTime);
      _timeController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      _timeError = null;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  bool validate() {
    final parsedTime = parseHoraSolicitud(_timeController.text);
    setState(() {
      _showValidationErrors = true;
      _timeError = parsedTime == null ? 'Use el formato 9:30am.' : null;
    });
    return _selectedDate != null && parsedTime != null;
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final monthStart = DateTime(nextMonth.year, nextMonth.month);
    final monthEnd = DateTime(nextMonth.year, nextMonth.month + 1, 0);
    if (monthEnd.isBefore(_firstDate) || monthStart.isAfter(_lastDate)) return;
    setState(() => _visibleMonth = nextMonth);
  }

  void _selectDate(DateTime date) {
    final selected = DateUtils.dateOnly(date);
    setState(() => _selectedDate = selected);
    widget.onDateChanged(selected);
  }

  void _onTimeChanged(String value) {
    final parsed = parseHoraSolicitud(value);
    setState(() {
      _timeError = value.isEmpty || parsed != null
          ? null
          : 'Use el formato 9:30am.';
    });
    widget.onTimeChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final primary = theme.primary;
    final disabled = theme.secondaryText;
    final firstWeekdayOffset = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).weekday - 1;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final previousMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final canGoBack = DateTime(previousMonth.year, previousMonth.month + 1, 0)
        .isAfter(_firstDate.subtract(const Duration(days: 1)));
    final canGoForward = DateTime(nextMonth.year, nextMonth.month)
        .isBefore(DateTime(_lastDate.year, _lastDate.month + 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showInstructions) ...[
          Text(
            '1 · Clic en el día',
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Mes anterior',
                    onPressed: canGoBack ? () => _changeMonth(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                    color: primary,
                  ),
                  Expanded(
                    child: Text(
                      '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mes siguiente',
                    onPressed: canGoForward ? () => _changeMonth(1) : null,
                    icon: const Icon(Icons.chevron_right),
                    color: primary,
                  ),
                ],
              ),
              Row(
                children: [
                  for (final day in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - firstWeekdayOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    dayNumber,
                  );
                  final isSelected = _selectedDate != null &&
                      DateUtils.isSameDay(_selectedDate, date);
                  final isEnabled = !date.isBefore(_firstDate) &&
                      !date.isAfter(_lastDate);
                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: Material(
                      color: isSelected ? primary : Colors.transparent,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: isEnabled ? () => _selectDate(date) : null,
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: theme.bodyMedium.copyWith(
                              color: isSelected
                                  ? theme.info
                                  : isEnabled
                                      ? theme.primaryText
                                      : disabled.withValues(alpha: 0.45),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_showValidationErrors && _selectedDate == null) ...[
          const SizedBox(height: 4),
          Text(
            'Seleccione una fecha.',
            style: theme.bodySmall.copyWith(color: theme.error),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          widget.timeLabel,
          style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _timeController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          onChanged: _onTimeChanged,
          decoration: InputDecoration(
            hintText: '9:30am',
            errorText: _showValidationErrors || _timeError != null
                ? _timeError ??
                    (_timeController.text.isEmpty
                        ? 'Escriba la hora en formato 9:30am.'
                        : null)
                : null,
            filled: true,
            fillColor: theme.secondaryBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.alternate),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
