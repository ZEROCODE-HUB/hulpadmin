import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import '/components/hulp_modal_actions.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lo que devuelve el selector.
///
/// Cerrarlo sin decidir devuelve `null`, que significa cancelar: no se
/// finaliza nada. Es distinto de elegir «finalizar sin profesional», que sí
/// es una decisión y se representa con [SeleccionProfesional.sinAsignar].
class SeleccionProfesional {
  const SeleccionProfesional.asignar(String this.profesionalId)
      : sinProfesional = false;

  const SeleccionProfesional.sinAsignar()
      : profesionalId = null,
        sinProfesional = true;

  final String? profesionalId;
  final bool sinProfesional;
}

/// Abre el selector y devuelve la decisión del administrador.
///
/// Se usa al finalizar una solicitud que no tiene profesional asignado, que es
/// lo que pasa con todas las que quedaron colgando tras dar de baja a un
/// proveedor: al borrarlo, su `profesional_id` se pone a nulo.
Future<SeleccionProfesional?> mostrarSelectorDeProfesional(
  BuildContext context, {
  required String? servicioId,
  String? servicioNombre,
}) {
  return showDialog<SeleccionProfesional>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment:
          AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
      child: SeleccionarProfesionalWidget(
        servicioId: servicioId,
        servicioNombre: servicioNombre,
      ),
    ),
  );
}

class SeleccionarProfesionalWidget extends StatefulWidget {
  const SeleccionarProfesionalWidget({
    super.key,
    required this.servicioId,
    this.servicioNombre,
  });

  /// Servicio del catálogo, para ofrecer solo a quien lo presta.
  final String? servicioId;
  final String? servicioNombre;

  @override
  State<SeleccionarProfesionalWidget> createState() =>
      _SeleccionarProfesionalWidgetState();
}

class _SeleccionarProfesionalWidgetState
    extends State<SeleccionarProfesionalWidget> {
  late Future<List<VwProfesionalesCompletoRow>> _consulta;
  final _buscarController = TextEditingController();
  String _busqueda = '';
  String? _elegido;

  @override
  void initState() {
    super.initState();
    _consulta = _cargarProfesionales();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  /// Solo proveedores **aprobados** que ofrezcan este servicio.
  ///
  /// Se consulta `vw_profesionales_completo` y no `vw_profesionales_servicios`
  /// porque esta última no trae el estado, y sin él se acabaría asignando
  /// trabajo a gente pendiente de aprobar o ya rechazada.
  Future<List<VwProfesionalesCompletoRow>> _cargarProfesionales() {
    return VwProfesionalesCompletoTable().queryRows(
      queryFn: (q) => q
          .eqOrNull('servicio_id', widget.servicioId)
          .eqOrNull('verificado', 'verificado')
          .order('nombres', ascending: true),
    );
  }

  List<VwProfesionalesCompletoRow> _filtrar(
      List<VwProfesionalesCompletoRow> filas) {
    // Un proveedor podría venir repetido si tuviera el mismo servicio dado de
    // alta dos veces; se deja uno por persona.
    final vistos = <String>{};
    final unicos = <VwProfesionalesCompletoRow>[];
    for (final fila in filas) {
      final id = fila.profesionalId;
      if (id == null || id.isEmpty) continue;
      if (vistos.add(id)) unicos.add(fila);
    }

    if (_busqueda.trim().isEmpty) return unicos;
    final aguja = _busqueda.trim().toLowerCase();
    return unicos.where((fila) {
      final nombre = (fila.nombreCompleto ?? '').toLowerCase();
      final correo = (fila.correoElectronico ?? '').toLowerCase();
      return nombre.contains(aguja) || correo.contains(aguja);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
        child: Container(
          constraints: BoxConstraints(maxWidth: 540.0, maxHeight: 620.0),
          decoration: BoxDecoration(
            color: tema.primaryBackground,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignar profesional',
                  style: tema.headlineSmall.override(
                    font: GoogleFonts.interTight(),
                    letterSpacing: 0.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
                  child: Text(
                    widget.servicioNombre != null &&
                            widget.servicioNombre!.isNotEmpty
                        ? 'Esta solicitud no tiene profesional asignado. Servicio: ${widget.servicioNombre}'
                        : 'Esta solicitud no tiene profesional asignado.',
                    style: tema.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: tema.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                  child: TextFormField(
                    controller: _buscarController,
                    onChanged: (valor) => setState(() => _busqueda = valor),
                    decoration: decorarInputHulp(context, InputDecoration(
                      hintText: 'Buscar por nombre o correo',
                      prefixIcon: Icon(Icons.search, color: tema.secondaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: tema.alternate),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: tema.alternate),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: tema.primary),
                      ),
                      contentPadding: EdgeInsetsDirectional.fromSTEB(
                          12.0, 12.0, 12.0, 12.0),
                    )),
                    style: tema.bodyMedium.override(
                      font: GoogleFonts.inter(),
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                    child: FutureBuilder<List<VwProfesionalesCompletoRow>>(
                      future: _consulta,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: SizedBox(
                                width: 40.0,
                                height: 40.0,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(tema.primary),
                                ),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return _aviso(
                            tema,
                            Icons.error_outline,
                            'No se pudo cargar la lista de profesionales. '
                            'Puedes finalizar sin asignar o cerrar e intentarlo de nuevo.',
                          );
                        }

                        final profesionales = _filtrar(snapshot.data ?? []);
                        if (profesionales.isEmpty) {
                          return _aviso(
                            tema,
                            Icons.person_off_outlined,
                            _busqueda.trim().isEmpty
                                ? 'Ningún proveedor aprobado ofrece este servicio. '
                                    'Puedes finalizar la solicitud sin asignar profesional.'
                                : 'Ningún proveedor aprobado coincide con la búsqueda.',
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: profesionales.length,
                          separatorBuilder: (_, __) => SizedBox(height: 6.0),
                          itemBuilder: (context, indice) {
                            final fila = profesionales[indice];
                            final id = fila.profesionalId!;
                            final seleccionado = _elegido == id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () => setState(() => _elegido = id),
                              child: Container(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 10.0, 12.0, 10.0),
                                decoration: BoxDecoration(
                                  color: seleccionado
                                      ? tema.primary.withOpacity(0.08)
                                      : tema.secondaryBackground,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: seleccionado
                                        ? tema.primary
                                        : tema.alternate,
                                    width: seleccionado ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      seleccionado
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: seleccionado
                                          ? tema.primary
                                          : tema.secondaryText,
                                      size: 20.0,
                                    ),
                                    SizedBox(width: 12.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            fila.nombreCompleto ??
                                                '${fila.nombres ?? ''} ${fila.apellidos ?? ''}'
                                                    .trim(),
                                            style: tema.bodyMedium.override(
                                              font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600),
                                              letterSpacing: 0.0,
                                            ),
                                          ),
                                          if ((fila.correoElectronico ?? '')
                                              .isNotEmpty)
                                            Text(
                                              fila.correoElectronico!,
                                              style: tema.bodySmall.override(
                                                font: GoogleFonts.inter(),
                                                color: tema.secondaryText,
                                                letterSpacing: 0.0,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${fila.serviciosRealizados ?? 0} servicios',
                                      style: tema.bodySmall.override(
                                        font: GoogleFonts.inter(),
                                        color: tema.secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    hulpModalCloseButton(
                      text: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                    ),
                    hulpModalSecondaryButton(
                      context: context,
                      text: 'Finalizar sin profesional',
                      onPressed: () => Navigator.pop(
                          context, SeleccionProfesional.sinAsignar()),
                    ),
                    hulpModalPrimaryButton(
                      context: context,
                      onPressed: _elegido == null
                          ? null
                          : () => Navigator.pop(context,
                              SeleccionProfesional.asignar(_elegido!)),
                      text: 'Asignar y finalizar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aviso(FlutterFlowTheme tema, IconData icono, String texto) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: tema.secondaryText, size: 36.0),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: tema.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: tema.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
