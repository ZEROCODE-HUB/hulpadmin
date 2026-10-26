/// Presentación del valor completo que ya entrega la vista de solicitudes.
String nombreClienteVisible(String? nombreCompleto) {
  final nombre = nombreCompleto?.trim() ?? '';
  return nombre.isEmpty ? 'Cliente sin nombre' : nombre;
}

/// Los modelos del perfil administrativo entregan las partes por separado.
String nombreClienteDePerfil(String? nombres, String? apellidos) {
  return nombreClienteVisible(
    [nombres, apellidos]
        .map((parte) => parte?.trim() ?? '')
        .where((parte) => parte.isNotEmpty)
        .join(' '),
  );
}
