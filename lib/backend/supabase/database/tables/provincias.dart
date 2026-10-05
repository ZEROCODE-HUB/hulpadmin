import '../database.dart';

class ProvinciasTable extends SupabaseTable<ProvinciasRow> {
  @override
  String get tableName => 'provincias';

  @override
  ProvinciasRow createRow(Map<String, dynamic> data) => ProvinciasRow(data);
}

class ProvinciasRow extends SupabaseDataRow {
  ProvinciasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProvinciasTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get paisId => getField<String>('pais_id');
  set paisId(String? value) => setField<String>('pais_id', value);

  String get nombre => getField<String>('nombre')!;
  set nombre(String value) => setField<String>('nombre', value);

  bool? get activo => getField<bool>('activo');
  set activo(bool? value) => setField<bool>('activo', value);

  DateTime? get creadoEn => getField<DateTime>('creado_en');
  set creadoEn(DateTime? value) => setField<DateTime>('creado_en', value);
}
