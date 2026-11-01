/// Oculta el prefijo de ciudad y el país Colombia, sin alterar el registro.
String direccionSolicitudVisible(String? ubicacion, String? ciudad) {
  var direccion = ubicacion?.trim() ?? '';
  final nombreCiudad = ciudad?.trim() ?? '';
  if (nombreCiudad.isNotEmpty) {
    final prefijo = RegExp(
      '^${RegExp.escape(nombreCiudad)}[ \\t]*(?:,|\\r?\\n|\$)\\s*',
      caseSensitive: false,
    );
    while (prefijo.hasMatch(direccion)) {
      direccion = direccion.replaceFirst(prefijo, '');
    }
  }
  // Google añade el país al final de la dirección. Puede haber complementos
  // en líneas posteriores; se conservan nombres como "Avenida Colombia".
  final pais = RegExp(r'(?:,\s*|^)Colombia\s*[,.]?\s*$', caseSensitive: false);
  direccion = direccion
      .split(RegExp(r'\r?\n'))
      .map((linea) => linea.replaceFirst(pais, '').trimRight())
      .where((linea) => linea.trim().isNotEmpty)
      .join('\n')
      .trim();
  return direccion.isEmpty ? 'Sin dirección registrada' : direccion;
}
