/// Valida el precio de catálogo antes de crear un servicio.
String? validarPrecioNuevoServicio(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Ingresa el precio base';
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(texto)) {
    return 'Ingresa un precio numérico válido';
  }
  final precio = double.tryParse(texto);
  if (precio == null || !precio.isFinite) {
    return 'Ingresa un precio numérico válido';
  }
  if (precio < 1500) return r'El precio mínimo es $1.500 COP';
  return null;
}
