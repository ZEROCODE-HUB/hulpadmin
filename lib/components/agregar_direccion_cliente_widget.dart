import '/backend/direcciones_cliente.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'selector_ubicacion_widget.dart';
import 'package:flutter/material.dart';

class AgregarDireccionClienteWidget extends StatefulWidget {
  const AgregarDireccionClienteWidget(
      {super.key,
      required this.usuarioId,
      required this.nombreCliente,
      required this.repository});
  final String usuarioId;
  final String nombreCliente;
  final DireccionesClienteRepository repository;
  @override
  State<AgregarDireccionClienteWidget> createState() =>
      _AgregarDireccionState();
}

class _AgregarDireccionState extends State<AgregarDireccionClienteWidget> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _complemento = TextEditingController();
  final _referencia = TextEditingController();
  late final Future<List<CiudadesRow>> _ciudades =
      widget.repository.ciudades(soloActivas: true);
  int _revisionMapa = 0;
  String _tipo = 'casa';
  String? _ciudad;
  Coordenadas? _punto;
  bool _guardando = false;
  String? _error;
  @override
  void dispose() {
    for (final controller in [_nombre, _direccion, _complemento, _referencia]) {
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
      final result = await widget.repository.guardar({
        'usuario_id': widget.usuarioId,
        'tipo': _tipo,
        'nombre': _tipo == 'otra' ? _nombre.text.trim() : null,
        'direccion': _direccion.text.trim(),
        'complemento': _complemento.text.trim(),
        'referencia': _referencia.text.trim(),
        'ciudad_id': _ciudad,
        'latitud': _punto?.latitud,
        'longitud': _punto?.longitud,
      });
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted)
        setState(() {
          _guardando = false;
          _error =
              'No se pudo guardar la dirección. Revisa los datos e intenta nuevamente.';
        });
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
        _etiqueta('Ciudad *'),
        FutureBuilder<List<CiudadesRow>>(
          future: _ciudades,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                  'No se pudieron cargar las ciudades. Cierra y vuelve a intentar.',
                  style: tema.bodyMedium.copyWith(color: tema.error));
            }
            return DropdownButtonFormField<String>(
              initialValue: _ciudad,
              isExpanded: true,
              style: tema.bodyMedium.copyWith(fontSize: 16),
              decoration: _decoracion(snapshot.hasData
                  ? 'Seleccionar ciudad...'
                  : 'Cargando ciudades...'),
              dropdownColor: tema.secondaryBackground,
              items: [
                for (final c in snapshot.data ?? <CiudadesRow>[])
                  DropdownMenuItem(value: c.id, child: Text(c.nombre))
              ],
              onChanged: _guardando || !snapshot.hasData
                  ? null
                  : (v) => setState(() {
                        _ciudad = v;
                        _punto = null;
                      }),
              validator: (v) => v == null ? 'Selecciona una ciudad' : null,
            );
          },
        ),
      ],
    );
  }

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
                    child: Text('Agregar dirección',
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
                                  _mapa()
                                ]);
                          }
                          return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _campos()),
                                const SizedBox(width: 24),
                                Expanded(child: _mapa()),
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
                text: _guardando ? 'Guardando…' : 'Guardar dirección',
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
