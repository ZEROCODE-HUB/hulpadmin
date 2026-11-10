import 'dart:async';
import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import '/components/hulp_modal_actions.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/modal_con_encabezado_fijo.dart';

final _soloNumeroFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) =>
      RegExp(r'^\d*(?:[.,]\d*)?$').hasMatch(newValue.text)
          ? newValue
          : oldValue,
);

double? _parseNumeroEntrada(String? value) {
  final text = value?.trim().replaceAll(',', '.') ?? '';
  if (text.isEmpty || text == '.') return null;
  return double.tryParse(text);
}

bool _normalizarNumeroEntrada(TextEditingController controller) {
  final original = controller.text;
  var normalized = original.trim().replaceAll(',', '.');
  if (normalized.isEmpty || normalized == '.') {
    normalized = '0';
  } else {
    if (normalized.startsWith('.')) normalized = '0$normalized';
    if (normalized.endsWith('.')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
  }
  if (_parseNumeroEntrada(normalized) == null) normalized = '0';
  if (normalized == original) return false;
  controller.value = TextEditingValue(
    text: normalized,
    selection: TextSelection.collapsed(offset: normalized.length),
  );
  return true;
}

/// Editor de valores. Los resultados se solicitan al mismo cálculo del guardado.
class SolicitudFinanzasForm extends StatefulWidget {
  const SolicitudFinanzasForm(
      {super.key,
      required this.precioLista,
      this.solicitudId,
      this.soloLectura = false,
      this.disposicionCrear = false,
      this.permitirGuardar = false,
      this.previsualizar});
  final double precioLista;
  final String? solicitudId;
  final bool soloLectura;
  final bool disposicionCrear;
  final bool permitirGuardar;
  final Future<Map<String, dynamic>> Function(
      Map<String, dynamic>, List<Map<String, dynamic>>)? previsualizar;
  @override
  State<SolicitudFinanzasForm> createState() => SolicitudFinanzasFormState();
}

class SolicitudFinanzasFormState extends State<SolicitudFinanzasForm> {
  static const double _altoControlReferencia = 54;
  static final _formatoMonedaEntera = NumberFormat('#,##0', 'es_CO');
  static final _formatoMonedaDecimal = NumberFormat('#,##0.00', 'es_CO');
  static final _formatoPorcentaje = NumberFormat('#,##0.##', 'es_CO');
  static final _formatoCantidadEntera = NumberFormat('#,##0', 'es_CO');
  static final _formatoCantidadDecimal = NumberFormat('#,##0.##', 'es_CO');

  final _lista = TextEditingController();
  final _precio = TextEditingController();
  final _motivo = TextEditingController();
  final _adelanto = TextEditingController(text: '0');
  final _motivoAdelanto = TextEditingController();
  final _listaFocus = FocusNode();
  final _precioFocus = FocusNode();
  final _adelantoFocus = FocusNode();
  bool _tarjeta = false, _iva = false, _fe = false, _loading = false;
  String? _error;
  int? revision;
  int _generation = 0;
  Timer? _timer;
  List<Map<String, dynamic>> items = [];
  Map<String, dynamic> _resultados = {};
  bool _verMateriales = false;

  Map<String, dynamic> get entradas => {
        'precio_base': _parseNumeroEntrada(_lista.text),
        'precio': _parseNumeroEntrada(_precio.text),
        'motivo_precio_pagado': _motivo.text.trim(),
        'adelanto_proveedor': _parseNumeroEntrada(_adelanto.text),
        'adelanto_motivo': _motivoAdelanto.text.trim(),
        'aplica_wompi': _tarjeta,
        'aplica_ajuste_iva': _iva,
        'requiere_fe': _fe,
      };

  List<Map<String, dynamic>> get itemsGuardado => items
      .map((i) => {
            for (final k in [
              'tipo_item',
              'descripcion',
              'cantidad',
              'precio_unitario',
              'recibo_item_id'
            ])
              if (i[k] != null) k: i[k],
          })
      .toList();

  bool validar() {
    final normalizado = _normalizarCamposNumericos();
    if (normalizado) _cambio();
    final e = entradas;
    String? error;
    if (_loading) error = 'Espera a que cargue el desglose.';
    if ([e['precio_base'], e['precio'], e['adelanto_proveedor']]
        .any((v) => v == null || !(v as num).isFinite || v < 0)) {
      error = 'Revisa los importes: deben ser números positivos o cero.';
    } else if (e['precio_base'] != e['precio'] && _motivo.text.trim().isEmpty) {
      error = 'Indica el motivo del cambio de precio.';
    } else if ((e['adelanto_proveedor'] as num) > 0 &&
        _motivoAdelanto.text.trim().isEmpty) {
      error = 'Indica el motivo del adelanto.';
    }
    setState(() => _error = error);
    return error == null;
  }

  @override
  void initState() {
    super.initState();
    _listaFocus.addListener(_normalizarListaAlPerderFoco);
    _precioFocus.addListener(_normalizarPrecioAlPerderFoco);
    _adelantoFocus.addListener(_normalizarAdelantoAlPerderFoco);
    _lista.text = widget.precioLista.toString();
    _precio.text = widget.precioLista.toString();
    if (widget.solicitudId != null) {
      _cargar();
    } else {
      _preview();
    }
  }

  bool _normalizarCamposNumericos() {
    final lista = _normalizarNumeroEntrada(_lista);
    final precio = _normalizarNumeroEntrada(_precio);
    final adelanto = _normalizarNumeroEntrada(_adelanto);
    return lista || precio || adelanto;
  }

  void _normalizarAlPerderFoco(
      TextEditingController controller, FocusNode focusNode) {
    if (focusNode.hasFocus || !_normalizarNumeroEntrada(controller)) return;
    _cambio();
  }

  void _normalizarListaAlPerderFoco() =>
      _normalizarAlPerderFoco(_lista, _listaFocus);

  void _normalizarPrecioAlPerderFoco() =>
      _normalizarAlPerderFoco(_precio, _precioFocus);

  void _normalizarAdelantoAlPerderFoco() =>
      _normalizarAlPerderFoco(_adelanto, _adelantoFocus);

  @override
  void didUpdateWidget(covariant SolicitudFinanzasForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.solicitudId == null &&
        widget.precioLista != oldWidget.precioLista) {
      _lista.text = widget.precioLista.toString();
      _precio.text = widget.precioLista.toString();
      _cambio();
    }
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final response = await SupaFlow.client.functions.invoke(
          'solicitudes-finanzas',
          body: {'accion': 'leer', 'id': widget.solicitudId});
      if (!mounted) return;
      final data = Map<String, dynamic>.from(response.data as Map);
      final s = Map<String, dynamic>.from(data['solicitud'] as Map);
      revision = (s['finanzas_revision'] as num).toInt();
      _lista.text = '${s['precio_base']}';
      _precio.text = '${s['precio']}';
      _motivo.text = s['motivo_precio_pagado'] ?? '';
      _adelanto.text = '${s['adelanto_proveedor'] ?? 0}';
      _motivoAdelanto.text = s['adelanto_motivo'] ?? '';
      _tarjeta = s['aplica_wompi'] == true;
      _iva = s['aplica_ajuste_iva'] == true;
      _fe = s['requiere_fe'] == true;
      items = (data['items'] as List? ?? [])
          .map((i) => Map<String, dynamic>.from(i as Map))
          .toList();
      _resultados = s;
    } catch (e) {
      if (mounted) _error = 'No se pudo cargar el desglose. $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cambio() {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), _preview);
  }

  Future<void> _preview() async {
    final generation = ++_generation;
    final valores = entradas;
    if ([
      valores['precio'],
      valores['precio_base'],
      valores['adelanto_proveedor']
    ].any((value) => value is! num || !value.isFinite)) {
      if (mounted && generation == _generation) {
        setState(() => _resultados = {});
      }
      return;
    }
    try {
      final callback = widget.previsualizar;
      final Map<String, dynamic> resultado;
      if (callback != null) {
        resultado = await callback(entradas, itemsGuardado);
      } else {
        final response = await SupaFlow.client.functions
            .invoke('solicitudes-finanzas', body: {
          'accion': 'preview',
          'entradas': entradas,
          'items': itemsGuardado,
        });
        resultado = Map<String, dynamic>.from(response.data as Map);
      }
      if (mounted && generation == _generation) {
        setState(() {
          _resultados = resultado;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'No se pudo calcular el desglose. $e');
      }
    }
  }

  Future<void> _editarItem([int? index]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _SolicitudItemDialog(initial: index == null ? null : items[index]),
    );
    if (!mounted || result == null) return;
    if (index == null) {
      items.add(result);
    } else {
      items[index] = result;
    }
    _cambio();
  }

  Future<void> _guardar() async {
    await guardarCambios();
  }

  /// Permite guardar desde el pie general del modal.
  Future<bool> guardarCambios() async {
    if (!validar() || revision == null) return false;
    setState(() => _loading = true);
    try {
      await SupaFlow.client.functions.invoke('solicitudes-finanzas', body: {
        'accion': 'guardar',
        'id': widget.solicitudId,
        'revision': revision,
        'entradas': entradas,
        'items': itemsGuardado,
        'datos': <String, dynamic>{},
      });
      if (mounted) await _cargar();
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo guardar. $e';
        });
      }
      return false;
    }
  }

  Widget _campo(String label, TextEditingController controller,
          {bool numero = false}) =>
      SizedBox(
          width: 255,
          child: TextFormField(
            controller: controller,
            focusNode: numero ? _focusFor(controller) : null,
            inputFormatters: numero ? [_soloNumeroFormatter] : null,
            readOnly: widget.soloLectura || _loading,
            keyboardType: numero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: decorarInputHulp(
              context,
              InputDecoration(
                labelText: label,
                filled: true,
                fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              soloLectura: widget.soloLectura || _loading,
            ),
            onChanged: (_) => _cambio(),
          ));

  @override
  Widget build(BuildContext context) {
    if (widget.soloLectura) return _buildDetalleLectura(context);
    if (widget.disposicionCrear) return _buildDisposicionCrear(context);
    final theme = FlutterFlowTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Valores del servicio · editables', style: theme.titleMedium),
      const SizedBox(height: 16),
      if (_loading) const LinearProgressIndicator(),
      Wrap(spacing: 16, runSpacing: 16, children: [
        _campo('Precio lista (mano de obra)', _lista, numero: true),
        _campo('Precio pagado (acordado)', _precio, numero: true),
        _campo('Motivo del cambio', _motivo),
        _campo('Adelanto al proveedor', _adelanto, numero: true),
        _campo('Motivo del adelanto', _motivoAdelanto),
      ]),
      Wrap(spacing: 20, children: [
        _check('Paga por Wompi (+5 %)', _tarjeta, (v) => _tarjeta = v),
        _check('Ajuste IVA', _iva, (v) => _iva = v),
        _check('Requiere FE', _fe, (v) => _fe = v),
      ]),
      Text('Elegir Wompi estima el recargo; no registra un pago recibido.',
          style: theme.bodySmall),
      const SizedBox(height: 16),
      Text('Materiales y adicionales', style: theme.titleSmall),
      for (var index = 0; index < items.length; index++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${items[index]['descripcion']}'),
          subtitle: Text(
              '${items[index]['tipo_item']} · ${items[index]['cantidad']} × \$${items[index]['precio_unitario']}'),
          trailing: widget.soloLectura || items[index]['recibo_item_id'] != null
              ? (items[index]['recibo_item_id'] != null
                  ? const Text('Desde chat')
                  : null)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editarItem(index)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        items.removeAt(index);
                        _cambio();
                      })
                ]),
        ),
      if (!widget.soloLectura)
        OutlinedButton.icon(
            onPressed: () => _editarItem(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar ítem')),
      const SizedBox(height: 20),
      Text('Calculado por Hulp · no editable', style: theme.titleMedium),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 12, children: [
        for (final field in const {
          'materiales_total': 'Materiales',
          'pago_proveedor': 'Pago proveedor',
          'saldo_transferir': 'Saldo a transferir',
          'comision_hulp_iva': 'Comisión Hulp + IVA',
          'comision_neta_hulp': 'Comisión neta Hulp',
          'iva_valor': 'IVA',
          'comision_efectiva': 'Comisión efectiva (%)',
          'ajuste_iva_valor': 'Ajuste IVA',
          'wompi_valor': 'Wompi',
          'total_cliente': 'Total cliente',
        }.entries)
          SizedBox(
              width: 255,
              child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: field.value,
                      filled: true,
                      border: const OutlineInputBorder()),
                  child: Text(
                      _formatearResultado(field.key, _resultados[field.key]),
                      style: theme.bodyMedium))),
      ]),
      const SizedBox(height: 8),
      Text('El adelanto solo reduce el saldo a transferir.',
          style: theme.bodySmall),
      if (widget.permitirGuardar)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
                onPressed: _loading ? null : _guardar,
                child: const Text('Guardar desglose'))),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: theme.error))),
    ]);
  }

  Widget _buildDisposicionCrear(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Valores del servicio · editables', style: theme.titleMedium),
      const SizedBox(height: 20),
      if (_loading) const LinearProgressIndicator(),
      _rejillaReferencia([
        _entradaReferencia('Precio lista (mano de obra)', _lista, numero: true),
        _entradaReferencia('Precio pagado', _precio, numero: true),
        _entradaReferencia('Motivo del cambio', _motivo),
        _resultadoReferencia('Materiales', 'materiales_total',
            accion: IconButton(
              tooltip: 'Ver materiales y adicionales',
              onPressed: () => setState(() => _verMateriales = !_verMateriales),
              icon: const Icon(Icons.edit_outlined, size: 18),
            )),
      ]),
      const SizedBox(height: 16),
      _rejillaReferencia([
        _entradaReferencia('Adelanto al proveedor', _adelanto, numero: true),
        _entradaReferencia('Motivo del adelanto', _motivoAdelanto),
        _opcionReferencia(
            'Paga por Wompi (+5 %)', _tarjeta, (v) => _tarjeta = v),
        _opcionReferencia('Ajuste IVA', _iva, (v) => _iva = v),
        _opcionReferencia('Requiere FE', _fe, (v) => _fe = v),
      ], columnasEscritorio: 5),
      const SizedBox(height: 8),
      Text('Elegir Wompi estima el recargo; no registra un pago recibido.',
          style: theme.bodySmall),
      if (_verMateriales) ...[
        const SizedBox(height: 20),
        _seccionMateriales(context),
      ],
      const SizedBox(height: 28),
      Text('Calculado por Hulp · no editable', style: theme.titleMedium),
      const SizedBox(height: 20),
      _rejillaReferencia([
        _resultadoReferencia('Pago proveedor', 'pago_proveedor',
            ayuda: 'Precio lista × 72 %', destacado: true),
        _resultadoReferencia('Saldo a transferir', 'saldo_transferir',
            ayuda: 'Pago − adelanto', destacado: true),
        _resultadoReferencia('Comisión Hulp + IVA', 'comision_hulp_iva',
            ayuda: _iva ? 'Comisión + ajuste IVA' : 'Pagado − pago proveedor'),
        _resultadoReferencia('Comisión neta Hulp', 'comision_neta_hulp',
            ayuda: _iva ? 'Comisión base' : 'Comisión ÷ 1,19'),
        _resultadoReferencia('Comisión efectiva', 'comision_efectiva',
            ayuda: 'Comisión ÷ precio pagado', porcentaje: true),
        _resultadoReferencia('IVA', 'iva_valor',
            ayuda: 'Comisión − neta (19 %)'),
        _resultadoReferencia('Wompi', 'wompi_valor'),
        _resultadoReferencia('Ajuste IVA', 'ajuste_iva_valor'),
        _resultadoReferencia('Total cliente', 'total_cliente',
            ayuda: 'Pagado + materiales + Wompi + ajuste', destacado: true),
      ], columnasEscritorio: 3),
      const SizedBox(height: 8),
      Text('El adelanto solo reduce el saldo a transferir.',
          style: theme.bodySmall),
      if (widget.permitirGuardar)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
                onPressed: _loading ? null : _guardar,
                child: const Text('Guardar desglose'))),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: theme.error))),
    ]);
  }

  Widget _seccionMateriales(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final theme = FlutterFlowTheme.of(context);
          final compacto = constraints.maxWidth < 620;
          final agregar = OutlinedButton.icon(
            onPressed: _loading ? null : () => _editarItem(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar ítem'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compacto) ...[
                Text('Materiales y adicionales', style: theme.titleSmall),
                Align(alignment: Alignment.centerRight, child: agregar),
              ] else
                Row(
                  children: [
                    Text('Materiales y adicionales', style: theme.titleSmall),
                    const Spacer(),
                    agregar,
                  ],
                ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                _estadoVacioMateriales(theme)
              else if (compacto)
                Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0) const SizedBox(height: 8),
                      _tarjetaMaterial(index, theme),
                    ],
                  ],
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    border: Border.all(color: theme.alternate),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _cabeceraTablaMateriales(theme),
                      for (var index = 0; index < items.length; index++) ...[
                        if (index > 0)
                          Divider(height: 1, color: theme.alternate),
                        _filaTablaMateriales(index, theme),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      );

  Widget _estadoVacioMateriales(FlutterFlowTheme theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F2),
          border: Border.all(color: const Color(0xFFE2EEE4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF1E1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aún no hay materiales agregados',
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text('Agrega un ítem si aplica.',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      )),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _cabeceraTablaMateriales(FlutterFlowTheme theme) => Container(
        color: const Color(0xFFF6F5F2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
                flex: 5, child: _etiquetaColumnaMaterial('Descripción', theme)),
            Expanded(
                flex: 1, child: _etiquetaColumnaMaterial('Cantidad', theme)),
            Expanded(
                flex: 2,
                child: _etiquetaColumnaMaterial('Precio unitario', theme)),
            Expanded(
                flex: 2, child: _etiquetaColumnaMaterial('Subtotal', theme)),
            Expanded(flex: 2, child: _etiquetaColumnaMaterial('Origen', theme)),
            const SizedBox(width: 80),
          ],
        ),
      );

  Widget _etiquetaColumnaMaterial(String label, FlutterFlowTheme theme) => Text(
        label,
        style: theme.bodySmall.copyWith(
          color: theme.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _filaTablaMateriales(int index, FlutterFlowTheme theme) {
    final item = items[index];
    final cantidad = _numero(item['cantidad']) ?? 0;
    final precioUnitario = _numero(item['precio_unitario']) ?? 0;
    final subtotal = cantidad * precioUnitario;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['descripcion'] ?? 'Ítem sin descripción'}',
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_etiquetaTipoItem(item['tipo_item']),
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    )),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatearCantidad(cantidad),
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatearDinero(precioUnitario),
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatearDinero(subtotal),
              textAlign: TextAlign.center,
              style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _origenMaterial(item, theme),
            ),
          ),
          SizedBox(width: 80, child: _accionesMaterial(index, theme)),
        ],
      ),
    );
  }

  Widget _tarjetaMaterial(int index, FlutterFlowTheme theme) {
    final item = items[index];
    final cantidad = _numero(item['cantidad']) ?? 0;
    final precioUnitario = _numero(item['precio_unitario']) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['descripcion'] ?? 'Ítem sin descripción'}',
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(_etiquetaTipoItem(item['tipo_item']),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        )),
                  ],
                ),
              ),
              _accionesMaterial(index, theme),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Cantidad: ${_formatearCantidad(cantidad)}',
                  style: theme.bodySmall),
              Text('Precio unitario: ${_formatearDinero(precioUnitario)}',
                  style: theme.bodySmall),
              Text(
                'Subtotal: ${_formatearDinero(cantidad * precioUnitario)}',
                style: theme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              _origenMaterial(item, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _origenMaterial(Map<String, dynamic> item, FlutterFlowTheme theme) {
    final desdeChat = item['recibo_item_id'] != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: desdeChat ? const Color(0xFFE4F3E6) : const Color(0xFFF0EFEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        desdeChat ? 'Desde chat' : 'Manual',
        style: theme.bodySmall.copyWith(
          color: desdeChat ? theme.primary : theme.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _accionesMaterial(int index, FlutterFlowTheme theme) {
    if (items[index]['recibo_item_id'] != null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar ítem',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(Icons.edit_outlined, size: 18, color: theme.primary),
          onPressed: _loading ? null : () => _editarItem(index),
        ),
        IconButton(
          tooltip: 'Eliminar ítem',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(Icons.delete_outline, size: 18, color: theme.error),
          onPressed: _loading
              ? null
              : () {
                  items.removeAt(index);
                  _cambio();
                },
        ),
      ],
    );
  }

  Widget _buildDetalleLectura(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_loading && widget.solicitudId != null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          border: Border.all(color: const Color(0xFFE8B9B5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_error!, style: TextStyle(color: theme.error)),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final ancho = constraints.maxWidth;
      final columnasResumen = ancho >= 850
          ? 3
          : ancho >= 520
              ? 2
              : 1;
      final columnasDetalle = ancho >= 1020
          ? 3
          : ancho >= 680
              ? 2
              : 1;
      final resumenWidth =
          (ancho - 16 * (columnasResumen - 1)) / columnasResumen;
      final detalleWidth =
          (ancho - 16 * (columnasDetalle - 1)) / columnasDetalle;

      final resumen = [
        _tarjetaResumen(
          context,
          'Total cliente',
          _resultados['total_cliente'],
          Icons.account_balance_wallet_outlined,
          'Pagado + materiales + Wompi + ajuste',
        ),
        _tarjetaResumen(
          context,
          'Pago proveedor',
          _resultados['pago_proveedor'],
          Icons.credit_card_outlined,
          'Precio lista × 72 %',
        ),
        _tarjetaResumen(
          context,
          'Saldo a transferir',
          _resultados['saldo_transferir'],
          Icons.swap_horiz_rounded,
          'Pago − adelanto',
        ),
      ];

      final tarjetasDetalle = [
        _tarjetaValoresServicio(context),
        _tarjetaPagoProveedor(context),
        _tarjetaComisiones(context),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final tarjeta in resumen)
                SizedBox(width: resumenWidth, child: tarjeta),
            ],
          ),
          const SizedBox(height: 20),
          if (columnasDetalle == 3)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < tarjetasDetalle.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: index == tarjetasDetalle.length - 1 ? 0 : 8,
                            left: index == 0 ? 0 : 8),
                        child: tarjetasDetalle[index],
                      ),
                    ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final tarjeta in tarjetasDetalle)
                  SizedBox(width: detalleWidth, child: tarjeta),
              ],
            ),
        ],
      );
    });
  }

  Widget _tarjetaResumen(
    BuildContext context,
    String titulo,
    dynamic valor,
    IconData icono,
    String formula,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EF),
        border: Border.all(color: const Color(0xFFE3EEE1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF1E1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icono, color: theme.primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo, style: theme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  _formatearDinero(valor, decimalesFijos: true),
                  style: theme.titleLarge.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Text(
                  formula,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    height: 1.25,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDetalle(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required List<Widget> contenido,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF2F7F3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icono, color: theme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: contenido,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaValoresServicio(BuildContext context) => _tarjetaDetalle(
        context,
        titulo: 'Valores del servicio',
        icono: Icons.build_outlined,
        contenido: [
          _filaFinanciera(
            context,
            'Precio lista (mano de obra)',
            _formatearDinero(_lista.text),
          ),
          _filaFinanciera(
            context,
            'Precio pagado',
            _formatearDinero(_precio.text),
          ),
          _filaFinanciera(
            context,
            'Motivo del cambio',
            _motivo.text.trim().isEmpty ? '—' : _motivo.text.trim(),
          ),
          _filaMateriales(context),
          _filaFinanciera(context, 'Pago por Wompi (+5%)', _siNo(_tarjeta)),
          _filaFinanciera(context, 'Ajuste IVA', _siNo(_iva)),
          _filaFinanciera(context, 'Requiere FE', _siNo(_fe), ultimo: true),
        ],
      );

  Widget _tarjetaPagoProveedor(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _tarjetaDetalle(
      context,
      titulo: 'Pago al proveedor',
      icono: Icons.credit_card_outlined,
      contenido: [
        _filaFinanciera(
          context,
          'Pago proveedor',
          _formatearDinero(_resultados['pago_proveedor']),
        ),
        _filaFinanciera(
          context,
          'Adelanto',
          _formatearDinero(_adelanto.text),
        ),
        _filaFinanciera(
          context,
          'Motivo del adelanto',
          _motivoAdelanto.text.trim().isEmpty
              ? '—'
              : _motivoAdelanto.text.trim(),
          ultimo: true,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Saldo a transferir',
                  style: theme.bodyMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _formatearDinero(_resultados['saldo_transferir']),
                  textAlign: TextAlign.end,
                  style: theme.titleMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El adelanto solo reduce el saldo a transferir.',
          style: theme.bodySmall.copyWith(color: theme.secondaryText),
        ),
      ],
    );
  }

  Widget _tarjetaComisiones(BuildContext context) => _tarjetaDetalle(
        context,
        titulo: 'Comisión e impuestos',
        icono: Icons.percent_rounded,
        contenido: [
          _filaFinanciera(
            context,
            'Comisión neta Hulp',
            _formatearDinero(_resultados['comision_neta_hulp']),
          ),
          _filaFinanciera(
            context,
            'Comisión Hulp + IVA',
            _formatearDinero(_resultados['comision_hulp_iva']),
          ),
          _filaFinanciera(
            context,
            'IVA',
            _formatearDinero(_resultados['iva_valor']),
          ),
          _filaFinanciera(
            context,
            'Comisión efectiva',
            _formatearPorcentaje(_resultados['comision_efectiva']),
          ),
          _filaFinanciera(
            context,
            'Wompi',
            _formatearDinero(_resultados['wompi_valor']),
          ),
          _filaFinanciera(
            context,
            'Ajuste IVA',
            _formatearDinero(_resultados['ajuste_iva_valor']),
            ultimo: true,
          ),
        ],
      );

  Widget _filaMateriales(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hayMateriales = items.isNotEmpty;
    final contenido = <Widget>[
      Tooltip(
        message: _verMateriales
            ? 'Ocultar materiales y adicionales'
            : 'Ver materiales y adicionales',
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: hayMateriales
              ? () => setState(() => _verMateriales = !_verMateriales)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                if (hayMateriales) ...[
                  Icon(
                    _verMateriales ? Icons.expand_less : Icons.expand_more,
                    color: theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    'Materiales',
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatearDinero(_resultados['materiales_total']),
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_verMateriales)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sin materiales ni adicionales.',
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++)
                      _filaItemMaterial(context, items[index],
                          ultimo: index == items.length - 1),
                  ],
                ),
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: contenido,
      ),
    );
  }

  Widget _filaItemMaterial(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool ultimo,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final descripcion = item['descripcion']?.toString().trim();
    final tipo = _etiquetaTipoItem(item['tipo_item']);
    final cantidad = _formatearCantidad(item['cantidad']);
    final precioUnitario = _formatearDinero(item['precio_unitario']);
    final reciboId = item['recibo_item_id']?.toString().trim();
    final desdeChat = reciboId != null && reciboId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descripcion == null || descripcion.isEmpty
                    ? 'Adicional sin descripción'
                    : descripcion,
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$tipo · $cantidad × $precioUnitario',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                  if (desdeChat)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Desde chat', style: theme.bodySmall),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!ultimo) Divider(height: 1, color: theme.alternate),
      ],
    );
  }

  Widget _filaFinanciera(
    BuildContext context,
    String etiqueta,
    String valor, {
    bool ultimo = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(etiqueta, style: theme.bodyMedium, softWrap: true),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  valor,
                  textAlign: TextAlign.end,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
        if (!ultimo) Divider(height: 1, color: theme.alternate),
      ],
    );
  }

  String _siNo(bool valor) => valor ? 'Sí' : 'No';

  String _formatearDinero(dynamic valor, {bool decimalesFijos = false}) {
    final numero = _numero(valor);
    if (numero == null) return '—';
    final formato = decimalesFijos || numero % 1 != 0
        ? _formatoMonedaDecimal
        : _formatoMonedaEntera;
    return '\$${formato.format(numero)}';
  }

  String _formatearPorcentaje(dynamic valor) {
    final numero = _numero(valor);
    if (numero == null) return '—';
    return '${_formatoPorcentaje.format(numero)} %';
  }

  String _formatearResultado(String field, dynamic value) =>
      field == 'comision_efectiva'
          ? _formatearPorcentaje(value)
          : _formatearDinero(value);

  String _formatearCantidad(dynamic valor) {
    final numero = _numero(valor);
    if (numero == null) return valor?.toString() ?? '—';
    final formato =
        numero % 1 == 0 ? _formatoCantidadEntera : _formatoCantidadDecimal;
    return formato.format(numero);
  }

  num? _numero(dynamic valor) {
    if (valor is num) return valor;
    if (valor is String) {
      return num.tryParse(valor.trim().replaceAll(',', '.'));
    }
    return null;
  }

  FocusNode _focusFor(TextEditingController controller) {
    if (identical(controller, _lista)) return _listaFocus;
    if (identical(controller, _precio)) return _precioFocus;
    if (identical(controller, _adelanto)) return _adelantoFocus;
    throw ArgumentError('No hay FocusNode para este campo numérico');
  }

  String _etiquetaTipoItem(dynamic valor) {
    final tipo = valor?.toString().trim();
    if (tipo == null || tipo.isEmpty) return 'Adicional';
    return switch (tipo) {
      'material' => 'Material',
      'mano_obra' => 'Mano de obra',
      _ => tipo[0].toUpperCase() + tipo.substring(1),
    };
  }

  Widget _rejillaReferencia(
    List<Widget> children, {
    int columnasEscritorio = 4,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final desktopBreakpoint = switch (columnasEscritorio) {
            5 => 1100.0,
            4 => 1000.0,
            3 => 850.0,
            _ => 850.0,
          };
          final columns = constraints.maxWidth >= desktopBreakpoint * scale
              ? columnasEscritorio
              : constraints.maxWidth >= 600 * scale
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 20,
            children: [
              for (final child in children) SizedBox(width: width, child: child)
            ],
          );
        },
      );

  InputDecoration _decoracionReferencia({
    bool calculado = false,
    bool destacado = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: destacado ? theme.primary : theme.alternate,
        width: destacado ? 1.6 : 0.5,
      ),
    );
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      filled: true,
      fillColor: calculado ? const Color(0xFFF5F4F1) : const Color(0xFFFBFAF9),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border,
    );
  }

  Widget _entradaReferencia(String label, TextEditingController controller,
          {bool numero = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: FlutterFlowTheme.of(context).bodyMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: _altoControlReferencia,
          child: TextFormField(
            key: ValueKey('finanzas-entrada-$label'),
            controller: controller,
            focusNode: numero ? _focusFor(controller) : null,
            inputFormatters: numero ? [_soloNumeroFormatter] : null,
            readOnly: widget.soloLectura || _loading,
            keyboardType: numero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: decorarInputHulp(
              context,
              _decoracionReferencia(),
              etiqueta: label,
              soloLectura: widget.soloLectura || _loading,
            ),
            onChanged: (_) => _cambio(),
          ),
        ),
      ]);

  Widget _resultadoReferencia(String label, String field,
      {String? ayuda,
      Widget? accion,
      bool porcentaje = false,
      bool destacado = false}) {
    final value = _resultados[field];
    final theme = FlutterFlowTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: theme.bodyMedium.copyWith(
          fontWeight: destacado ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: _altoControlReferencia,
        child: InputDecorator(
          key: ValueKey('finanzas-resultado-$field'),
          decoration: _decoracionReferencia(
            calculado: accion == null,
            destacado: destacado,
          ).copyWith(suffixIcon: accion),
          child: Text(
            porcentaje
                ? _formatearPorcentaje(value)
                : _formatearDinero(value),
            style: theme.bodyMedium.copyWith(
              color: destacado ? theme.primary : theme.primaryText,
              fontWeight: destacado ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
      if (ayuda != null) ...[
        const SizedBox(height: 2),
        Text(ayuda,
            style: theme.bodySmall.copyWith(color: theme.secondaryText)),
      ],
    ]);
  }

  Widget _opcionReferencia(
          String label, bool value, void Function(bool) change) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: FlutterFlowTheme.of(context).bodyMedium),
        const SizedBox(height: 8),
        SizedBox(
          key: ValueKey('finanzas-opcion-$label'),
          height: _altoControlReferencia,
          child: InputDecorator(
            key: ValueKey('finanzas-opcion-decorator-$label'),
            decoration: _decoracionReferencia().copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Row(children: [
              Checkbox(
                activeColor: FlutterFlowTheme.of(context).primary,
                value: value,
                onChanged: widget.soloLectura || _loading
                    ? null
                    : (v) {
                        change(v!);
                        _cambio();
                      },
              ),
              Text(value ? 'Sí' : 'No'),
            ]),
          ),
        ),
      ]);

  Widget _check(String label, bool value, void Function(bool) change) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(
            activeColor: FlutterFlowTheme.of(context).primary,
            value: value,
            onChanged: widget.soloLectura || _loading
                ? null
                : (v) {
                    change(v!);
                    _cambio();
                  }),
        Text(label),
      ]);

  @override
  void dispose() {
    _timer?.cancel();
    _listaFocus.removeListener(_normalizarListaAlPerderFoco);
    _precioFocus.removeListener(_normalizarPrecioAlPerderFoco);
    _adelantoFocus.removeListener(_normalizarAdelantoAlPerderFoco);
    _listaFocus.dispose();
    _precioFocus.dispose();
    _adelantoFocus.dispose();
    for (final c in [_lista, _precio, _motivo, _adelanto, _motivoAdelanto]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _SolicitudItemDialog extends StatefulWidget {
  const _SolicitudItemDialog({this.initial});
  final Map<String, dynamic>? initial;
  @override
  State<_SolicitudItemDialog> createState() => _SolicitudItemDialogState();
}

class _SolicitudItemDialogState extends State<_SolicitudItemDialog> {
  late final TextEditingController _descripcion;
  late final TextEditingController _cantidad;
  late final TextEditingController _precio;
  final _cantidadFocus = FocusNode();
  final _precioFocus = FocusNode();
  late String _tipo;
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _descripcion =
        TextEditingController(text: widget.initial?['descripcion'] ?? '');
    _cantidad =
        TextEditingController(text: '${widget.initial?['cantidad'] ?? 1}');
    _precio = TextEditingController(
        text: '${widget.initial?['precio_unitario'] ?? 0}');
    _cantidadFocus.addListener(_normalizarCantidadAlPerderFoco);
    _precioFocus.addListener(_normalizarPrecioAlPerderFoco);
    _tipo = widget.initial?['tipo_item'] ?? 'material';
  }

  void _normalizarCantidadAlPerderFoco() {
    if (!_cantidadFocus.hasFocus && _normalizarNumeroEntrada(_cantidad)) {
      setState(() {});
    }
  }

  void _normalizarPrecioAlPerderFoco() {
    if (!_precioFocus.hasFocus && _normalizarNumeroEntrada(_precio)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cantidad = _parseNumeroEntrada(_cantidad.text) ?? 0;
    final precio = _parseNumeroEntrada(_precio.text) ?? 0;
    final total = cantidad * precio;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: theme.secondaryBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.alternate),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: ModalConEncabezadoFijo(
              encabezado: const EncabezadoModal(),
              cuerpo: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.initial == null ? 'Agregar Cobro' : 'Editar Cobro',
                      textAlign: TextAlign.center,
                      style: theme.headlineMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        for (final (tipo, label) in [
                          ('material', 'Material'),
                          ('mano_obra', 'Mano de Obra'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _tipo == tipo,
                            showCheckmark: false,
                            selectedColor: theme.primary,
                            backgroundColor: const Color(0xFFF7F4F4),
                            labelStyle: theme.bodyMedium.copyWith(
                              color: _tipo == tipo
                                  ? Colors.white
                                  : theme.secondaryText,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_tipo == tipo ? 20 : 8),
                            ),
                            onSelected: (_) => setState(() => _tipo = tipo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _campoItem(
                        'Descripción', 'Qué estás cobrando?', _descripcion,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Escribe una descripción'
                            : null),
                    const SizedBox(height: 16),
                    LayoutBuilder(builder: (context, constraints) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(16) / 16;
                      final campos = [
                        _campoItem('Cantidad', 'Cantidad', _cantidad,
                            focusNode: _cantidadFocus,
                            numero: true, validator: (v) => _numero(v, true)),
                        _campoItem('Precio por Unidad', 'Precio', _precio,
                            focusNode: _precioFocus,
                            numero: true, validator: (v) => _numero(v, false)),
                      ];
                      if (constraints.maxWidth < 300 * scale) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            campos[0],
                            const SizedBox(height: 16),
                            campos[1]
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: campos[0]),
                          const SizedBox(width: 12),
                          Expanded(child: campos[1]),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('Total:', style: theme.titleMedium),
                          Text(
                              total.isFinite
                                  ? total.toStringAsFixed(2)
                                  : '0.00',
                              style: theme.titleMedium
                                  .copyWith(color: theme.primary)),
                        ]),
                    if (_tipo == 'mano_obra') ...[
                      const SizedBox(height: 12),
                      Text(
                        'La mano de obra se detalla aquí y está contenida en el precio lista/acordado; no se vuelve a sumar.',
                        style: theme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 20),
                    hulpModalActionRow(
                      actions: [
                        hulpModalCloseButton(
                          text: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                        ),
                        hulpModalPrimaryButton(
                          context: context,
                          onPressed: _guardarItem,
                          text: widget.initial == null ? 'Agregar' : 'Guardar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoItem(String label, String hint, TextEditingController controller,
      {bool numero = false,
      FocusNode? focusNode,
      required String? Function(String?) validator}) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: theme.alternate),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: theme.bodyMedium),
      const SizedBox(height: 4),
      TextFormField(
        key: ValueKey('solicitud-item-$label'),
        controller: controller,
        focusNode: focusNode,
        inputFormatters: numero ? [_soloNumeroFormatter] : null,
        keyboardType: numero
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: decorarInputHulp(
          context,
          InputDecoration(
            hintText: hint,
            hintStyle: theme.bodyLarge.copyWith(color: theme.secondaryText),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            enabledBorder: border,
            border: border,
            focusedBorder:
                border.copyWith(borderSide: BorderSide(color: theme.primary)),
          ),
          etiqueta: label,
        ),
        validator: validator,
        onChanged: numero ? (_) => setState(() {}) : null,
      ),
    ]);
  }

  void _guardarItem() {
    final cantidadNormalizada = _normalizarNumeroEntrada(_cantidad);
    final precioNormalizado = _normalizarNumeroEntrada(_precio);
    if (cantidadNormalizada || precioNormalizado) setState(() {});
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'tipo_item': _tipo,
      'descripcion': _descripcion.text.trim(),
      'cantidad': _parseNumeroEntrada(_cantidad.text) ?? 0,
      'precio_unitario': _parseNumeroEntrada(_precio.text) ?? 0,
    });
  }

  String? _numero(String? text, bool positivo) {
    final n = _parseNumeroEntrada(text);
    return n == null || !n.isFinite || (positivo ? n <= 0 : n < 0)
        ? 'Revisa el importe'
        : null;
  }

  @override
  void dispose() {
    _cantidadFocus.removeListener(_normalizarCantidadAlPerderFoco);
    _precioFocus.removeListener(_normalizarPrecioAlPerderFoco);
    _cantidadFocus.dispose();
    _precioFocus.dispose();
    _descripcion.dispose();
    _cantidad.dispose();
    _precio.dispose();
    super.dispose();
  }
}
