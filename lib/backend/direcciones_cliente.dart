import 'supabase/supabase.dart';
import '/flutter_flow/ubicacion_helpers.dart';

class DireccionCliente {
  DireccionCliente(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get usuarioId => data['usuario_id'] as String;
  bool get activa => data['activo'] != false;
  String get etiqueta => switch (data['tipo']) {
        'casa' => 'Casa',
        'oficina' => 'Oficina',
        _ => data['nombre'] as String? ?? 'Otra',
      };
  String get completa => ['direccion', 'complemento', 'referencia']
      .map((key) => (data[key] as String? ?? '').trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
  String? get ciudadId => data['ciudad_id'] as String?;
  Coordenadas? get punto => data['latitud'] == null || data['longitud'] == null
      ? null
      : Coordenadas((data['latitud'] as num).toDouble(),
          (data['longitud'] as num).toDouble());
}

class DireccionesClienteRepository {
  Future<List<DireccionCliente>> cargarClientes(List<String> usuarioIds) async {
    if (usuarioIds.isEmpty) return [];
    final rows = await SupaFlow.client
        .from('direcciones_usuario')
        .select()
        .inFilter('usuario_id', usuarioIds)
        .eq('activo', true)
        .order('creado_en');
    return rows.map((row) => DireccionCliente(row)).toList();
  }

  Future<List<CiudadesRow>> ciudades({bool soloActivas = false}) =>
      CiudadesTable().queryRows(
          queryFn: (q) => soloActivas
              ? q.eqOrNull('activo', true).order('nombre')
              : q.order('nombre'));
  Future<List<DireccionCliente>> cargar(String usuarioId) async {
    final rows = await SupaFlow.client
        .from('direcciones_usuario')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('activo', true)
        .order('creado_en');
    return rows.map((row) => DireccionCliente(row)).toList();
  }

  /// Solo para la administración del perfil; los selectores siguen usando cargar().
  Future<List<DireccionCliente>> cargarTodas(String usuarioId) async {
    final rows = await SupaFlow.client
        .from('direcciones_usuario')
        .select()
        .eq('usuario_id', usuarioId)
        .order('creado_en');
    return rows.map((row) => DireccionCliente(row)).toList();
  }

  Future<DireccionCliente> guardar(Map<String, dynamic> data) async =>
      DireccionCliente(await SupaFlow.client
          .from('direcciones_usuario')
          .insert(data)
          .select()
          .single());

  Future<DireccionCliente> actualizar(
      String usuarioId, String id, Map<String, dynamic> data,
      {bool activa = true}) async {
    final row = await SupaFlow.client
        .from('direcciones_usuario')
        .update(data)
        .eq('id', id)
        .eq('usuario_id', usuarioId)
        .eq('activo', activa)
        .select()
        .maybeSingle();
    if (row == null) throw StateError('La dirección ya no está disponible');
    return DireccionCliente(row);
  }

  Future<void> archivar(String usuarioId, String id) async {
    final row = await SupaFlow.client
        .from('direcciones_usuario')
        .update({'activo': false})
        .eq('id', id)
        .eq('usuario_id', usuarioId)
        .eq('activo', true)
        .select('id')
        .maybeSingle();
    if (row == null) throw StateError('La dirección ya no está disponible');
  }

  Future<void> desarchivar(String usuarioId, String id) async {
    final row = await SupaFlow.client
        .from('direcciones_usuario')
        .update({'activo': true})
        .eq('id', id)
        .eq('usuario_id', usuarioId)
        .eq('activo', false)
        .select('id')
        .maybeSingle();
    if (row == null) throw StateError('La dirección ya no está disponible');
  }
}
