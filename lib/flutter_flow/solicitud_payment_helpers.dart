/// Returns whether the payment state represents a completed payment.
bool isPaymentReceived(String? estadoPago) =>
    estadoPago?.trim().toLowerCase() == 'pagado';

/// Treats a missing payment state as pending for legacy rows.
bool isPaymentPending(String? estadoPago) {
  final normalized = estadoPago?.trim().toLowerCase();
  return normalized == null || normalized.isEmpty || normalized == 'pendiente';
}

/// Maps stored payment states to the wording used in the requests list.
String paymentStatusLabel(String? estadoPago) {
  if (isPaymentReceived(estadoPago)) return 'Recibido';
  if (isPaymentPending(estadoPago)) return 'Sin pago';
  return estadoPago!.trim();
}
