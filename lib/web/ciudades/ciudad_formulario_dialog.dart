import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Termina cuando la ruta ha retirado también su animación y overlay.
Future<bool> mostrarFormularioCiudad({
  required BuildContext context,
  String? nombreInicial,
  bool activoInicial = true,
  required String? Function(String nombre) validarNombre,
  required Future<void> Function(String nombre, bool activo) onGuardar,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final ruta = DialogRoute<bool>(
    context: context,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (_) => CiudadFormularioDialog(
      nombreInicial: nombreInicial,
      activoInicial: activoInicial,
      validarNombre: validarNombre,
      onGuardar: onGuardar,
    ),
  );
  final guardado = await navigator.push(ruta);
  await ruta.completed;
  return guardado == true;
}

class CiudadFormularioDialog extends StatefulWidget {
  const CiudadFormularioDialog({
    super.key,
    this.nombreInicial,
    this.activoInicial = true,
    required this.validarNombre,
    required this.onGuardar,
  });

  final String? nombreInicial;
  final bool activoInicial;
  final String? Function(String nombre) validarNombre;
  final Future<void> Function(String nombre, bool activo) onGuardar;

  @override
  State<CiudadFormularioDialog> createState() => _CiudadFormularioDialogState();
}

class _CiudadFormularioDialogState extends State<CiudadFormularioDialog> {
  late final TextEditingController _nombre;
  late bool _activo;
  bool _guardando = false;
  bool _cerrando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial ?? '');
    _activo = widget.activoInicial;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || _cerrando) return;
    final nombre = _nombre.text.trim();
    final error = widget.validarNombre(nombre);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(nombre, _activo);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar: $e';
      });
      return;
    }
    if (!mounted) return;
    // PopScope debe actualizarse antes de permitir el cierre tras guardar.
    setState(() {
      _guardando = false;
      _cerrando = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return PopScope(
      canPop: !_guardando,
      child: AlertDialog(
        backgroundColor: tema.secondaryBackground,
        title: Text(
          widget.nombreInicial == null ? 'Nueva ciudad' : 'Editar ciudad',
          style: tema.headlineSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            fontSize: 20.0,
          ),
        ),
        content: SizedBox(
          width: 380.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nombre,
                  autofocus: true,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Bogotá D.C.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6.0),
                SwitchListTile(
                  value: _activo,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  subtitle: const Text(
                    'Si se desactiva, deja de ofrecerse al registrarse o al crear solicitudes',
                    style: TextStyle(fontSize: 12.0),
                  ),
                  onChanged:
                      _guardando ? null : (v) => setState(() => _activo = v),
                ),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: tema.error)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _guardando || _cerrando
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _guardando || _cerrando ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
