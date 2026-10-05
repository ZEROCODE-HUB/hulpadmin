import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/web/menu/menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ciudades_model.dart';
export 'ciudades_model.dart';

/// Mantenimiento de las ciudades en las que opera Hulp.
///
/// Esta tabla la consumen el registro de Talento, el alta de proveedores y
/// clientes, y el formulario de solicitudes: lo que se añada aquí aparece
/// solo en todos esos sitios.
class CiudadesWidget extends StatefulWidget {
  const CiudadesWidget({super.key});

  static String routeName = 'Ciudades';
  static String routePath = '/ciudades';

  @override
  State<CiudadesWidget> createState() => _CiudadesWidgetState();
}

class _CiudadesWidgetState extends State<CiudadesWidget> {
  late CiudadesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CiudadesModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _model.cargar();
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _aviso(String mensaje, {bool exito = false}) {
    final tema = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: tema.primaryBackground)),
        duration: const Duration(milliseconds: 4000),
        backgroundColor: exito ? tema.primary : tema.error,
      ),
    );
  }

  /// Alta y edición comparten formulario: cambia el título y poco más.
  Future<void> _abrirFormulario({CiudadesRow? ciudad}) async {
    final tema = FlutterFlowTheme.of(context);
    final nombreCtrl = TextEditingController(text: ciudad?.nombre ?? '');
    bool activo = ciudad?.activo ?? true;
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) => AlertDialog(
          backgroundColor: tema.secondaryBackground,
          title: Text(
            ciudad == null ? 'Nueva ciudad' : 'Editar ciudad',
            style: tema.headlineSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              fontSize: 20.0,
            ),
          ),
          content: SizedBox(
            width: 380.0,
            // Con scroll: en pantallas bajas una Column suelta se recorta sin
            // avisar y deja campos fuera de la vista.
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreCtrl,
                  autofocus: true,
                  enabled: !guardando,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Bogotá D.C.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6.0),
                SwitchListTile(
                  value: activo,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  // Una ciudad inactiva desaparece de los formularios pero no
                  // rompe las solicitudes ni los proveedores que ya la tienen.
                  subtitle: const Text(
                    'Si se desactiva, deja de ofrecerse al registrarse o al crear solicitudes',
                    style: TextStyle(fontSize: 12.0),
                  ),
                  onChanged: guardando
                      ? null
                      : (val) => actualizar(() => activo = val),
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: guardando
                  ? null
                  : () async {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty) {
                        _aviso('El nombre no puede estar vacío');
                        return;
                      }
                      // El nombre es la clave con la que cruzan las fichas de
                      // usuario, que lo guardan como texto: no puede repetirse.
                      final repetida = _model.ciudades.any((c) =>
                          c.id != ciudad?.id &&
                          c.nombre.toLowerCase() == nombre.toLowerCase());
                      if (repetida) {
                        _aviso('Ya existe una ciudad con ese nombre');
                        return;
                      }

                      actualizar(() => guardando = true);
                      try {
                        if (ciudad == null) {
                          await CiudadesTable().insert({
                            'nombre': nombre,
                            'activo': activo,
                            // La columna provincia_id viene del esquema viejo y
                            // no se pide en el formulario: si sigue siendo
                            // obligatoria se rellena sola, y si no, va nula.
                            if (_model.provinciaPorDefecto != null)
                              'provincia_id': _model.provinciaPorDefecto,
                          });
                        } else {
                          await CiudadesTable().update(
                            data: {
                              'nombre': nombre,
                              'activo': activo,
                            },
                            matchingRows: (rows) =>
                                rows.eqOrNull('id', ciudad.id),
                          );
                          // Las fichas guardan el nombre, no el id: si cambia,
                          // hay que arrastrarlo o quedan huérfanas.
                          if (ciudad.nombre != nombre) {
                            await UsuariosTable().update(
                              data: {'ciudad': nombre},
                              matchingRows: (rows) =>
                                  rows.eqOrNull('ciudad', ciudad.nombre),
                            );
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _model.cargar();
                        safeSetState(() {});
                        _aviso(
                            ciudad == null
                                ? 'Ciudad creada'
                                : 'Ciudad actualizada',
                            exito: true);
                      } catch (e) {
                        actualizar(() => guardando = false);
                        _aviso('No se pudo guardar: $e');
                      }
                    },
              child: Text(guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    nombreCtrl.dispose();
  }

  Future<void> _eliminar(CiudadesRow ciudad) async {
    final usos = await _model.usosDe(ciudad);
    if (!mounted) return;

    // Borrar una ciudad en uso deja solicitudes sin referencia y proveedores
    // con una ciudad que ya no existe; en ese caso se ofrece desactivarla.
    final enUso = usos.solicitudes > 0 || usos.usuarios > 0;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enUso ? 'Esta ciudad está en uso' : 'Eliminar ciudad'),
        content: Text(
          enUso
              ? '«${ciudad.nombre}» la usan ${usos.solicitudes} solicitud(es) y '
                  '${usos.usuarios} usuario(s).\n\nSi la eliminas, esas '
                  'solicitudes se quedan sin ciudad y esos usuarios con una '
                  'ciudad que ya no existe. Lo recomendable es desactivarla.'
              : '¿Eliminar «${ciudad.nombre}»? No la usa ninguna solicitud ni '
                  'ningún usuario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          if (enUso)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx, false);
                await CiudadesTable().update(
                  data: {'activo': false},
                  matchingRows: (rows) => rows.eqOrNull('id', ciudad.id),
                );
                await _model.cargar();
                safeSetState(() {});
                _aviso('Ciudad desactivada', exito: true);
              },
              child: const Text('Desactivar'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    try {
      await CiudadesTable().delete(
        matchingRows: (rows) => rows.eqOrNull('id', ciudad.id),
      );
      await _model.cargar();
      safeSetState(() {});
      _aviso('Ciudad eliminada', exito: true);
    } catch (e) {
      _aviso('No se pudo eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: tema.secondaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0.0, -1.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                wrapWithModel(
                  model: _model.menuModel,
                  updateCallback: () => safeSetState(() {}),
                  child: MenuWidget(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 72.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEECE8),
                          border: Border.all(
                              color: const Color(0xFFD9C19C), width: 0.5),
                        ),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            40.0, 0.0, 40.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ciudades',
                              style: tema.headlineMedium.override(
                                font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600),
                                fontSize: 24.0,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add, size: 18.0),
                              label: const Text('Agregar ciudad'),
                              style: FilledButton.styleFrom(
                                backgroundColor: tema.primary,
                                minimumSize: const Size(0, 44.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (_model.cargando) {
                              return Center(
                                child: SizedBox(
                                  width: 50.0,
                                  height: 50.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        tema.primary),
                                  ),
                                ),
                              );
                            }
                            if (_model.error != null) {
                              return Center(child: Text(_model.error!));
                            }
                            if (_model.ciudades.isEmpty) {
                              return const Center(
                                  child: Text('Todavía no hay ciudades'));
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  40.0, 24.0, 40.0, 24.0),
                              itemCount: _model.ciudades.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8.0),
                              itemBuilder: (context, i) {
                                final ciudad = _model.ciudades[i];
                                final activa = ciudad.activo ?? false;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: tema.primaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                        color: const Color(0xFFD9C19C),
                                        width: 0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          ciudad.nombre,
                                          style: tema.bodyMedium.override(
                                            font: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600),
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Icon(
                                              activa
                                                  ? Icons.check_circle
                                                  : Icons.remove_circle_outline,
                                              size: 18.0,
                                              color: activa
                                                  ? tema.primary
                                                  : tema.secondaryText,
                                            ),
                                            const SizedBox(width: 6.0),
                                            Text(
                                                activa ? 'Activa' : 'Inactiva'),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _abrirFormulario(ciudad: ciudad),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar',
                                        icon: Icon(Icons.delete_outline,
                                            color: tema.error),
                                        onPressed: () => _eliminar(ciudad),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
