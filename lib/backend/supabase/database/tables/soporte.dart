import '../database.dart';

class SoporteTable extends SupabaseTable<SoporteRow> {
  @override
  String get tableName => 'soporte';

  @override
  SoporteRow createRow(Map<String, dynamic> data) => SoporteRow(data);
}

class SoporteRow extends SupabaseDataRow {
  SoporteRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SoporteTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  int get nro => getField<int>('nro')!;
  set nro(int value) => setField<int>('nro', value);

  String get asunto => getField<String>('asunto')!;
  set asunto(String value) => setField<String>('asunto', value);

  DateTime? get fechaHora => getField<DateTime>('fecha_hora');
  set fechaHora(DateTime? value) => setField<DateTime>('fecha_hora', value);

  String? get servicio => getField<String>('servicio');
  set servicio(String? value) => setField<String>('servicio', value);

  String? get subcategoria => getField<String>('subcategoria');
  set subcategoria(String? value) => setField<String>('subcategoria', value);

  String? get direccion => getField<String>('direccion');
  set direccion(String? value) => setField<String>('direccion', value);

  double? get precio => getField<double>('precio');
  set precio(double? value) => setField<double>('precio', value);

  String? get idProveedor => getField<String>('id_proveedor');
  set idProveedor(String? value) => setField<String>('id_proveedor', value);

  String? get nombreUsuario => getField<String>('nombre_usuario');
  set nombreUsuario(String? value) => setField<String>('nombre_usuario', value);

  String? get telefonoUsuario => getField<String>('telefono_usuario');
  set telefonoUsuario(String? value) =>
      setField<String>('telefono_usuario', value);

  String? get emailUsuario => getField<String>('email_usuario');
  set emailUsuario(String? value) => setField<String>('email_usuario', value);

  String? get nombreProveedor => getField<String>('nombre_proveedor');
  set nombreProveedor(String? value) =>
      setField<String>('nombre_proveedor', value);

  String? get telefonoProveedor => getField<String>('telefono_proveedor');
  set telefonoProveedor(String? value) =>
      setField<String>('telefono_proveedor', value);

  String? get emailProveedor => getField<String>('email_proveedor');
  set emailProveedor(String? value) =>
      setField<String>('email_proveedor', value);

  String? get estado => getField<String>('estado');
  set estado(String? value) => setField<String>('estado', value);

  String? get notas => getField<String>('notas');
  set notas(String? value) => setField<String>('notas', value);

  String? get nroSolicitud => getField<String>('nro_solicitud');
  set nroSolicitud(String? value) => setField<String>('nro_solicitud', value);
}
