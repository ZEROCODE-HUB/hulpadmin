import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/web/menu/menu_widget.dart';
import 'ciudades_widget.dart' show CiudadesWidget;
import 'package:flutter/material.dart';

class CiudadesModel extends FlutterFlowModel<CiudadesWidget> {
  // Model for Menu component.
  late MenuModel menuModel;

  /// Las ciudades tal y como se pintan ahora mismo.
  List<CiudadesRow> ciudades = [];

  /// Provincias. No se piden en el formulario —el admin solo da de alta
  /// ciudades—, pero `ciudades.provincia_id` viene del esquema original y
  /// puede seguir siendo obligatoria, así que se guarda una para rellenarla
  /// sin molestar a nadie.
  List<ProvinciasRow> provincias = [];

  String? get provinciaPorDefecto =>
      provincias.isEmpty ? null : provincias.first.id;

  bool cargando = true;
  String? error;

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    menuModel.dispose();
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    try {
      ciudades = await CiudadesTable().queryRows(
        queryFn: (q) => q.order('nombre', ascending: true),
      );
      provincias = await ProvinciasTable().queryRows(
        queryFn: (q) => q.order('nombre', ascending: true),
      );
    } catch (e) {
      error = 'No se pudieron cargar las ciudades: $e';
    }
    cargando = false;
  }

  /// Cuántas solicitudes y cuántos usuarios dependen de una ciudad.
  ///
  /// Se consulta antes de borrar: las solicitudes la referencian por id, y las
  /// fichas de usuario guardan el **nombre** en texto, así que una ciudad
  /// borrada deja al proveedor con una ciudad que ya no existe en la tabla
  /// —y, con el filtro por ciudad de la app de Talento, sin ver solicitudes.
  Future<({int solicitudes, int usuarios})> usosDe(CiudadesRow ciudad) async {
    final solicitudes = await SupaFlow.client
        .from('solicitudes_servicio')
        .select('id')
        .eq('ciudad_id', ciudad.id)
        .count(CountOption.exact);
    final usuarios = await SupaFlow.client
        .from('usuarios')
        .select('id')
        .eq('ciudad', ciudad.nombre)
        .count(CountOption.exact);
    return (solicitudes: solicitudes.count, usuarios: usuarios.count);
  }
}
