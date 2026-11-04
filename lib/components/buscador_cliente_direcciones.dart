import 'dart:async';
import 'package:flutter/material.dart';
import '/backend/direcciones_cliente.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/dialog_helpers.dart';
import 'agregar_direccion_cliente_widget.dart';

class SeleccionClienteDireccion {
  const SeleccionClienteDireccion(this.cliente, [this.direccion]);
  final UsuariosRow cliente;
  final DireccionCliente? direccion;
}

class BuscadorClienteDirecciones extends StatelessWidget {
  const BuscadorClienteDirecciones(
      {super.key,
      required this.clientes,
      required this.onSeleccion,
      this.usuarioId,
      this.repository});
  final List<UsuariosRow> clientes;
  final String? usuarioId;
  final ValueChanged<SeleccionClienteDireccion> onSeleccion;
  final DireccionesClienteRepository? repository;

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final cliente = clientes.where((c) => c.id == usuarioId).firstOrNull;
    final nombre = cliente == null
        ? null
        : '${cliente.nombres ?? ''} ${cliente.apellidos ?? ''}'.trim();
    return InkWell(
      key: const ValueKey('abrir_buscador_clientes'),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final seleccion = await showMapSafeDialog<SeleccionClienteDireccion>(
            context: context,
            builder: (_) => _ResultadosClienteDialog(config: this));
        if (context.mounted && seleccion != null) onSeleccion(seleccion);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
            color: const Color(0xFFFBFAF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tema.alternate, width: .5)),
        child: Row(children: [
          Expanded(
              child: Text(nombre ?? 'Seleccionar usuario...',
                  overflow: TextOverflow.ellipsis,
                  style: tema.bodyMedium.copyWith(
                      fontSize: 16,
                      color: nombre == null
                          ? const Color(0xFF8A8A8A)
                          : tema.primaryText))),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: tema.secondaryText, size: 24),
        ]),
      ),
    );
  }
}

class _ResultadosClienteDialog extends StatefulWidget {
  const _ResultadosClienteDialog({required this.config});
  final BuscadorClienteDirecciones config;
  @override
  State<_ResultadosClienteDialog> createState() => _BuscadorState();
}

class _BuscadorState extends State<_ResultadosClienteDialog> {
  late final _repo = widget.config.repository ?? DireccionesClienteRepository();
  late final _texto = TextEditingController();
  final _foco = FocusNode();
  List<UsuariosRow> _resultados = [];
  List<DireccionCliente> _direcciones = [];
  List<CiudadesRow> _ciudades = [];
  Future<List<CiudadesRow>>? _ciudadesRequest;
  Timer? _debounce;
  int _version = 0;
  bool _cargando = false;
  bool _error = false;
  bool _agregando = false;

  String _nombre(UsuariosRow c) =>
      '${c.nombres ?? ''} ${c.apellidos ?? ''}'.trim();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buscar('', inmediato: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _buscar(String texto, {bool inmediato = false}) {
    _debounce?.cancel();
    final version = ++_version;
    final q = texto.trim().toLowerCase();
    final digitos = q.replaceAll(RegExp(r'\D'), '');
    final resultados = widget.config.clientes
        .where((c) {
          final busqueda =
              '${_nombre(c)} ${c.telefono ?? ''} ${c.correoElectronico ?? ''}'
                  .toLowerCase();
          return busqueda.contains(q) ||
              (digitos.isNotEmpty &&
                  q.replaceAll(RegExp(r'[\d\s+()-]'), '').isEmpty &&
                  (c.telefono ?? '')
                      .replaceAll(RegExp(r'\D'), '')
                      .contains(digitos));
        })
        .take(8)
        .toList();
    setState(() {
      _resultados = resultados;
      _direcciones = [];
      _cargando = resultados.isNotEmpty;
      _error = false;
    });
    Future<void> cargar() async {
      if (resultados.isEmpty) return;
      try {
        final rows =
            await _repo.cargarClientes(resultados.map((c) => c.id).toList());
        final ciudades = await (_ciudadesRequest ??= _repo.ciudades());
        if (!mounted || version != _version) return;
        setState(() {
          _direcciones = rows;
          _ciudades = ciudades;
          _cargando = false;
        });
      } catch (_) {
        _ciudadesRequest = null;
        if (mounted && version == _version) {
          setState(() {
            _error = true;
            _cargando = false;
          });
        }
      }
    }

    if (inmediato) {
      unawaited(cargar());
    } else {
      _debounce = Timer(const Duration(milliseconds: 250), cargar);
    }
  }

  void _elegir(UsuariosRow cliente, [DireccionCliente? direccion]) {
    _debounce?.cancel();
    _version++;
    _foco.unfocus();
    Navigator.of(context).pop(SeleccionClienteDireccion(cliente, direccion));
  }

  Future<void> _agregar(UsuariosRow cliente) async {
    if (_agregando) return;
    _foco.unfocus();
    setState(() => _agregando = true);
    final direccion = await showDialog<DireccionCliente>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AgregarDireccionClienteWidget(
            usuarioId: cliente.id,
            nombreCliente: _nombre(cliente),
            repository: _repo));
    if (!mounted) return;
    setState(() => _agregando = false);
    if (direccion != null) _elegir(cliente, direccion);
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final borde = OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tema.alternate, width: .5));
    return Dialog(
      backgroundColor: tema.secondaryBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 620, maxHeight: MediaQuery.sizeOf(context).height * .75),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _texto,
                focusNode: _foco,
                autofocus: true,
                onChanged: _buscar,
                style: tema.bodyMedium.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Nombre, teléfono o correo',
                  prefixIcon: Icon(Icons.search, color: tema.secondaryText),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFFBFAF9),
                  enabledBorder: borde,
                  focusedBorder: borde.copyWith(
                      borderSide: BorderSide(color: tema.primary)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )),
              IconButton(
                  tooltip: 'Cerrar buscador',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: tema.secondaryText)),
            ]),
            Flexible(
                child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          border: Border.all(color: tema.alternate, width: .5),
                          borderRadius: BorderRadius.circular(8),
                          color: tema.secondaryBackground),
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            if (_resultados.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Sin resultados')),
                            if (_cargando)
                              LinearProgressIndicator(color: tema.primary),
                            if (_error)
                              Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(children: [
                                    Text(
                                        'No se pudieron cargar las direcciones.',
                                        style: tema.bodySmall
                                            .copyWith(color: tema.error)),
                                    TextButton(
                                        onPressed: () => _buscar(_texto.text,
                                            inmediato: true),
                                        child: const Text('Reintentar'))
                                  ])),
                            for (final cliente in _resultados) ...[
                              Material(
                                  color: tema.primary.withValues(alpha: .09),
                                  child: InkWell(
                                      key: ValueKey('cliente_${cliente.id}'),
                                      onTap: () => _elegir(cliente),
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '${_nombre(cliente)}${(cliente.ciudad ?? '').isEmpty ? '' : ' · ${cliente.ciudad}'}',
                                                    style: tema.bodyMedium
                                                        .copyWith(
                                                            color: tema.primary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16)),
                                                Text(
                                                    [
                                                      cliente.telefono,
                                                      cliente.correoElectronico
                                                    ]
                                                        .whereType<String>()
                                                        .where((v) =>
                                                            v.trim().isNotEmpty)
                                                        .join(' · '),
                                                    style: tema.bodySmall
                                                        .copyWith(
                                                            color: tema
                                                                .secondaryText)),
                                              ])))),
                              if (!_cargando && !_error) ...[
                                for (final direccion in _direcciones
                                    .where((d) => d.usuarioId == cliente.id))
                                  ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      key: ValueKey(
                                          'resultado_direccion_${direccion.id}'),
                                      title: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(
                                                text:
                                                    '${direccion.etiqueta} · ',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            TextSpan(text: direccion.completa),
                                          ]),
                                          style: tema.bodyMedium),
                                      subtitle: _ciudades
                                              .where((c) =>
                                                  c.id == direccion.ciudadId)
                                              .isEmpty
                                          ? null
                                          : Text(
                                              _ciudades
                                                  .firstWhere((c) =>
                                                      c.id ==
                                                      direccion.ciudadId)
                                                  .nombre,
                                              style: tema.bodySmall),
                                      onTap: () => _elegir(cliente, direccion)),
                                if (!_direcciones
                                    .any((d) => d.usuarioId == cliente.id))
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Text('Sin direcciones guardadas',
                                          style: tema.bodySmall.copyWith(
                                              color: tema.secondaryText))),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                        key: ValueKey(
                                            'agregar_direccion_${cliente.id}'),
                                        onPressed: _agregando
                                            ? null
                                            : () => _agregar(cliente),
                                        style: TextButton.styleFrom(
                                            foregroundColor: tema.primary),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text(
                                            'Agregar otra dirección'))),
                              ],
                              Divider(height: 1, color: tema.alternate),
                            ],
                            if (_resultados.length == 8)
                              Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                      'Escribe para afinar la búsqueda.',
                                      style: tema.bodySmall.copyWith(
                                          color: tema.secondaryText))),
                          ])),
                    ))),
          ]),
        ),
      ),
    );
  }
}
