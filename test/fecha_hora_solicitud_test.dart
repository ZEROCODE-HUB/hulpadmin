import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/fecha_hora_solicitud_widget.dart';

void main() {
  group('parseHoraSolicitud', () {
    test('accepts lowercase 12-hour values and converts them to 24-hour time',
        () {
      expect(parseHoraSolicitud('9:30am'), DateTime(1970, 1, 1, 9, 30));
      expect(parseHoraSolicitud('9:30pm'), DateTime(1970, 1, 1, 21, 30));
      expect(parseHoraSolicitud('12:00am'), DateTime(1970, 1, 1, 0));
      expect(parseHoraSolicitud('12:00pm'), DateTime(1970, 1, 1, 12));
    });

    test('rejects uppercase, whitespace, 24-hour and invalid clock values', () {
      for (final value in [
        '9:30 AM',
        '9:30 am',
        '21:30',
        '0:30am',
        '13:30pm',
        '9:75am',
        '9:3am',
        '',
      ]) {
        expect(parseHoraSolicitud(value), isNull, reason: value);
      }
    });
  });

  test('formats stored times back into the editable lowercase form', () {
    expect(formatHoraSolicitud(DateTime(1970, 1, 1, 9, 30)), '9:30am');
    expect(formatHoraSolicitud(DateTime(1970, 1, 1, 21, 30)), '9:30pm');
  });
}
