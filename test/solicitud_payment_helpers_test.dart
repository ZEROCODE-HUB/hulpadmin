import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/flutter_flow/solicitud_payment_helpers.dart';

void main() {
  group('payment status helpers', () {
    test('recognizes pagado without case or whitespace sensitivity', () {
      expect(isPaymentReceived(' pagado '), isTrue);
      expect(isPaymentReceived('PAGADO'), isTrue);
      expect(paymentStatusLabel('PAGADO'), 'Recibido');
    });

    test('treats pending and missing states as pending', () {
      expect(isPaymentPending('pendiente'), isTrue);
      expect(isPaymentPending(null), isTrue);
      expect(isPaymentPending('  '), isTrue);
      expect(paymentStatusLabel(null), 'Sin pago');
      expect(paymentStatusLabel(' pendiente '), 'Sin pago');
    });

    test('preserves unknown states instead of relabeling them', () {
      expect(isPaymentPending('reembolsado'), isFalse);
      expect(isPaymentReceived('reembolsado'), isFalse);
      expect(paymentStatusLabel(' reembolsado '), 'reembolsado');
    });
  });
}
