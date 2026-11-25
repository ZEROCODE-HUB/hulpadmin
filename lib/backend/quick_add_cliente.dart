import 'direcciones_cliente.dart';
import 'supabase/supabase.dart';

String normalizarCelularCliente(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length == 10 ? '57$digits' : digits;
}

class QuickAddException implements Exception {
  const QuickAddException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ResultadoQuickAdd {
  const ResultadoQuickAdd(this.cliente, this.direccion,
      {this.existente = false});
  final UsuariosRow cliente;
  final DireccionCliente? direccion;
  final bool existente;
}

class QuickAddClienteRepository {
  Future<ResultadoQuickAdd> crear(
      {required String requestId,
      required String nombre,
      required String apellido,
      required String telefono,
      required Map<String, dynamic> direccion}) async {
    try {
      final response = await SupaFlow.client.functions
          .invoke('crear-cliente-externo', body: {
        'request_id': requestId,
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'telefono': normalizarCelularCliente(telefono),
        'direccion': direccion,
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true || data['cliente'] is! Map) {
        throw const QuickAddException(
            'No se pudo crear el cliente. Vuelve a guardar.');
      }
      return ResultadoQuickAdd(
        UsuariosRow(Map<String, dynamic>.from(data['cliente'] as Map)),
        data['direccion'] is Map
            ? DireccionCliente(
                Map<String, dynamic>.from(data['direccion'] as Map))
            : null,
        existente: data['existente'] == true,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      throw QuickAddException(details is Map && details['error'] is String
          ? details['error'] as String
          : 'No se pudo crear el cliente. Vuelve a guardar.');
    }
  }
}
