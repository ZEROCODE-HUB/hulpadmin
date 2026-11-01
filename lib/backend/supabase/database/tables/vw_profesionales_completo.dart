import '../database.dart';

class VwProfesionalesCompletoTable
    extends SupabaseTable<VwProfesionalesCompletoRow> {
  @override
  String get tableName => 'vw_profesionales_completo';

  @override
  VwProfesionalesCompletoRow createRow(Map<String, dynamic> data) =>
      VwProfesionalesCompletoRow(data);
}

class VwProfesionalesCompletoRow extends SupabaseDataRow {
  VwProfesionalesCompletoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwProfesionalesCompletoTable();

  String? get profesionalId => getField<String>('profesional_id');
  set profesionalId(String? value) => setField<String>('profesional_id', value);

  String? get nombres => getField<String>('nombres');
  set nombres(String? value) => setField<String>('nombres', value);

  String? get apellidos => getField<String>('apellidos');
  set apellidos(String? value) => setField<String>('apellidos', value);

  String? get nombreCompleto => getField<String>('nombre_completo');
  set nombreCompleto(String? value) =>
      setField<String>('nombre_completo', value);

  String? get tipoDocumento => getField<String>('tipo_documento');
  set tipoDocumento(String? value) => setField<String>('tipo_documento', value);

  String? get numeroDocumento => getField<String>('numero_documento');
  set numeroDocumento(String? value) =>
      setField<String>('numero_documento', value);

  String? get pais => getField<String>('pais');
  set pais(String? value) => setField<String>('pais', value);

  String? get codigoPais => getField<String>('codigo_pais');
  set codigoPais(String? value) => setField<String>('codigo_pais', value);

  String? get telefono => getField<String>('telefono');
  set telefono(String? value) => setField<String>('telefono', value);

  String? get correoElectronico => getField<String>('correo_electronico');
  set correoElectronico(String? value) =>
      setField<String>('correo_electronico', value);

  String? get direccion => getField<String>('direccion');
  set direccion(String? value) => setField<String>('direccion', value);

  String? get fotoPerfilUrl => getField<String>('foto_perfil_url');
  set fotoPerfilUrl(String? value) =>
      setField<String>('foto_perfil_url', value);

  DateTime? get fechaRegistro => getField<DateTime>('fecha_registro');
  set fechaRegistro(DateTime? value) =>
      setField<DateTime>('fecha_registro', value);

  int? get aniosExperiencia => getField<int>('anios_experiencia');
  set aniosExperiencia(int? value) => setField<int>('anios_experiencia', value);

  String? get registroTributario => getField<String>('registro_tributario');
  set registroTributario(String? value) =>
      setField<String>('registro_tributario', value);

  String? get verificado => getField<String>('verificado');
  set verificado(String? value) => setField<String>('verificado', value);

  String? get servicioId => getField<String>('servicio_id');
  set servicioId(String? value) => setField<String>('servicio_id', value);

  String? get servicioNombre => getField<String>('servicio_nombre');
  set servicioNombre(String? value) =>
      setField<String>('servicio_nombre', value);

  String? get subcategoriaId => getField<String>('subcategoria_id');
  set subcategoriaId(String? value) =>
      setField<String>('subcategoria_id', value);

  String? get subcategoriaNombre => getField<String>('subcategoria_nombre');
  set subcategoriaNombre(String? value) =>
      setField<String>('subcategoria_nombre', value);

  String? get categoriaId => getField<String>('categoria_id');
  set categoriaId(String? value) => setField<String>('categoria_id', value);

  String? get categoriaNombre => getField<String>('categoria_nombre');
  set categoriaNombre(String? value) =>
      setField<String>('categoria_nombre', value);

  String? get ciudad => getField<String>('ciudad');
  set ciudad(String? value) => setField<String>('ciudad', value);

  String? get estado => getField<String>('estado');
  set estado(String? value) => setField<String>('estado', value);

  DateTime? get ultimoAcceso => getField<DateTime>('ultimo_acceso');
  set ultimoAcceso(DateTime? value) =>
      setField<DateTime>('ultimo_acceso', value);

  int? get serviciosRealizados => getField<int>('servicios_realizados');
  set serviciosRealizados(int? value) =>
      setField<int>('servicios_realizados', value);

  int? get serviciosOfrecidos => getField<int>('servicios_ofrecidos');
  set serviciosOfrecidos(int? value) =>
      setField<int>('servicios_ofrecidos', value);

  double? get promedioResenas => getField<double>('promedio_resenas');
  set promedioResenas(double? value) =>
      setField<double>('promedio_resenas', value);

  int? get totalResenas => getField<int>('total_resenas');
  set totalResenas(int? value) => setField<int>('total_resenas', value);

  int? get totalSolicitudes => getField<int>('total_solicitudes');
  set totalSolicitudes(int? value) => setField<int>('total_solicitudes', value);

  double? get tasaFinalizacion => getField<double>('tasa_finalizacion');
  set tasaFinalizacion(double? value) =>
      setField<double>('tasa_finalizacion', value);
}
