import 'package:intl/intl.dart';

enum TipoActividadSolicitud {
  creada,
  aceptada,
  enCamino,
  iniciada,
  finalizada,
  financiera,
}

typedef CambioSolicitud = ({String campo, String anterior, String nuevo});

class ActividadSolicitud {
  const ActividadSolicitud({
    required this.tipo,
    required this.titulo,
    required this.fecha,
    this.autor,
    this.motivo,
    this.cambios = const [],
  });

  final TipoActividadSolicitud tipo;
  final String titulo;
  final DateTime fecha;
  final String? autor;
  final String? motivo;
  final List<CambioSolicitud> cambios;

  bool get esFinanciera => tipo == TipoActividadSolicitud.financiera;

  // Colombia usa UTC−5 durante todo el año para las fechas de Hulp.
  DateTime get fechaColombia =>
      fecha.toUtc().subtract(const Duration(hours: 5));
}

const _operaciones = {
  'aceptar': (TipoActividadSolicitud.aceptada, 'Solicitud aceptada'),
  'en_camino': (TipoActividadSolicitud.enCamino, 'En camino'),
  'empece': (TipoActividadSolicitud.iniciada, 'Servicio iniciado'),
  'termine': (TipoActividadSolicitud.finalizada, 'Servicio finalizado'),
};

const _camposEditables = {
  'precio_base': ('Precio lista', 'Precio lista actualizado'),
  'precio': ('Precio pagado', 'Precio pagado actualizado'),
  'motivo_precio_pagado': (
    'Motivo del cambio',
    'Motivo del cambio actualizado'
  ),
  'adelanto_proveedor': (
    'Adelanto al proveedor',
    'Adelanto al proveedor actualizado'
  ),
  'adelanto_motivo': ('Motivo del adelanto', 'Motivo del adelanto actualizado'),
  'aplica_wompi': ('Paga por Wompi', 'Recargo de Wompi actualizado'),
  'aplica_ajuste_iva': ('Ajuste IVA', 'Ajuste IVA actualizado'),
  'requiere_fe': ('Requiere FE', 'Requiere FE actualizado'),
};

const _resultados = {
  'materiales_total': 'Total de materiales',
  'pago_proveedor': 'Pago proveedor',
  'saldo_transferir': 'Saldo a transferir',
  'comision_base': 'Comisión base',
  'comision_hulp_iva': 'Comisión Hulp + IVA',
  'comision_neta_hulp': 'Comisión neta Hulp',
  'iva_valor': 'IVA',
  'comision_efectiva': 'Comisión efectiva',
  'wompi_valor': 'Wompi',
  'ajuste_iva_valor': 'Valor del ajuste IVA',
  'total_cliente': 'Total cliente',
};

String? _texto(Object? value) {
  final texto = value?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}

String? _autor(Map? autor) {
  final origen = switch (autor?['rol']) {
    'proveedor' => 'App de proveedora',
    'administrador' => 'Web Admin',
    'usuario' => 'App del cliente',
    _ => null,
  };
  final nombre = _texto(autor?['nombre']);
  final partes = [origen, nombre].whereType<String>().join(' · ');
  return partes.isEmpty ? null : partes;
}

num? _numero(Object? valor) => num.tryParse(valor?.toString() ?? '');

final _decimales = NumberFormat.decimalPattern('es_CO')
  ..maximumFractionDigits = 6;

String _moneda(Object? valor) {
  final numero = _numero(valor);
  return numero == null ? '—' : '\$${_decimales.format(numero)}';
}

String _valorEditable(String campo, Object? valor) {
  return switch (campo) {
    'precio_base' || 'precio' || 'adelanto_proveedor' => _moneda(valor),
    'aplica_wompi' || 'aplica_ajuste_iva' || 'requiere_fe' => switch (valor) {
        true => 'Sí',
        false => 'No',
        _ => '—',
      },
    _ => _texto(valor) ?? '—',
  };
}

String _valorCalculado(String campo, Object? valor) {
  if (campo != 'comision_efectiva') return _moneda(valor);
  final numero = _numero(valor);
  return numero == null ? '—' : '${_decimales.format(numero)} %';
}

List<String> _items(Map entradas) => [
      for (final item in (entradas['items'] as List? ?? []).cast<Map>())
        '${item['tipo_item'] == 'material' ? 'Material' : 'Mano de obra'} · '
            '${_texto(item['descripcion']) ?? 'Ítem'} · '
            '${_decimales.format(_numero(item['cantidad']) ?? 0)} × '
            '${_moneda(item['precio_unitario'])}',
    ]..sort();

List<String> _itemsDistintos(List<String> origen, List<String> comparacion) {
  final pendientes = comparacion.toList();
  return [
    for (final item in origen)
      if (!pendientes.remove(item)) item
  ];
}

ActividadSolicitud? _actividadFinanciera(Map anterior, Map actual) {
  final entradasPrevias = anterior['entradas'] as Map;
  final entradasNuevas = actual['entradas'] as Map;
  final datosPrevios = entradasPrevias['datos'] as Map;
  final datosNuevos = entradasNuevas['datos'] as Map;
  final cambios = <CambioSolicitud>[];
  final titulos = <String>[];
  final cambioPrecio =
      _numero(datosPrevios['precio']) != _numero(datosNuevos['precio']);
  for (final MapEntry(:key, value: (campo, titulo))
      in _camposEditables.entries) {
    if (key == 'motivo_precio_pagado' && cambioPrecio) continue;
    final previo = _valorEditable(key, datosPrevios[key]);
    final nuevo = _valorEditable(key, datosNuevos[key]);
    if (previo == nuevo) continue;
    cambios.add((campo: campo, anterior: previo, nuevo: nuevo));
    titulos.add(titulo);
  }

  final itemsPrevios = _items(entradasPrevias);
  final itemsNuevos = _items(entradasNuevas);
  final retirados = _itemsDistintos(itemsPrevios, itemsNuevos);
  final agregados = _itemsDistintos(itemsNuevos, itemsPrevios);
  if (retirados.isNotEmpty || agregados.isNotEmpty) {
    cambios.add((
      campo: 'Materiales y adicionales',
      anterior: retirados.isEmpty ? '—' : retirados.join('\n'),
      nuevo: agregados.isEmpty ? '—' : agregados.join('\n'),
    ));
    titulos.add('Materiales y adicionales actualizados');
  }

  // Un recálculo puede cambiar valores guardados sin editar los campos.
  if (cambios.isEmpty) {
    final previo = anterior['resultados'] as Map;
    final nuevo = actual['resultados'] as Map;
    for (final MapEntry(:key, value: campo) in _resultados.entries) {
      final valorAnterior = _valorCalculado(key, previo[key]);
      final valorNuevo = _valorCalculado(key, nuevo[key]);
      if (valorAnterior == valorNuevo) continue;
      cambios.add((campo: campo, anterior: valorAnterior, nuevo: valorNuevo));
    }
  }
  if (cambios.isEmpty) return null;
  final motivoPrecio =
      cambioPrecio ? _texto(datosNuevos['motivo_precio_pagado']) : null;
  return ActividadSolicitud(
    tipo: TipoActividadSolicitud.financiera,
    titulo: titulos.length == 1
        ? titulos.single
        : 'Desglose financiero actualizado',
    fecha: DateTime.parse(actual['fecha'] as String),
    autor: _autor(actual['autor'] as Map?),
    motivo: motivoPrecio ?? _texto(actual['motivo']),
    cambios: cambios,
  );
}

List<ActividadSolicitud> leerActividadesSolicitud(Map historial) {
  final actividades = <ActividadSolicitud>[];
  final creacion = historial['creacion'] as Map?;
  if (creacion != null) {
    actividades.add(ActividadSolicitud(
      tipo: TipoActividadSolicitud.creada,
      titulo: 'Solicitud creada',
      fecha: DateTime.parse(creacion['fecha'] as String),
      autor: switch (creacion['tipo']) {
        'externo' => 'Web Admin',
        'app' => 'App del cliente',
        _ => null,
      },
    ));
  }
  for (final evento in (historial['eventos'] as List).cast<Map>()) {
    final operacion = _operaciones[evento['accion']];
    if (operacion == null) continue;
    actividades.add(ActividadSolicitud(
      tipo: operacion.$1,
      titulo: operacion.$2,
      fecha: DateTime.parse(evento['fecha'] as String),
      autor: _autor(evento['autor'] as Map?),
    ));
  }
  final revisiones = (historial['revisiones'] as List).cast<Map>().toList()
    ..sort((a, b) => (a['revision'] as int).compareTo(b['revision'] as int));
  for (var i = 1; i < revisiones.length; i++) {
    final actividad = _actividadFinanciera(revisiones[i - 1], revisiones[i]);
    if (actividad != null) actividades.add(actividad);
  }

  final ordenadas = actividades.indexed.toList()
    ..sort((a, b) {
      final fecha = b.$2.fecha.compareTo(a.$2.fecha);
      return fecha == 0 ? b.$1.compareTo(a.$1) : fecha;
    });
  return [for (final (_, actividad) in ordenadas) actividad];
}
