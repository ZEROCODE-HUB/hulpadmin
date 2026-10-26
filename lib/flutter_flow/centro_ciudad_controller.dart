import 'package:flutter/foundation.dart';

import 'ubicacion_helpers.dart';

/// Estado de cámara independiente de la selección de coordenadas del servicio.
class CentroCiudadController extends ChangeNotifier {
  CentroCiudadController(this.resolver);

  final Future<Coordenadas?> Function(String? id, String? nombre) resolver;
  Coordenadas? centro;
  bool fallo = false;
  String? _identidad;
  int _revision = 0;
  bool _cerrado = false;

  Future<void> actualizar(String? id, String? nombre) async {
    final identidad = '${id?.trim() ?? ''}|${nombre?.trim() ?? ''}';
    if (_cerrado || identidad == _identidad) return;
    _identidad = identidad;
    final revision = ++_revision;
    centro = null;
    fallo = false;
    notifyListeners();
    if ((id?.trim().isEmpty ?? true) && (nombre?.trim().isEmpty ?? true)) {
      return;
    }

    Coordenadas? resultado;
    try {
      resultado = await resolver(id, nombre);
    } catch (_) {
      // La captura manual sigue funcionando si falla el catálogo o Google.
    }
    if (_cerrado || revision != _revision) return;
    centro = resultado;
    fallo = resultado == null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _revision++;
    super.dispose();
  }
}
