import '/backend/direcciones_cliente.dart';
import '/backend/quick_add_cliente.dart';
import 'package:uuid/uuid.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'selector_ubicacion_widget.dart';
import 'searchable_dropdown_widget.dart';
import 'package:flutter/material.dart';

class AgregarDireccionClienteWidget extends StatefulWidget {
  const AgregarDireccionClienteWidget(
      {super.key,
      required this.usuarioId,
      required this.nombreCliente,
      required this.repository,
      this.quickAdd,
      this.nombreInicial = '',
      this.telefonoInicial = '',
      this.ciudadInicial});
  final String usuarioId;
  final String nombreCliente;
  final DireccionesClienteRepository repository;
  final QuickAddClienteRepository? quickAdd;
  final String nombreInicial;
  final String telefonoInicial;
  final String? ciudadInicial;
  @override
  State<AgregarDireccionClienteWidget> createState() =>
      _AgregarDireccionState();
}

class _AgregarDireccionState extends State<AgregarDireccionClienteWidget> {
  final _form = GlobalKey<FormState>();
  late final _cliente = TextEditingController(text: widget.nombreInicial);
  final _apellido = TextEditingController();
  late final _telefono = TextEditingController(text: widget.telefonoInicial);
  final _requestId = const Uuid().v4();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _complemento = TextEditingController();
  final _referencia = TextEditingController();
  late final Future<List<CiudadesRow>> _ciudades =
      widget.repository.ciudades(soloActivas: true).then((rows) {
    if (!rows.any((c) => c.id == _ciudad)) _ciudad = null;
    return rows;
  });
  int _revisionMapa = 0;
  String _tipo = 'casa';
  late String? _ciudad = widget.ciudadInicial;
  Coordenadas? _punto;
  bool _guardando = false;
  String? _error;
  @override
  void dispose() {
    for (final controller in [
      _cliente,
      _apellido,
      _telefono,
      _nombre,
      _direccion,
      _complemento,
      _referencia
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final datos = <String, dynamic>{
        'usuario_id': widget.usuarioId,
        'tipo': _tipo,
        'nombre': _tipo == 'otra' ? _nombre.text.trim() : null,
        'direccion': _direccion.text.trim(),
        'complemento': _complemento.text.trim(),
        'referencia': _referencia.text.trim(),
        'ciudad_id': _ciudad,
        'latitud': _punto?.latitud,
        'longitud': _punto?.longitud,
      };
      if (widget.quickAdd != null) {
        final result = await widget.quickAdd!.crear(
            requestId: _requestId,
            nombre: _cliente.text,
            apellido: _apellido.text,
            telefono: _telefono.text,
            direccion: datos);
        if (!mounted) return;
        if (result.existente) {
          final usar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Cliente existente'),
                    content: Text('Este celular pertenece a ${[
                      result.cliente.nombres,
                      result.cliente.apellidos
                    ].whereType<String>().join(' ')}. ¿Quieres usar ese cliente?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Volver')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Usar cliente existente')),
                    ],
                  ));
          if (!mounted) return;
          if (usar != true) {
            setState(() => _guardando = false);
            return;
          }
        }
        if (mounted) Navigator.of(context).pop(result);
        return;
      }
      final result = await widget.repository.guardar(datos);
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = error is QuickAddException
              ? error.message
              : widget.quickAdd != null
                  ? 'No se pudo crear el cliente. Tus datos se conservan; vuelve a guardar.'
                  : 'No se pudo guardar la dirección. Revisa los datos e intenta nuevamente.';
        });
      }
    }
  }

  InputDecoration _decoracion(String hint) {
    final tema = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: tema.alternate, width: .5),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: tema.labelMedium
          .copyWith(color: const Color(0xFF8A8A8A), fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFFBFAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder:
          border.copyWith(borderSide: BorderSide(color: tema.primary)),
      errorBorder: border.copyWith(borderSide: BorderSide(color: tema.error)),
      focusedErrorBorder:
          border.copyWith(borderSide: BorderSide(color: tema.error)),
    );
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style:
                FlutterFlowTheme.of(context).bodyMedium.copyWith(fontSize: 16)),
      );

  Widget _campo(String etiqueta, String hint, TextEditingController controller,
          {String? Function(String?)? validator,
          ValueChanged<String>? onChanged}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _etiqueta(etiqueta),
          TextFormField(
            controller: controller,
            enabled: !_guardando,
            style:
                FlutterFlowTheme.of(context).bodyMedium.copyWith(fontSize: 16),
            decoration: _decoracion(hint),
            validator: validator,
            onChanged: onChanged,
          ),
        ]),
      );

  Widget _campos() {
    final tema = FlutterFlowTheme.of(context);
    return Column(
      key: const ValueKey('campos_direccion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.quickAdd != null) ...[
          _campo('Nombre *', 'Nombre del cliente', _cliente,
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Escribe el nombre'
                  : v!.trim().length > 200
                      ? 'Usa hasta 200 caracteres'
                      : null),
          _campo('Apellido *', 'Apellido del cliente', _apellido,
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Escribe el apellido'
                  : v!.trim().length > 200
                      ? 'Usa hasta 200 caracteres'
                      : null),
          _campo('Celular *', '300 123 4567', _telefono,
              validator: (v) => RegExp(r'^573\d{9}$')
                      .hasMatch(normalizarCelularCliente(v ?? ''))
                  ? null
                  : 'Ingresa un celular colombiano de 10 dígitos'),
        ],
        _etiqueta('Tipo *'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tipo in ['casa', 'oficina', 'otra'])
            ChoiceChip(
              label: Text({
                'casa': 'Casa',
                'oficina': 'Oficina',
                'otra': 'Otra'
              }[tipo]!),
              selected: _tipo == tipo,
              showCheckmark: false,
              selectedColor: tema.primary,
              backgroundColor: const Color(0xFFFBFAF9),
              labelStyle: tema.bodyMedium.copyWith(
                  fontSize: 16,
                  color: _tipo == tipo ? Colors.white : tema.primaryText),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              side: BorderSide(
                  color: _tipo == tipo ? tema.primary : tema.alternate,
                  width: .5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              onSelected:
                  _guardando ? null : (_) => setState(() => _tipo = tipo),
            ),
        ]),
        const SizedBox(height: 16),
        if (_tipo == 'otra')
          _campo('Nombre de la dirección *', 'Ej. Casa de la mamá', _nombre,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un nombre' : null),
        _campo('Dirección *', 'Calle y número', _direccion,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Escribe la dirección' : null,
            onChanged: (_) => setState(() {
                  if (_punto != null) _revisionMapa++;
                  _punto = null;
                })),
        _campo('Apto, torre, edificio, conjunto u oficina (opcional)',
            'Ej. Apto 712, Torre A', _complemento),
        _campo('Referencia de llegada (opcional)', 'Ej. Portería norte',
            _referencia),
        if (widget.quickAdd == null) _campoCiudad(),
      ],
    );
  }

  Widget _campoCiudad() {
    final tema = FlutterFlowTheme.of(context);
    return Column(
      key: const ValueKey('ciudad_direccion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta('Ciudad *'),
        FutureBuilder<List<CiudadesRow>>(
          future: _ciudades,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                  'No se pudieron cargar las ciudades. Cierra y vuelve a intentar.',
                  style: tema.bodyMedium.copyWith(color: tema.error));
            }
            final ciudades = snapshot.data ?? <CiudadesRow>[];
            return FormField<String>(
              key: ValueKey('ciudad_cargada_${snapshot.hasData}'),
              initialValue: _ciudad,
              validator: (v) => !snapshot.hasData || v == null
                  ? 'Selecciona una ciudad'
                  : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AbsorbPointer(
                    absorbing: _guardando || !snapshot.hasData,
                    child: SearchableDropdown(
                      values: ciudades.map((c) => c.id).toList(),
                      labels: ciudades.map((c) => c.nombre).toList(),
                      selectedValue: field.value,
                      hint: snapshot.hasData
                          ? 'Seleccionar ciudad...'
                          : 'Cargando ciudades...',
                      searchHint: 'Buscar ciudad...',
                      onChanged: (v) {
                        field.didChange(v);
                        setState(() {
                          _ciudad = v;
                          _punto = null;
                        });
                      },
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(field.errorText!,
                          style: tema.bodySmall.copyWith(color: tema.error)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _columnaMapa() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.quickAdd != null) ...[
            _campoCiudad(),
            const SizedBox(height: 16),
          ],
          _mapa(),
        ],
      );

  Widget _mapa() => AbsorbPointer(
        key: const ValueKey('mapa_direccion'),
        absorbing: _guardando,
        child: SelectorUbicacionWidget(
          key: ValueKey('mapa_${_ciudad}_$_revisionMapa'),
          ciudadId: _ciudad,
          direccionActual: () => _direccion.text,
          onDireccionSugerida: (v) {
            _direccion.text = v;
          },
          onCambio: (p) {
            _punto = p;
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final estrecho = MediaQuery.sizeOf(context).width < 600;
    return PopScope(
      canPop: !_guardando,
      child: Dialog(
        backgroundColor: tema.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        insetPadding:
            EdgeInsets.symmetric(horizontal: estrecho ? 8 : 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: EdgeInsets.all(estrecho ? 16 : 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const SizedBox(width: 48),
                Expanded(
                    child: Text(
                        widget.quickAdd == null
                            ? 'Agregar dirección'
                            : 'Crear cliente nuevo',
                        textAlign: TextAlign.center,
                        style: tema.bodyMedium.copyWith(
                            fontSize: 22, fontWeight: FontWeight.w500))),
                IconButton(
                  tooltip: 'Cerrar',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: tema.primaryText, size: 24),
                ),
              ]),
              if (widget.quickAdd == null)
                Text('Cliente: ${widget.nombreCliente}',
                    textAlign: TextAlign.center,
                    style: tema.bodyMedium
                        .copyWith(fontSize: 16, color: tema.secondaryText)),
              const SizedBox(height: 20),
              Flexible(
                  child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 650) {
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _campos(),
                                  const SizedBox(height: 24),
                                  _columnaMapa()
                                ]);
                          }
                          return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _campos()),
                                const SizedBox(width: 24),
                                Expanded(child: _columnaMapa()),
                              ]);
                        }),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_error!,
                                    style: tema.bodyMedium
                                        .copyWith(color: tema.error))),
                          ),
                      ],
                    )),
              )),
              const SizedBox(height: 20),
              FFButtonWidget(
                onPressed: _guardando ? null : _guardar,
                text: _guardando
                    ? 'Guardando…'
                    : widget.quickAdd == null
                        ? 'Guardar dirección'
                        : 'Crear y seleccionar cliente',
                options: FFButtonOptions(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: tema.primary,
                  textStyle: tema.titleSmall
                      .copyWith(color: Colors.white, fontSize: 16),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
