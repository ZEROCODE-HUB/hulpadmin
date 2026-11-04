import '../database.dart';

class VwSolicitudesServiciosCompletaTable
    extends SupabaseTable<VwSolicitudesServiciosCompletaRow> {
  @override
  String get tableName => 'vw_solicitudes_servicios_completa';

  @override
  VwSolicitudesServiciosCompletaRow createRow(Map<String, dynamic> data) =>
      VwSolicitudesServiciosCompletaRow(data);
}

class VwSolicitudesServiciosCompletaRow extends SupabaseDataRow {
  VwSolicitudesServiciosCompletaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwSolicitudesServiciosCompletaTable();

  String? get solicitudId => getField<String>('solicitud_id');
  String? get direccionUsuarioId => getField<String>('direccion_usuario_id');
  set solicitudId(String? value) => setField<String>('solicitud_id', value);

  int? get ticket => getField<int>('ticket');
  set ticket(int? value) => setField<int>('ticket', value);

  String? get usuarioId => getField<String>('usuario_id');
  set usuarioId(String? value) => setField<String>('usuario_id', value);

  String? get solicitudDescripcion => getField<String>('solicitud_descripcion');
  set solicitudDescripcion(String? value) =>
      setField<String>('solicitud_descripcion', value);

  String? get informacionAdicional => getField<String>('informacion_adicional');
  set informacionAdicional(String? value) =>
      setField<String>('informacion_adicional', value);

  String? get ubicacion => getField<String>('ubicacion');
  set ubicacion(String? value) => setField<String>('ubicacion', value);

  DateTime? get fecha => getField<DateTime>('fecha');
  set fecha(DateTime? value) => setField<DateTime>('fecha', value);

  PostgresTime? get hora => getField<PostgresTime>('hora');
  set hora(PostgresTime? value) => setField<PostgresTime>('hora', value);

  double? get precioSolicitud => getField<double>('precio_solicitud');
  set precioSolicitud(double? value) =>
      setField<double>('precio_solicitud', value);

  double? get precioBase => getField<double>('precio_base');
  set precioBase(double? value) => setField<double>('precio_base', value);

  double? get precioAdicionales => getField<double>('precio_adicionales');
  set precioAdicionales(double? value) =>
      setField<double>('precio_adicionales', value);

  double? get precioTotal => getField<double>('precio_total');
  set precioTotal(double? value) => setField<double>('precio_total', value);

  double? get precioCalculado => getField<double>('precio_calculado');
  set precioCalculado(double? value) =>
      setField<double>('precio_calculado', value);

  String? get estadoSolicitud => getField<String>('estado_solicitud');
  set estadoSolicitud(String? value) =>
      setField<String>('estado_solicitud', value);

  String? get estadoPago => getField<String>('estado_pago');
  set estadoPago(String? value) => setField<String>('estado_pago', value);

  DateTime? get solicitudCreadaEn => getField<DateTime>('solicitud_creada_en');
  set solicitudCreadaEn(DateTime? value) =>
      setField<DateTime>('solicitud_creada_en', value);

  int? get clienteIdUsuario => getField<int>('cliente_id_usuario');
  set clienteIdUsuario(int? value) =>
      setField<int>('cliente_id_usuario', value);

  String? get clienteNombres => getField<String>('cliente_nombres');
  set clienteNombres(String? value) =>
      setField<String>('cliente_nombres', value);

  String? get clienteApellidos => getField<String>('cliente_apellidos');
  set clienteApellidos(String? value) =>
      setField<String>('cliente_apellidos', value);

  String? get clienteNombreCompleto =>
      getField<String>('cliente_nombre_completo');
  set clienteNombreCompleto(String? value) =>
      setField<String>('cliente_nombre_completo', value);

  String? get clienteTelefono => getField<String>('cliente_telefono');
  set clienteTelefono(String? value) =>
      setField<String>('cliente_telefono', value);

  String? get clienteCorreo => getField<String>('cliente_correo');
  set clienteCorreo(String? value) => setField<String>('cliente_correo', value);

  String? get clienteDireccion => getField<String>('cliente_direccion');
  set clienteDireccion(String? value) =>
      setField<String>('cliente_direccion', value);

  String? get clienteFotoPerfil => getField<String>('cliente_foto_perfil');
  set clienteFotoPerfil(String? value) =>
      setField<String>('cliente_foto_perfil', value);

  String? get servicioId => getField<String>('servicio_id');
  set servicioId(String? value) => setField<String>('servicio_id', value);

  String? get servicioNombre => getField<String>('servicio_nombre');
  set servicioNombre(String? value) =>
      setField<String>('servicio_nombre', value);

  String? get servicioDescripcion => getField<String>('servicio_descripcion');
  set servicioDescripcion(String? value) =>
      setField<String>('servicio_descripcion', value);

  double? get servicioPrecioBase => getField<double>('servicio_precio_base');
  set servicioPrecioBase(double? value) =>
      setField<double>('servicio_precio_base', value);

  String? get servicioEstado => getField<String>('servicio_estado');
  set servicioEstado(String? value) =>
      setField<String>('servicio_estado', value);

  String? get servicioInformacionRelevante =>
      getField<String>('servicio_informacion_relevante');
  set servicioInformacionRelevante(String? value) =>
      setField<String>('servicio_informacion_relevante', value);

  List<String> get servicioFotos => getListField<String>('servicio_fotos');
  set servicioFotos(List<String>? value) =>
      setListField<String>('servicio_fotos', value);

  List<String> get servicioItems => getListField<String>('servicio_items');
  set servicioItems(List<String>? value) =>
      setListField<String>('servicio_items', value);

  String? get profesionalId => getField<String>('profesional_id');
  set profesionalId(String? value) => setField<String>('profesional_id', value);

  int? get proveedorIdUsuario => getField<int>('proveedor_id_usuario');
  set proveedorIdUsuario(int? value) =>
      setField<int>('proveedor_id_usuario', value);

  String? get proveedorNombres => getField<String>('proveedor_nombres');
  set proveedorNombres(String? value) =>
      setField<String>('proveedor_nombres', value);

  String? get proveedorApellidos => getField<String>('proveedor_apellidos');
  set proveedorApellidos(String? value) =>
      setField<String>('proveedor_apellidos', value);

  String? get proveedorNombreCompleto =>
      getField<String>('proveedor_nombre_completo');
  set proveedorNombreCompleto(String? value) =>
      setField<String>('proveedor_nombre_completo', value);

  String? get proveedorTelefono => getField<String>('proveedor_telefono');
  set proveedorTelefono(String? value) =>
      setField<String>('proveedor_telefono', value);

  String? get proveedorCorreo => getField<String>('proveedor_correo');
  set proveedorCorreo(String? value) =>
      setField<String>('proveedor_correo', value);

  String? get proveedorDireccion => getField<String>('proveedor_direccion');
  set proveedorDireccion(String? value) =>
      setField<String>('proveedor_direccion', value);

  String? get proveedorFotoPerfil => getField<String>('proveedor_foto_perfil');
  set proveedorFotoPerfil(String? value) =>
      setField<String>('proveedor_foto_perfil', value);

  int? get proveedorExperiencia => getField<int>('proveedor_experiencia');
  set proveedorExperiencia(int? value) =>
      setField<int>('proveedor_experiencia', value);

  String? get proveedorRegistroTributario =>
      getField<String>('proveedor_registro_tributario');
  set proveedorRegistroTributario(String? value) =>
      setField<String>('proveedor_registro_tributario', value);

  String? get proveedorVerificado => getField<String>('proveedor_verificado');
  set proveedorVerificado(String? value) =>
      setField<String>('proveedor_verificado', value);

  bool? get proveedorDisponible => getField<bool>('proveedor_disponible');
  set proveedorDisponible(bool? value) =>
      setField<bool>('proveedor_disponible', value);

  String? get subcategoriaId => getField<String>('subcategoria_id');
  set subcategoriaId(String? value) =>
      setField<String>('subcategoria_id', value);

  String? get subcategoriaNombre => getField<String>('subcategoria_nombre');
  set subcategoriaNombre(String? value) =>
      setField<String>('subcategoria_nombre', value);

  String? get subcategoriaDescripcion =>
      getField<String>('subcategoria_descripcion');
  set subcategoriaDescripcion(String? value) =>
      setField<String>('subcategoria_descripcion', value);

  String? get categoriaId => getField<String>('categoria_id');
  set categoriaId(String? value) => setField<String>('categoria_id', value);

  String? get categoriaNombre => getField<String>('categoria_nombre');
  set categoriaNombre(String? value) =>
      setField<String>('categoria_nombre', value);

  String? get categoriaImagen => getField<String>('categoria_imagen');
  set categoriaImagen(String? value) =>
      setField<String>('categoria_imagen', value);

  int? get puntuacion => getField<int>('puntuacion');
  set puntuacion(int? value) => setField<int>('puntuacion', value);

  double? get proveedorCalificacionPromedio =>
      getField<double>('proveedor_calificacion_promedio');
  set proveedorCalificacionPromedio(double? value) =>
      setField<double>('proveedor_calificacion_promedio', value);

  int? get proveedorTotalResenas => getField<int>('proveedor_total_resenas');
  set proveedorTotalResenas(int? value) =>
      setField<int>('proveedor_total_resenas', value);

  int? get proveedorServiciosCompletados =>
      getField<int>('proveedor_servicios_completados');
  set proveedorServiciosCompletados(int? value) =>
      setField<int>('proveedor_servicios_completados', value);

  // REQ-006 v1.0.0: ciudad de la solicitud (ciudades.nombre vía LEFT JOIN en la vista).
  String? get solicitudCiudad => getField<String>('solicitud_ciudad');
  set solicitudCiudad(String? value) =>
      setField<String>('solicitud_ciudad', value);

  // Punto exacto de la solicitud. Nulo en todo lo creado antes de la
  // migracion 0003 y en lo que se siga creando sin capturarlo.
  double? get latitud => getField<double>('latitud');
  set latitud(double? value) => setField<double>('latitud', value);

  double? get longitud => getField<double>('longitud');
  set longitud(double? value) => setField<double>('longitud', value);
}
