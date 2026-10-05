import '/backend/supabase/supabase.dart';

/// Consultas de proveedores sobre `vw_profesionales_completo`.
///
/// La vista devuelve **una fila por servicio ofrecido**, no una por proveedor:
/// un proveedor con 8 servicios ocupa 8 filas. Como PostgREST corta cualquier
/// respuesta en 1000 filas, pedir la vista de un solo tirón traía apenas ~70
/// proveedores de los 200 pendientes, y los registros nuevos se quedaban fuera
/// del corte sin ninguna señal de error. Por eso aquí se pagina con `range`
/// hasta agotar el resultado.
const int _tamanoPagina = 1000;

/// Tope de seguridad: 30 páginas = 30.000 filas. Muy por encima del volumen
/// real (≈3.800 filas pendientes) y evita un bucle infinito si el servidor
/// devolviera siempre páginas llenas.
const int _maximoPaginas = 30;

const String _vistaProfesionales = 'vw_profesionales_completo';

/// Columnas contra las que busca la caja de búsqueda del admin.
///
/// Antes sólo se comparaba contra `nombres`, así que escribir un correo o una
/// cédula no encontraba nunca al proveedor.
String filtroBusquedaProfesionales(String texto) {
  final termino = limpiarTerminoBusqueda(texto);

  return [
    'nombres.ilike.%$termino%',
    'apellidos.ilike.%$termino%',
    'nombre_completo.ilike.%$termino%',
    'correo_electronico.ilike.%$termino%',
    'numero_documento.ilike.%$termino%',
    'telefono.ilike.%$termino%',
  ].join(',');
}

/// PostgREST separa las condiciones de un `or` con comas y las delimita con
/// paréntesis: si el término los trae, la consulta se rompe.
String limpiarTerminoBusqueda(String texto) =>
    texto.replaceAll(RegExp(r'[,()]'), ' ').trim();

/// Trae **todas** las filas de la vista que cumplen los filtros, paginando.
///
/// El resultado conserva una fila por servicio (la UI necesita las categorías
/// para el desplegable de filtro); usar [porProveedor] para quedarse con una
/// fila por proveedor.
Future<List<VwProfesionalesCompletoRow>> consultarProfesionales({
  String? verificado,
  String? categoriaId,
  String busqueda = '',
}) async {
  final termino = limpiarTerminoBusqueda(busqueda);
  final filas = <VwProfesionalesCompletoRow>[];

  for (var pagina = 0; pagina < _maximoPaginas; pagina++) {
    var query = SupaFlow.client.from(_vistaProfesionales).select();

    if (verificado != null && verificado.isNotEmpty) {
      query = query.eq('verificado', verificado);
    }
    if (categoriaId != null && categoriaId.isNotEmpty) {
      query = query.eq('categoria_id', categoriaId);
    }
    if (termino.isNotEmpty) {
      query = query.or(filtroBusquedaProfesionales(termino));
    }

    final desde = pagina * _tamanoPagina;
    // El orden tiene que ser total y determinista: `fecha_registro` empata
    // entre las filas de un mismo proveedor, y con empates las páginas pueden
    // repetir u omitir filas.
    final lote = await query
        .order('fecha_registro', ascending: false)
        .order('profesional_id', ascending: true)
        .order('servicio_id', ascending: true)
        .range(desde, desde + _tamanoPagina - 1);

    filas.addAll(lote.map(VwProfesionalesCompletoRow.new));

    if (lote.length < _tamanoPagina) {
      break;
    }
  }

  return filas;
}

/// Deja una sola fila por proveedor, preservando el orden de entrada.
List<VwProfesionalesCompletoRow> porProveedor(
  List<VwProfesionalesCompletoRow> filas,
) {
  final vistos = <String>{};
  return filas
      .where((fila) => vistos.add(fila.profesionalId ?? ''))
      .toList(growable: false);
}

/// Nombres de categoría presentes en el resultado, ordenados alfabéticamente.
List<String> categoriasDe(List<VwProfesionalesCompletoRow> filas) {
  final nombres = filas
      .map((fila) => fila.categoriaNombre)
      .whereType<String>()
      .where((nombre) => nombre.isNotEmpty)
      .toSet()
      .toList();
  nombres.sort();
  return nombres;
}

/// Cuenta proveedores **distintos**, opcionalmente por estado de verificación.
///
/// Se cuenta sobre `usuarios` y no sobre la vista: la vista tiene una fila por
/// servicio, así que contar sus filas da un número inflado, y contar personas
/// distintas obligaría a descargarla entera (>4.000 filas) sólo para pintar un
/// número. `count` exacto no trae ninguna fila.
Future<int> contarProveedores({String? verificado}) async {
  var query =
      SupaFlow.client.from('usuarios').select('id').eq('rol', 'proveedor');

  if (verificado != null && verificado.isNotEmpty) {
    query = query.eq('verificado', verificado);
  }

  final respuesta = await query.count(CountOption.exact);
  return respuesta.count;
}
