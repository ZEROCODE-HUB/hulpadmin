import 'package:flutter/services.dart';

/// Formatters and validators shared by numeric fields in Hulp Admin.
class HulpNumericInput {
  HulpNumericInput._();

  static TextInputFormatter get integerFormatter =>
      FilteringTextInputFormatter.digitsOnly;

  static TextInputFormatter get decimalFormatter =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        return RegExp(r'^\d*(?:\.\d*)?$').hasMatch(newValue.text)
            ? newValue
            : oldValue;
      });

  /// Keeps the common Colombian NIT separators while rejecting letters.
  static TextInputFormatter get taxIdFormatter =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        return RegExp(r'^[0-9.-]*$').hasMatch(newValue.text)
            ? newValue
            : oldValue;
      });

  static String? validateInteger(
    String? value, {
    required String fieldName,
    bool required = true,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? '$fieldName es obligatorio.' : null;
    }
    return RegExp(r'^\d+$').hasMatch(text)
        ? null
        : 'Ingresa solo números en $fieldName.';
  }

  static String? validateDecimal(
    String? value, {
    required String fieldName,
    bool required = true,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? '$fieldName es obligatorio.' : null;
    }
    final isDecimal = RegExp(r'^(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(text);
    final parsed = double.tryParse(text);
    return isDecimal && parsed != null && parsed.isFinite
        ? null
        : 'Ingresa un valor numérico válido en $fieldName.';
  }

  static String? validateTaxId(
    String? value, {
    required String fieldName,
    bool required = true,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? '$fieldName es obligatorio.' : null;
    }
    return RegExp(r'^\d+(?:[.-]\d+)*$').hasMatch(text)
        ? null
        : 'Ingresa un $fieldName válido, usando solo números y separadores.';
  }
}
