import '../database.dart';

class SolicitudesServicioTable extends SupabaseTable<SolicitudesServicioRow> {
  @override
  String get tableName => 'solicitudes_servicio';

  @override
  SolicitudesServicioRow createRow(Map<String, dynamic> data) =>
      SolicitudesServicioRow(data);
}

class SolicitudesServicioRow extends SupabaseDataRow {
  String? get direccionUsuarioId => getField<String>('direccion_usuario_id');
  SolicitudesServicioRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SolicitudesServicioTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get usuarioId => getField<String>('usuario_id')!;
  set usuarioId(String value) => setField<String>('usuario_id', value);

  String? get descripcion => getField<String>('descripcion');
  set descripcion(String? value) => setField<String>('descripcion', value);

  String? get informacionAdicional => getField<String>('informacion_adicional');
  set informacionAdicional(String? value) =>
      setField<String>('informacion_adicional', value);

  String get ubicacion => getField<String>('ubicacion')!;
  set ubicacion(String value) => setField<String>('ubicacion', value);

  DateTime get fecha => getField<DateTime>('fecha')!;
  set fecha(DateTime value) => setField<DateTime>('fecha', value);

  PostgresTime get hora => getField<PostgresTime>('hora')!;
  set hora(PostgresTime value) => setField<PostgresTime>('hora', value);

  double get precio => getField<double>('precio')!;
  set precio(double value) => setField<double>('precio', value);

  String get estado => getField<String>('estado')!;
  set estado(String value) => setField<String>('estado', value);

  DateTime? get creadoEn => getField<DateTime>('creado_en');
  set creadoEn(DateTime? value) => setField<DateTime>('creado_en', value);

  String? get servicioId => getField<String>('servicio_id');
  set servicioId(String? value) => setField<String>('servicio_id', value);

  String? get servicioNombre => getField<String>('servicio_nombre');
  set servicioNombre(String? value) =>
      setField<String>('servicio_nombre', value);

  String? get profesionalId => getField<String>('profesional_id');
  set profesionalId(String? value) => setField<String>('profesional_id', value);

  String? get estadoPago => getField<String>('estado_pago');
  set estadoPago(String? value) => setField<String>('estado_pago', value);

  int? get ticket => getField<int>('ticket');
  set ticket(int? value) => setField<int>('ticket', value);

  DateTime? get fechaCancelacion => getField<DateTime>('fecha_cancelacion');
  set fechaCancelacion(DateTime? value) =>
      setField<DateTime>('fecha_cancelacion', value);

  DateTime? get fechaReagendamiento =>
      getField<DateTime>('fecha_reagendamiento');
  set fechaReagendamiento(DateTime? value) =>
      setField<DateTime>('fecha_reagendamiento', value);

  DateTime? get fechaPago => getField<DateTime>('fecha_pago');
  set fechaPago(DateTime? value) => setField<DateTime>('fecha_pago', value);

  DateTime? get fechaAceptacion => getField<DateTime>('fecha_aceptacion');
  set fechaAceptacion(DateTime? value) =>
      setField<DateTime>('fecha_aceptacion', value);

  String? get solicitudOriginalId => getField<String>('solicitud_original_id');
  set solicitudOriginalId(String? value) =>
      setField<String>('solicitud_original_id', value);

  double? get precioBase => getField<double>('precio_base');
  set precioBase(double? value) => setField<double>('precio_base', value);

  double? get precioAdicionales => getField<double>('precio_adicionales');
  set precioAdicionales(double? value) =>
      setField<double>('precio_adicionales', value);

  String? get tipo => getField<String>('tipo');
  set tipo(String? value) => setField<String>('tipo', value);

  String? get ciudadId => getField<String>('ciudad_id');
  set ciudadId(String? value) => setField<String>('ciudad_id', value);

  double? get latitud => getField<double>('latitud');
  set latitud(double? value) => setField<double>('latitud', value);

  double? get longitud => getField<double>('longitud');
  set longitud(double? value) => setField<double>('longitud', value);
}
