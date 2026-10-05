import '/components/documentos_proveedor.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/web/menu/menu_widget.dart';
import '/flutter_flow/upload_data.dart';
import '/components/notificacion2_widget.dart';
import '/components/notificacioneliminar_widget.dart';
import 'dart:math' show min;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'detalle_proveedor_model.dart';
export 'detalle_proveedor_model.dart';

/// REQ-002 v2.0.0 — Página dedicada que reemplaza al pop-up
/// `InformacionProveedorWidget`. La lógica de datos y los helpers de documentos
/// se conservan idénticos a la versión v1.0.0; solo cambia la presentación.
class DetalleProveedorWidget extends StatefulWidget {
  const DetalleProveedorWidget({
    super.key,
    required this.proveedorId,
    this.categoriaid,
    this.categorianombre,
  });

  final String? proveedorId;
  final String? categoriaid;
  final String? categorianombre;

  static String routeName = 'DetalleProveedor';
  static String routePath = '/detalleProveedor';

  @override
  State<DetalleProveedorWidget> createState() => _DetalleProveedorWidgetState();
}

class _DetalleProveedorWidgetState extends State<DetalleProveedorWidget> {
  late DetalleProveedorModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Paleta (alineada a FlutterFlowTheme y a los colores ya usados en el proyecto)
  static const Color _chipBg = Color(0xFFDFF9D2);
  static const Color _chipText = Color(0xFF18AC4C);
  static const Color _inactiveBg = Color(0xFFFFE9CC);
  static const Color _inactiveText = Color(0xFFD6A100);
  static const Color _breadcrumb = Color(0xFF5E252B);
  static const Color _cardBorder = Color(0x7C766C4D);
  static const Color _labelGray = Color(0xFF4A4A4A);
  static const Color _valueGray = Color(0xFF606060);
  // REQ-002 v2.0.3: color de los labels de campo, fiel al diseño.
  // Antes era un azul (#133CC2) que no esta en la paleta de Hulp.
  static Color _labelColor(BuildContext c) => FlutterFlowTheme.of(c).primary;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetalleProveedorModel());
    _cargarCiudades();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Ciudades en las que opera Hulp, para no dejar escribirlas a mano.
  List<String> _ciudades = [];

  Future<void> _cargarCiudades() async {
    try {
      final filas = await CiudadesTable().queryRows(
        queryFn: (q) =>
            q.eqOrNull('activo', true).order('nombre', ascending: true),
      );
      if (!mounted) return;
      safeSetState(() => _ciudades = filas.map((c) => c.nombre).toList());
    } catch (e) {
      print('No se pudieron cargar las ciudades: $e');
    }
  }

  /// Desplegable de ciudad con la misma pinta que `_dialogField`.
  ///
  /// Escribe en el mismo `TextEditingController` que usaba el campo de texto,
  /// asi el guardado no cambia. Antes se escribia a mano y cualquier variante
  /// («bogota», «Bogotá») dejaba al proveedor descolgado del filtro por ciudad.
  Widget _dialogCiudad(
      BuildContext ctx, TextEditingController controlador, bool saving) {
    final actual = controlador.text.trim();
    final opciones = <String>{
      ..._ciudades,
      if (actual.isNotEmpty) actual,
    }.toList();

    return StatefulBuilder(
      builder: (ctx, refrescar) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ciudad',
            style: FlutterFlowTheme.of(ctx).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  fontSize: 13,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: controlador.text.trim().isEmpty
                ? null
                : controlador.text.trim(),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: const Text('Sin ciudad'),
            items: opciones
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: saving
                ? null
                : (val) => refrescar(() => controlador.text = val ?? ''),
          ),
        ],
      ),
    );
  }

  // ── Helpers de documentos (idénticos a v1.0.0) ───────────────────────────

  // ── Documentos privados ──────────────────────────────────────────────────
  // Cedulas, cuentas bancarias y contratos viven en el bucket privado
  // 'documentos-privados' y se guardan como RUTA, no como URL. Se firman al
  // vuelo y el enlace caduca. Los valores que siguen siendo http (las
  // certificaciones y los registros anteriores a la migracion) se devuelven
  // tal cual, asi que ambos formatos conviven sin ramas en el resto del codigo.
  final Map<String, String> _urlsFirmadas = {};

  /// El nombre del archivo, sin la ruta ni los parametros de la URL firmada.
  String _nombreArchivo(String? valor) {
    if (valor == null || valor.isEmpty) return '—';
    final sinQuery = valor.split('?').first;
    final partes = sinQuery.split('/');
    return partes.isEmpty ? valor : Uri.decodeComponent(partes.last);
  }

  /// Vista previa pequena del documento, para saber que se esta reemplazando
  /// o borrando antes de hacerlo. Los PDF y ofimaticos no se pueden pintar:
  /// para esos va un icono segun la extension.
  Widget _miniatura(BuildContext ctx, String? valor) {
    const lado = 44.0;
    Widget marco(Widget hijo) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: lado,
            height: lado,
            color: const Color(0xFFEAEAEA),
            child: hijo,
          ),
        );

    if (valor == null || valor.isEmpty) {
      return marco(Icon(Icons.description_outlined,
          size: 20, color: FlutterFlowTheme.of(ctx).secondaryText));
    }

    final ext = _nombreArchivo(valor).split('.').last.toLowerCase();
    const imagenes = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    if (!imagenes.contains(ext)) {
      final icono = ext == 'pdf'
          ? Icons.picture_as_pdf_outlined
          : (ext == 'xlsx' || ext == 'xls')
              ? Icons.table_chart_outlined
              : Icons.article_outlined;
      return marco(
          Icon(icono, size: 20, color: FlutterFlowTheme.of(ctx).secondary));
    }

    return marco(FutureBuilder<String?>(
      future: resolverUrlDocumento(valor),
      builder: (_, snap) {
        if (!snap.hasData || snap.data == null) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.network(
          snap.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
              size: 20, color: FlutterFlowTheme.of(ctx).secondaryText),
        );
      },
    ));
  }

  // ── Helpers de presentación (REQ-002 v2.0.0) ─────────────────────────────

  /// REQ-002 v2.0.0 §11.5: ID de proveedor derivado, solo presentación.
  String _idProveedor(UsuariosRow? row) {
    final anio = (row?.fechaRegistro?.year ?? DateTime.now().year).toString();
    final idNum = row?.idUsuario;
    final padded = idNum != null ? idNum.toString().padLeft(4, '0') : '----';
    return 'PROV-$anio-$padded';
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String texto,
      {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: FlutterFlowTheme.of(context).primary),
          const SizedBox(width: 8),
          Text(
            texto,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  fontSize: 20,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          if (onEdit != null) ...[
            const Spacer(),
            _editIconButton(context, onEdit),
          ],
        ],
      ),
    );
  }

  /// REQ-007: ícono de lápiz reutilizable para abrir el pop-up de edición de
  /// una sección. Respeta el color primario y el tamaño del diseño.
  Widget _editIconButton(BuildContext context, VoidCallback onTap,
      {String tooltip = 'Editar'}) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        icon: Icon(Icons.edit_outlined,
            size: 18, color: FlutterFlowTheme.of(context).primary),
        onPressed: onTap,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // REQ-007: edición de secciones (pop-ups). Reutiliza el patrón visual de
  // _agregarReferenciaDialog (colores, formas, botones Cancelar/Actualizar).
  // ──────────────────────────────────────────────────────────────────────

  /// Campo de texto reutilizable para los pop-ups de edición (REQ-007).
  Widget _dialogField(BuildContext ctx, String label, TextEditingController c,
      {bool saving = false,
      bool requiredField = false,
      TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(ctx).bodySmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                fontSize: 13,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
                color: _labelColor(ctx),
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          enabled: !saving,
          validator: requiredField
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFFBFAF9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: FlutterFlowTheme.of(ctx).alternate, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: FlutterFlowTheme.of(ctx).primary, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: FlutterFlowTheme.of(ctx).error, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: FlutterFlowTheme.of(ctx).error, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 15),
        ),
      ],
    );
  }

  /// Pop-up de edición genérico: header (icono + título), campos y los botones
  /// Cancelar / Actualizar. Ejecuta [onSave] y refresca la página al terminar.
  Future<void> _showEditFormDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<TextEditingController> controllers,
    required List<Widget> Function(BuildContext ctx, bool saving) fields,
    required Future<void> Function() onSave,
    Future<void> Function()? onDelete,
  }) async {
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 20,
                                  color: FlutterFlowTheme.of(ctx).primary),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: FlutterFlowTheme.of(ctx)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700),
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          FlutterFlowTheme.of(ctx).primaryText,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...fields(ctx, saving),
                          const SizedBox(height: 24),
                          if (onDelete != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: saving
                                    ? null
                                    : () async {
                                        Navigator.of(ctx).pop();
                                        await onDelete();
                                      },
                                icon: Icon(Icons.delete_outline,
                                    size: 18,
                                    color: FlutterFlowTheme.of(ctx).error),
                                label: Text('Eliminar',
                                    style: GoogleFonts.inter(
                                        color: FlutterFlowTheme.of(ctx).error,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _valueGray,
                                  side: const BorderSide(
                                      color: Color(0xFF8A8A8A)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      FlutterFlowTheme.of(ctx).primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: saving
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        setLocal(() => saving = true);
                                        try {
                                          await onSave();
                                          if (ctx.mounted) {
                                            Navigator.of(ctx).pop();
                                          }
                                          if (mounted) {
                                            safeSetState(() {});
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Actualizado correctamente'),
                                            ));
                                          }
                                        } catch (_) {
                                          setLocal(() => saving = false);
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(const SnackBar(
                                              content:
                                                  Text('No se pudo actualizar'),
                                            ));
                                          }
                                        }
                                      },
                                child: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Actualizar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  /// REQ-007: pop-up para editar "Datos básicos" (usuarios).
  void _editDatosBasicosDialog(BuildContext context, UsuariosRow? usuario) {
    final tipoCtrl = TextEditingController(text: usuario?.tipoDocumento ?? '');
    final numCtrl = TextEditingController(text: usuario?.numeroDocumento ?? '');
    final dirCtrl = TextEditingController(text: usuario?.direccion ?? '');
    final paisCtrl = TextEditingController(text: usuario?.pais ?? '');
    _showEditFormDialog(
      context,
      icon: Icons.person_outline,
      title: 'Editar datos básicos',
      controllers: [tipoCtrl, numCtrl, dirCtrl, paisCtrl],
      fields: (ctx, saving) => [
        _dialogField(ctx, 'Tipo de documento', tipoCtrl, saving: saving),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Número de documento', numCtrl, saving: saving),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Dirección', dirCtrl, saving: saving),
        const SizedBox(height: 14),
        _dialogField(ctx, 'País', paisCtrl, saving: saving),
      ],
      onSave: () async {
        await UsuariosTable().update(
          data: {
            'tipo_documento': tipoCtrl.text.trim(),
            'numero_documento': numCtrl.text.trim(),
            'direccion': dirCtrl.text.trim(),
            'pais': paisCtrl.text.trim(),
          },
          matchingRows: (rows) => rows.eqOrNull('id', widget.proveedorId),
        );
      },
    );
  }

  /// REQ-007: pop-up para editar "Facturación" (cuentas_bancarias + RUT).
  void _editFacturacionDialog(
      BuildContext context, UsuariosRow? usuario) async {
    final rows = await CuentasBancariasTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
    final cuenta = rows.isNotEmpty ? rows.first : null;
    final entidadCtrl =
        TextEditingController(text: cuenta?.entidadBancaria ?? '');
    final tipoCtrl = TextEditingController(text: cuenta?.tipoCuenta ?? '');
    final numCtrl = TextEditingController(text: cuenta?.numeroCuenta ?? '');
    final rutCtrl =
        TextEditingController(text: usuario?.registroTributario ?? '');
    if (!mounted) return;
    _showEditFormDialog(
      context,
      icon: Icons.account_balance_wallet_outlined,
      title: 'Editar facturación',
      controllers: [entidadCtrl, tipoCtrl, numCtrl, rutCtrl],
      fields: (ctx, saving) => [
        _dialogField(ctx, 'Entidad bancaria', entidadCtrl, saving: saving),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Tipo de cuenta', tipoCtrl, saving: saving),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Número de cuenta', numCtrl,
            saving: saving, keyboard: TextInputType.number),
        const SizedBox(height: 14),
        _dialogField(ctx, 'RUT', rutCtrl, saving: saving),
      ],
      onSave: () async {
        if (cuenta != null) {
          await CuentasBancariasTable().update(
            data: {
              'entidad_bancaria': entidadCtrl.text.trim(),
              'tipo_cuenta': tipoCtrl.text.trim(),
              'numero_cuenta': numCtrl.text.trim(),
            },
            matchingRows: (r) => r.eqOrNull('id', cuenta.id),
          );
        } else {
          final hasAny = entidadCtrl.text.trim().isNotEmpty ||
              tipoCtrl.text.trim().isNotEmpty ||
              numCtrl.text.trim().isNotEmpty;
          if (hasAny) {
            final titular =
                '${usuario?.nombres ?? ''} ${usuario?.apellidos ?? ''}'.trim();
            await CuentasBancariasTable().insert({
              'usuario_id': widget.proveedorId,
              'entidad_bancaria': entidadCtrl.text.trim(),
              'tipo_cuenta': tipoCtrl.text.trim(),
              'numero_cuenta': numCtrl.text.trim(),
              'nombre_titular': titular.isEmpty ? '—' : titular,
            });
          }
        }
        await UsuariosTable().update(
          data: {'registro_tributario': rutCtrl.text.trim()},
          matchingRows: (r) => r.eqOrNull('id', widget.proveedorId),
        );
      },
    );
  }

  /// REQ-007: pop-up para editar una referencia (montado) con opción Eliminar.
  void _editReferenciaDialog(BuildContext context, ReferenciasLaboralesRow r) {
    final nombreCtrl = TextEditingController(text: r.nombreReferencia);
    final telCtrl = TextEditingController(text: r.telefonoReferencia);
    final relCtrl = TextEditingController(text: r.relacionLaboral);
    _showEditFormDialog(
      context,
      icon: Icons.people_alt_outlined,
      title: 'Editar referencia',
      controllers: [nombreCtrl, telCtrl, relCtrl],
      fields: (ctx, saving) => [
        _dialogField(ctx, 'Nombre *', nombreCtrl,
            saving: saving, requiredField: true),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Teléfono *', telCtrl,
            saving: saving, requiredField: true, keyboard: TextInputType.phone),
        const SizedBox(height: 14),
        _dialogField(ctx, 'Relación *', relCtrl,
            saving: saving, requiredField: true),
      ],
      onSave: () async {
        await ReferenciasLaboralesTable().update(
          data: {
            'nombre_referencia': nombreCtrl.text.trim(),
            'telefono_referencia': telCtrl.text.trim(),
            'relacion_laboral': relCtrl.text.trim(),
          },
          matchingRows: (rows) => rows.eqOrNull('id', r.id),
        );
      },
      onDelete: () => _confirmDeleteReferencia(context, r),
    );
  }

  /// REQ-007: confirmación previa antes de eliminar una referencia.
  Future<void> _confirmDeleteReferencia(
      BuildContext context, ReferenciasLaboralesRow r) async {
    await showDialog(
      context: context,
      builder: (dctx) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: NotificacioneliminarWidget(
            titulo: 'Eliminar referencia',
            texto: '¿Seguro de eliminar esta referencia?',
            succes: false,
            action: () async {
              await ReferenciasLaboralesTable().delete(
                matchingRows: (rows) => rows.eqOrNull('id', r.id),
              );
              if (mounted) safeSetState(() {});
            },
          ),
        );
      },
    );
  }

  /// REQ-007: pop-up para editar "Datos del cliente" (encabezado) + foto.
  void _editDatosClienteDialog(BuildContext context, UsuariosRow? usuario) {
    final nombresCtrl = TextEditingController(text: usuario?.nombres ?? '');
    final apellidosCtrl = TextEditingController(text: usuario?.apellidos ?? '');
    final telCtrl = TextEditingController(text: usuario?.telefono ?? '');
    final ciudadCtrl = TextEditingController(text: usuario?.ciudad ?? '');
    final igCtrl = TextEditingController(
        text: (usuario?.redesSociales.isNotEmpty ?? false)
            ? usuario!.redesSociales.first
            : '');
    final fbCtrl = TextEditingController(
        text: (usuario?.redesSociales.length ?? 0) > 1
            ? usuario!.redesSociales.elementAt(1)
            : '');
    final formKey = GlobalKey<FormState>();
    String? nuevaFotoUrl;
    bool saving = false;
    bool subiendoFoto = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          final fotoActual = nuevaFotoUrl ??
              ((usuario?.fotoPerfilUrl?.isNotEmpty ?? false)
                  ? usuario!.fotoPerfilUrl
                  : null);
          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 20,
                                color: FlutterFlowTheme.of(ctx).primary),
                            const SizedBox(width: 8),
                            Text(
                              'Editar datos del cliente',
                              style: FlutterFlowTheme.of(ctx)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700),
                                    fontSize: 18,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w700,
                                    color: FlutterFlowTheme.of(ctx).primaryText,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFEAEAEA)),
                                child: fotoActual != null
                                    ? Image.network(fotoActual,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 44))
                                    : const Icon(Icons.person, size: 44),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: (saving || subiendoFoto)
                                    ? null
                                    : () async {
                                        final files = await selectFiles(
                                          storageFolderPath: 'perfiles',
                                          multiFile: false,
                                        );
                                        if (files == null || files.isEmpty) {
                                          return;
                                        }
                                        setLocal(() => subiendoFoto = true);
                                        try {
                                          final urls =
                                              await uploadSupabaseStorageFiles(
                                            bucketName: 'archivos',
                                            selectedFiles: files,
                                          );
                                          if (urls.isNotEmpty) {
                                            setLocal(() =>
                                                nuevaFotoUrl = urls.first);
                                          }
                                        } catch (_) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'No se pudo subir la foto'),
                                            ));
                                          }
                                        } finally {
                                          setLocal(() => subiendoFoto = false);
                                        }
                                      },
                                icon: subiendoFoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Icon(Icons.photo_camera_outlined,
                                        size: 18,
                                        color:
                                            FlutterFlowTheme.of(ctx).primary),
                                label: Text(
                                    subiendoFoto
                                        ? 'Subiendo...'
                                        : 'Cambiar foto',
                                    style: GoogleFonts.inter(
                                        color: FlutterFlowTheme.of(ctx).primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _dialogField(ctx, 'Nombres *', nombresCtrl,
                            saving: saving, requiredField: true),
                        const SizedBox(height: 14),
                        _dialogField(ctx, 'Apellidos *', apellidosCtrl,
                            saving: saving, requiredField: true),
                        const SizedBox(height: 14),
                        _dialogField(ctx, 'Teléfono', telCtrl,
                            saving: saving, keyboard: TextInputType.phone),
                        const SizedBox(height: 14),
                        _dialogCiudad(ctx, ciudadCtrl, saving),
                        const SizedBox(height: 14),
                        _dialogField(ctx, 'Instagram', igCtrl, saving: saving),
                        const SizedBox(height: 14),
                        _dialogField(ctx, 'Facebook', fbCtrl, saving: saving),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _valueGray,
                                side:
                                    const BorderSide(color: Color(0xFF8A8A8A)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed:
                                  saving ? null : () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(ctx).primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                textStyle: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              onPressed: (saving || subiendoFoto)
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setLocal(() => saving = true);
                                      try {
                                        final data = <String, dynamic>{
                                          'nombres': nombresCtrl.text.trim(),
                                          'apellidos':
                                              apellidosCtrl.text.trim(),
                                          'telefono': telCtrl.text.trim(),
                                          'ciudad': ciudadCtrl.text.trim(),
                                          'redes_sociales': [
                                            igCtrl.text.trim(),
                                            fbCtrl.text.trim(),
                                          ],
                                        };
                                        if (nuevaFotoUrl != null) {
                                          data['foto_perfil_url'] =
                                              nuevaFotoUrl;
                                        }
                                        await UsuariosTable().update(
                                          data: data,
                                          matchingRows: (rows) => rows.eqOrNull(
                                              'id', widget.proveedorId),
                                        );
                                        final fotoVieja =
                                            usuario?.fotoPerfilUrl;
                                        if (nuevaFotoUrl != null &&
                                            fotoVieja != null &&
                                            fotoVieja.isNotEmpty &&
                                            fotoVieja != nuevaFotoUrl) {
                                          try {
                                            await deleteSupabaseFileFromPublicUrl(
                                                fotoVieja);
                                          } catch (_) {}
                                        }
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        if (mounted) {
                                          safeSetState(() {});
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Actualizado correctamente'),
                                          ));
                                        }
                                      } catch (_) {
                                        setLocal(() => saving = false);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(const SnackBar(
                                            content:
                                                Text('No se pudo actualizar'),
                                          ));
                                        }
                                      }
                                    },
                              child: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Actualizar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      nombresCtrl.dispose();
      apellidosCtrl.dispose();
      telCtrl.dispose();
      ciudadCtrl.dispose();
      igCtrl.dispose();
      fbCtrl.dispose();
    });
  }

  /// REQ-007: pop-up para editar "Servicios ofrecidos" por categoría.
  /// Seleccionar una categoría = todos sus servicios activos (delete + insert).
  void _editServiciosDialog(BuildContext context) async {
    final results = await Future.wait<List<SupabaseDataRow>>([
      ProfesionalServiciosTable().queryRows(
          queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId)),
      ServiciosTable().queryRows(queryFn: (q) => q),
      SubcategoriasTable().queryRows(queryFn: (q) => q),
      CategoriasTable().queryRows(queryFn: (q) => q),
    ]);
    final prof = results[0].cast<ProfesionalServiciosRow>();
    final servicios = results[1].cast<ServiciosRow>();
    final subcats = results[2].cast<SubcategoriasRow>();
    final cats = results[3].cast<CategoriasRow>();

    final subToCat = <String, String>{
      for (final sc in subcats) sc.id: sc.categoriaId
    };
    final servToCat = <String, String>{};
    for (final s in servicios) {
      final c = subToCat[s.subcategoriaId];
      if (c != null) servToCat[s.id] = c;
    }
    final catsActivas = <CategoriasRow>[];
    final vistos = <String>{};
    for (final c in cats) {
      if (c.estado.trim().toLowerCase() != 'activo') continue;
      if (c.nombre.isEmpty || !vistos.add(c.id)) continue;
      catsActivas.add(c);
    }
    final selected = <String>{};
    for (final servId in prof.map((e) => e.servicioId)) {
      final c = servToCat[servId];
      if (c != null) selected.add(c);
    }
    if (!mounted) return;

    final formSelected = <String>{...selected};
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handyman,
                            size: 20, color: FlutterFlowTheme.of(ctx).primary),
                        const SizedBox(width: 8),
                        Text(
                          'Editar servicios',
                          style: FlutterFlowTheme.of(ctx).bodyMedium.override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700),
                                fontSize: 18,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w700,
                                color: FlutterFlowTheme.of(ctx).primaryText,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca una categoría para seleccionarla o quitarla.',
                      style: FlutterFlowTheme.of(ctx).bodySmall.override(
                            font: GoogleFonts.inter(),
                            fontSize: 13,
                            letterSpacing: 0,
                            color: FlutterFlowTheme.of(ctx).secondaryText,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (catsActivas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('No hay categorías activas',
                            style: GoogleFonts.inter(
                                color: FlutterFlowTheme.of(ctx).secondaryText)),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: catsActivas.map((c) {
                              final sel = formSelected.contains(c.id);
                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: saving
                                    ? null
                                    : () => setLocal(() {
                                          if (sel) {
                                            formSelected.remove(c.id);
                                          } else {
                                            formSelected.add(c.id);
                                          }
                                        }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        sel ? _chipBg : const Color(0xFFF0F0EF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          sel
                                              ? Icons.check_circle_outline
                                              : Icons.add,
                                          size: 16,
                                          color: sel
                                              ? _chipText
                                              : const Color(0xFF8A8A8A)),
                                      const SizedBox(width: 6),
                                      Text(c.nombre,
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: sel
                                                  ? _chipText
                                                  : const Color(0xFF8A8A8A))),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _valueGray,
                            side: const BorderSide(color: Color(0xFF8A8A8A)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed:
                              saving ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlutterFlowTheme.of(ctx).primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  setLocal(() => saving = true);
                                  try {
                                    final targetIds = <String>[];
                                    for (final s in servicios) {
                                      if (s.estado.trim().toLowerCase() !=
                                          'activo') continue;
                                      final c = servToCat[s.id];
                                      if (c != null &&
                                          formSelected.contains(c)) {
                                        targetIds.add(s.id);
                                      }
                                    }
                                    await ProfesionalServiciosTable().delete(
                                      matchingRows: (rows) => rows.eqOrNull(
                                          'usuario_id', widget.proveedorId),
                                    );
                                    for (final sid in targetIds) {
                                      await ProfesionalServiciosTable().insert({
                                        'usuario_id': widget.proveedorId,
                                        'servicio_id': sid,
                                      });
                                    }
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                    if (mounted) {
                                      safeSetState(() {});
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('Servicios actualizados'),
                                      ));
                                    }
                                  } catch (_) {
                                    setLocal(() => saving = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx)
                                          .showSnackBar(const SnackBar(
                                        content: Text('No se pudo actualizar'),
                                      ));
                                    }
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// REQ-007: confirmación genérica de borrado (reutiliza NotificacioneliminarWidget).
  Future<void> _confirmEliminar(BuildContext context, String titulo,
      String texto, Future<void> Function() action) async {
    await showDialog(
      context: context,
      builder: (dctx) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: NotificacioneliminarWidget(
            titulo: titulo,
            texto: texto,
            succes: false,
            action: () async {
              await action();
            },
          ),
        );
      },
    );
  }

  /// REQ-007 v1.1.0: pop-up para gestionar documentos (subir/reemplazar/
  /// eliminar registro y certificaciones). Tipos: jpg/jpeg/png/webp/pdf/docx/
  /// xlsx. Subida múltiple de certificaciones, barra de progreso y error real.
  void _gestionarDocumentosDialog(
      BuildContext context, UsuariosRow? usuario) async {
    const allowedExt = ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'docx', 'xlsx'];
    const formatosHint = 'Formatos: JPG, PNG, WEBP, PDF, DOCX, XLSX';
    final certsInit = await CertificacionesTable().queryRows(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
    if (!mounted) return;
    String? cedulaUrl = usuario?.cedula;
    String? cuentaUrl = usuario?.cuentaBancaria;
    String? contratoUrl = usuario?.contrato;
    final certs = [...certsInit];
    final entidadCtrl = TextEditingController();
    bool cambios = false;
    bool busy = false;
    double? progreso;
    String progresoTexto = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          // privado=true devuelve RUTAS del bucket privado; false, URLs
          // publicas. Los documentos de identidad y bancarios van por el
          // primer camino; las certificaciones siguen siendo publicas.
          Future<List<String>> subirConProgreso(List<SelectedFile> files,
              {bool privado = false}) async {
            final urls = <String>[];
            for (var i = 0; i < files.length; i++) {
              setLocal(() {
                progreso = i / files.length;
                progresoTexto = 'Subiendo ${i + 1} de ${files.length}';
              });
              final url = privado
                  ? await uploadSupabaseStoragePrivateFile(
                      selectedFile: files[i])
                  : await uploadSupabaseStorageFile(
                      bucketName: 'archivos', selectedFile: files[i]);
              urls.add(url);
              setLocal(() => progreso = (i + 1) / files.length);
            }
            return urls;
          }

          // Borra el archivo anterior en el bucket que corresponda.
          Future<void> borrarAnterior(String? actual) async {
            if (actual == null || actual.isEmpty) return;
            try {
              if (isPrivateStoragePath(actual)) {
                await deleteSupabasePrivateFile(actual);
              } else {
                await deleteSupabaseFileFromPublicUrl(actual);
              }
            } catch (_) {}
          }

          Future<void> subirRegistro(String campo, String folder,
              String? actual, void Function(String?) set) async {
            final files = await selectFiles(
                storageFolderPath: folder,
                allowedExtensions: allowedExt,
                multiFile: false);
            if (files == null || files.isEmpty) return;
            setLocal(() {
              busy = true;
              progreso = 0;
              progresoTexto = 'Subiendo...';
            });
            try {
              final urls = await subirConProgreso(files, privado: true);
              if (urls.isNotEmpty) {
                await UsuariosTable().update(
                  data: {campo: urls.first},
                  matchingRows: (r) => r.eqOrNull('id', widget.proveedorId),
                );
                if (actual != urls.first) {
                  await borrarAnterior(actual);
                }
                cambios = true;
                setLocal(() => set(urls.first));
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('No se pudo subir: $e')));
              }
            } finally {
              setLocal(() {
                busy = false;
                progreso = null;
              });
            }
          }

          Future<void> eliminarRegistro(
              String campo, String? actual, void Function(String?) set) async {
            await _confirmEliminar(context, 'Eliminar documento',
                '¿Seguro de eliminar este documento?', () async {
              await UsuariosTable().update(
                data: {campo: null},
                matchingRows: (r) => r.eqOrNull('id', widget.proveedorId),
              );
              await borrarAnterior(actual);
              cambios = true;
              setLocal(() => set(null));
            });
          }

          Future<void> agregarCerts() async {
            if (entidadCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Ingresa el nombre de la entidad')));
              return;
            }
            final files = await selectFiles(
                storageFolderPath: 'certificaciones',
                allowedExtensions: allowedExt,
                multiFile: true);
            if (files == null || files.isEmpty) return;
            setLocal(() {
              busy = true;
              progreso = 0;
              progresoTexto = 'Subiendo...';
            });
            try {
              final urls = await subirConProgreso(files);
              for (final url in urls) {
                await CertificacionesTable().insert({
                  'usuario_id': widget.proveedorId,
                  'entidad_certificadora': entidadCtrl.text.trim(),
                  'documento_url': url,
                });
              }
              final fresh = await CertificacionesTable().queryRows(
                queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
              );
              certs
                ..clear()
                ..addAll(fresh);
              entidadCtrl.clear();
              cambios = true;
              setLocal(() {});
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('No se pudo subir: $e')));
              }
            } finally {
              setLocal(() {
                busy = false;
                progreso = null;
              });
            }
          }

          Future<void> eliminarCert(CertificacionesRow c) async {
            await _confirmEliminar(context, 'Eliminar certificación',
                '¿Seguro de eliminar esta certificación?', () async {
              await CertificacionesTable().delete(
                matchingRows: (r) => r.eqOrNull('id', c.id),
              );
              try {
                await deleteSupabaseFileFromPublicUrl(c.documentoUrl);
              } catch (_) {}
              certs.remove(c);
              cambios = true;
              setLocal(() {});
            });
          }

          Widget regRow(String label, String? url, String campo, String folder,
              void Function(String?) set) {
            final cargado = url != null && url.isNotEmpty;
            // Se ensena el documento que hay, no solo la palabra «cargado»:
            // reemplazar o borrar sin ver que se esta tocando es como firmar
            // a ciegas, y estos son documentos de identidad.
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(ctx).secondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    _miniatura(ctx, url),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            cargado
                                ? _nombreArchivo(url)
                                : 'Sin documento cargado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: cargado
                                  ? FlutterFlowTheme.of(ctx).secondaryText
                                  : FlutterFlowTheme.of(ctx).error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: FlutterFlowTheme.of(ctx).primary,
                      ),
                      onPressed: busy
                          ? null
                          : () => subirRegistro(campo, folder, url, set),
                      child: Text(cargado ? 'Reemplazar' : 'Subir',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                    if (cargado)
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: busy
                            ? null
                            : () => eliminarRegistro(campo, url, set),
                        icon: Icon(Icons.delete_outline,
                            size: 20, color: FlutterFlowTheme.of(ctx).error),
                      ),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 20, color: FlutterFlowTheme.of(ctx).primary),
                        const SizedBox(width: 8),
                        Text('Gestionar documentos',
                            style: FlutterFlowTheme.of(ctx).bodyMedium.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  fontSize: 18,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w700,
                                  color: FlutterFlowTheme.of(ctx).primaryText,
                                )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // El progreso, arriba y no al final: es donde se mira
                    // al pulsar, y con la lista larga el pie queda fuera de
                    // la vista justo cuando hace falta.
                    if (busy) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE0E0E0),
                          color: FlutterFlowTheme.of(ctx).primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  FlutterFlowTheme.of(ctx).primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              progreso == null
                                  ? 'Procesando…'
                                  : '${((progreso ?? 0) * 100).round()}% · $progresoTexto',
                              style:
                                  FlutterFlowTheme.of(ctx).bodySmall.override(
                                        font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500),
                                        fontSize: 12,
                                        letterSpacing: 0,
                                        color: FlutterFlowTheme.of(ctx).primary,
                                      ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(formatosHint,
                        style: FlutterFlowTheme.of(ctx).bodySmall.override(
                              font: GoogleFonts.inter(),
                              fontSize: 12,
                              letterSpacing: 0,
                              color: FlutterFlowTheme.of(ctx).secondaryText,
                            )),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Documentos de registro',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: FlutterFlowTheme.of(ctx).primary)),
                            const SizedBox(height: 10),
                            regRow('Cédula', cedulaUrl, 'cedula', 'cedulas',
                                (v) => cedulaUrl = v),
                            regRow(
                                'Cuenta bancaria',
                                cuentaUrl,
                                'cuenta_bancaria',
                                'cuentas',
                                (v) => cuentaUrl = v),
                            regRow('Contrato', contratoUrl, 'contrato',
                                'contratos', (v) => contratoUrl = v),
                            const Divider(height: 28),
                            Text('Certificaciones',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: FlutterFlowTheme.of(ctx).primary)),
                            const SizedBox(height: 10),
                            if (certs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('Sin certificaciones',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: FlutterFlowTheme.of(ctx)
                                            .secondaryText)),
                              )
                            else
                              ...certs.map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(ctx)
                                            .secondaryBackground,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFE0E0E0)),
                                      ),
                                      child: Row(
                                        children: [
                                          _miniatura(ctx, c.documentoUrl),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(c.entidadCertificadora,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _nombreArchivo(
                                                      c.documentoUrl),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color:
                                                        FlutterFlowTheme.of(ctx)
                                                            .secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            onPressed: busy
                                                ? null
                                                : () => eliminarCert(c),
                                            icon: Icon(Icons.delete_outline,
                                                size: 20,
                                                color: FlutterFlowTheme.of(ctx)
                                                    .error),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _dialogField(
                                      ctx, 'Entidad certificadora', entidadCtrl,
                                      saving: busy),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          FlutterFlowTheme.of(ctx).primary,
                                      side: BorderSide(
                                          color:
                                              FlutterFlowTheme.of(ctx).primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: busy ? null : agregarCerts,
                                    icon: const Icon(Icons.upload_file_outlined,
                                        size: 18),
                                    label: Text('Subir',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                                'Puedes seleccionar varios archivos; cada uno se '
                                'guarda como una certificación de esa entidad.',
                                style:
                                    FlutterFlowTheme.of(ctx).bodySmall.override(
                                          font: GoogleFonts.inter(),
                                          fontSize: 11,
                                          letterSpacing: 0,
                                          color: FlutterFlowTheme.of(ctx)
                                              .secondaryText,
                                        )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(ctx).primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      entidadCtrl.dispose();
      if (cambios && mounted) safeSetState(() {});
    });
  }

  /// Devuelve el valor solo si es un dato real del backend; null si está
  /// ausente o vacío (para evitar mostrar valores mock/placeholder).
  String? _valorReal(String? value) {
    if (value == null) return null;
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  /// Bloque label + valor de solo lectura (Datos básicos / Facturación).
  Widget _infoText(BuildContext context, String label, String? value,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                fontSize: 13,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
                color: _labelColor(context),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          (value == null || value.isEmpty) ? '—' : value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                fontSize: 15,
                letterSpacing: 0,
                fontWeight: FontWeight.w600,
                color: valueColor ?? FlutterFlowTheme.of(context).primaryText,
              ),
        ),
      ],
    );
  }

  Widget _metaItem(BuildContext context, IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: FlutterFlowTheme.of(context).primary),
        const SizedBox(width: 6),
        Text(
          texto,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(),
                fontSize: 13,
                letterSpacing: 0,
                color: _labelGray,
              ),
        ),
      ],
    );
  }

  Widget _serviceChip(BuildContext context, String texto, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_circle, size: 14, color: _chipText),
          const SizedBox(width: 6),
          Text(
            texto,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  fontSize: 12,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  color: _chipText,
                ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 0.5),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 2))
        ],
      );

  // ── Navegación ────────────────────────────────────────────────────────────

  void _volverAlListado() {
    if (Navigator.of(context).canPop()) {
      context.safePop();
    } else {
      context.pushNamed(
        Proveedores2Widget.routeName,
        queryParameters: {
          'categoriaid': serializeParam(widget.categoriaid, ParamType.String),
          'categorianombre':
              serializeParam(widget.categorianombre, ParamType.String),
        }.withoutNulls,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.menuModel,
                updateCallback: () => safeSetState(() {}),
                child: MenuWidget(),
              ),
              Expanded(
                child: FutureBuilder<List<UsuariosRow>>(
                  future: UsuariosTable().querySingleRow(
                    queryFn: (q) => q.eqOrNull('id', widget.proveedorId),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        ),
                      );
                    }
                    final rows = snapshot.data!;
                    final usuario = rows.isNotEmpty ? rows.first : null;

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context, usuario),
                            const SizedBox(height: 20),
                            _buildHeaderCard(context, usuario),
                            const SizedBox(height: 24),
                            _buildMiddleRow(context, usuario),
                            const SizedBox(height: 24),
                            _buildLowerRow(context, usuario),
                            const SizedBox(height: 24),
                            _buildServiciosOfrecidosCard(context),
                            const SizedBox(height: 24),
                            _buildHistorial(context),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UsuariosRow? usuario) {
    final nombre =
        '${usuario?.nombres ?? ''} ${usuario?.apellidos ?? ''}'.trim();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async => _volverAlListado(),
                child: Text(
                  'Proveedores',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic),
                        color: _breadcrumb,
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, color: _breadcrumb, size: 22),
              ),
              Flexible(
                child: Text(
                  nombre.isEmpty ? 'Proveedor' : nombre,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic),
                        color: _breadcrumb,
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Volver al listado'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _valueGray,
            side: const BorderSide(color: Color(0xFF8A8A8A)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: GoogleFonts.inter(fontSize: 14),
          ),
          onPressed: () => _volverAlListado(),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, UsuariosRow? usuario) {
    final nombre =
        '${usuario?.nombres ?? ''} ${usuario?.apellidos ?? ''}'.trim();
    final activo = usuario?.disponibilidad == true;
    final instagram = usuario?.redesSociales.isNotEmpty == true
        ? usuario!.redesSociales.first
        : 'Sin Instagram';
    final facebook = (usuario?.redesSociales.length ?? 0) > 1
        ? usuario!.redesSociales.elementAt(1)
        : 'Sin Facebook';
    final fecha = usuario?.fechaRegistro;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 900;
          final left = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.network(
                  valueOrDefault<String>(
                    usuario?.fotoPerfilUrl,
                    'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEAEAEA),
                    child: Icon(Icons.person,
                        size: 48,
                        color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            nombre.isEmpty ? 'Sin nombre' : nombre,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  fontSize: 24,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _editIconButton(context,
                            () => _editDatosClienteDialog(context, usuario)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: activo ? _chipBg : _inactiveBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activo ? 'Activo' : 'Inactivo',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                              fontSize: 13,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                              color: activo ? _chipText : _inactiveText,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _metaItem(
                            context,
                            Icons.location_on_outlined,
                            valueOrDefault<String>(
                                usuario?.ciudad, 'Sin ciudad')),
                        _metaItem(context, Icons.phone_outlined,
                            valueOrDefault<String>(usuario?.telefono, '—')),
                        _metaItem(
                            context, Icons.camera_alt_outlined, instagram),
                        _metaItem(context, Icons.facebook, facebook),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final center = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Servicios principales',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      fontSize: 13,
                      letterSpacing: 0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8),
              _buildServiciosPrincipalesChips(context),
            ],
          );

          final right = Column(
            crossAxisAlignment:
                narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inscripción recibida',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      fontSize: 13,
                      letterSpacing: 0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: FlutterFlowTheme.of(context).primary),
                  const SizedBox(width: 6),
                  Text(
                    fecha != null ? dateTimeFormat("d MMM, y", fecha) : '—',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          fontSize: 15,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'ID de proveedor',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      fontSize: 13,
                      letterSpacing: 0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _idProveedor(usuario),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      fontSize: 16,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 20),
                center,
                const SizedBox(height: 20),
                right,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: left),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: center),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: right),
            ],
          );
        },
      ),
    );
  }

  /// Chips de "Servicios principales" — NUEVA consulta (REQ-002 v2.0.0 §11.4).
  Widget _buildServiciosPrincipalesChips(BuildContext context) {
    return FutureBuilder<List<VwProfesionalesServiciosRow>>(
      future: VwProfesionalesServiciosTable().queryRows(
        queryFn: (q) => q.eqOrNull('profesional_id', widget.proveedorId),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        // REQ-005 v1.0.5: chips del encabezado muestran CATEGORÍAS distintas
        // (no servicios), coherente con "Servicios ofrecidos".
        final nombres = snapshot.data!
            .map((e) => e.categoriaNombre)
            .where((e) => e != null && e.isNotEmpty)
            .map((e) => e!)
            .toSet()
            .toList();
        if (nombres.isEmpty) {
          return Text(
            'Sin servicios',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(),
                  fontSize: 12,
                  letterSpacing: 0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          );
        }
        final visibles = nombres.take(4).toList();
        final restantes = nombres.length - visibles.length;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...visibles.map((n) => _serviceChip(context, n)),
            if (restantes > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$restantes',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        fontSize: 12,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                        color: _chipText,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiddleRow(BuildContext context, UsuariosRow? usuario) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final docs = _buildDocumentosCard(context, usuario);
        final refs = _buildReferenciasCard(context);
        if (narrow) {
          return Column(
            children: [docs, const SizedBox(height: 24), refs],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: docs),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: refs),
          ],
        );
      },
    );
  }

  Widget _buildDocumentosCard(BuildContext context, UsuariosRow? usuario) {
    final cedula = usuario?.cedula;
    final cuenta = usuario?.cuentaBancaria;
    final contrato = usuario?.contrato;
    final uploadDate = usuario?.fechaRegistro;
    final loadedRegistro = [cedula, cuenta, contrato]
        .where((u) => u != null && u.isNotEmpty)
        .length;

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(context, Icons.description_outlined, 'Documentos'),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$loadedRegistro/3 cargados',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          fontSize: 12,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _editIconButton(
                  context, () => _gestionarDocumentosDialog(context, usuario)),
            ],
          ),
          // Documentos de registro
          Text(
            'Documentos de registro',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  fontSize: 16,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primary,
                ),
          ),
          const SizedBox(height: 12),
          if (loadedRegistro == 0)
            _emptyState(
              context,
              Icons.upload_file_outlined,
              'Este proveedor aún no tiene documentos de registro cargados',
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final isMobile = c.maxWidth < 600;
                final cards = <Widget>[
                  if (cedula != null && cedula.isNotEmpty)
                    TarjetaDocumento(
                        label: 'Cédula',
                        url: cedula,
                        prefijoDescarga: 'cedula',
                        proveedorId: widget.proveedorId,
                        fechaSubida: uploadDate),
                  if (cuenta != null && cuenta.isNotEmpty)
                    TarjetaDocumento(
                        label: 'Cuenta bancaria',
                        url: cuenta,
                        prefijoDescarga: 'cuenta_bancaria',
                        proveedorId: widget.proveedorId,
                        fechaSubida: uploadDate),
                  if (contrato != null && contrato.isNotEmpty)
                    TarjetaDocumento(
                        label: 'Contrato',
                        url: contrato,
                        prefijoDescarga: 'contrato',
                        proveedorId: widget.proveedorId,
                        fechaSubida: uploadDate),
                ];
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(height: 12),
                      ]
                    ],
                  );
                }
                return filaDocumentos(
                    cards.map((c) => Expanded(child: c)).toList());
              },
            ),
          const SizedBox(height: 24),
          // Certificaciones
          Text(
            'Certificaciones',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  fontSize: 16,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primary,
                ),
          ),
          const SizedBox(height: 12),
          _buildCertificaciones(context),
        ],
      ),
    );
  }

  Widget _buildCertificaciones(BuildContext context) {
    return FutureBuilder<List<CertificacionesRow>>(
      future: CertificacionesTable().queryRows(
        queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        final validCerts =
            snapshot.data!.where((c) => c.documentoUrl.isNotEmpty).toList();
        if (validCerts.isEmpty) {
          return _emptyState(
            context,
            Icons.workspace_premium_outlined,
            'Este proveedor aún no tiene certificaciones registradas',
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final isMobile = c.maxWidth < 600;
            if (isMobile) {
              final items = <Widget>[];
              for (int i = 0; i < validCerts.length; i++) {
                items.add(TarjetaDocumento(
                  label: validCerts[i].entidadCertificadora,
                  url: validCerts[i].documentoUrl,
                  prefijoDescarga: 'certificacion',
                  proveedorId: validCerts[i].id,
                  fechaSubida: validCerts[i].createdAt,
                ));
                if (i < validCerts.length - 1) {
                  items.add(const SizedBox(height: 12));
                }
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items);
            }
            final rows = <Widget>[];
            for (int i = 0; i < validCerts.length; i += 3) {
              final slice =
                  validCerts.sublist(i, min(i + 3, validCerts.length));
              rows.add(filaDocumentos(
                slice
                    .map((cert) => Expanded(
                          child: TarjetaDocumento(
                            label: cert.entidadCertificadora,
                            url: cert.documentoUrl,
                            prefijoDescarga: 'certificacion',
                            proveedorId: cert.id,
                            fechaSubida: cert.createdAt,
                          ),
                        ))
                    .toList(),
              ));
              if (i + 3 < validCerts.length)
                rows.add(const SizedBox(height: 12));
            }
            return Column(mainAxisSize: MainAxisSize.min, children: rows);
          },
        );
      },
    );
  }

  Widget _buildReferenciasCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.people_alt_outlined, 'Referencias'),
          FutureBuilder<List<ReferenciasLaboralesRow>>(
            future: ReferenciasLaboralesTable().queryRows(
              queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }
              final referencias = snapshot.data!;
              if (referencias.isEmpty) {
                return _emptyState(context, Icons.person_off_outlined,
                    'Sin referencias registradas');
              }
              return Column(
                children: referencias
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _referenceItem(context, r),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar referencia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FlutterFlowTheme.of(context).primary,
                side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _agregarReferenciaDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  /// REQ-002 v2.0.3: pop-up con formulario para agregar una referencia laboral.
  /// Inserta en `referencias_laborales` y refresca el listado.
  void _agregarReferenciaDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget field(String label, TextEditingController c,
                {TextInputType? keyboard}) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FlutterFlowTheme.of(ctx).bodySmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          fontSize: 13,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500,
                          color: _labelColor(ctx),
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: c,
                    keyboardType: keyboard,
                    enabled: !saving,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFFBFAF9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(ctx).alternate,
                            width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(ctx).primary, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(ctx).error, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(ctx).error, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 15),
                  ),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_add_alt_1_outlined,
                                    size: 20,
                                    color: FlutterFlowTheme.of(ctx).primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Agregar referencia',
                                  style: FlutterFlowTheme.of(ctx)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700),
                                        fontSize: 18,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w700,
                                        color: FlutterFlowTheme.of(ctx)
                                            .primaryText,
                                      ),
                                ),
                              ],
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap:
                                  saving ? null : () => Navigator.of(ctx).pop(),
                              child: Icon(Icons.close,
                                  size: 22,
                                  color:
                                      FlutterFlowTheme.of(ctx).secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        field('Nombre *', nombreCtrl),
                        const SizedBox(height: 14),
                        field('Teléfono *', telCtrl,
                            keyboard: TextInputType.phone),
                        const SizedBox(height: 14),
                        field('Relación *', relCtrl),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _valueGray,
                                side:
                                    const BorderSide(color: Color(0xFF8A8A8A)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed:
                                  saving ? null : () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(ctx).primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                textStyle: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setLocal(() => saving = true);
                                      try {
                                        await ReferenciasLaboralesTable()
                                            .insert({
                                          'usuario_id': widget.proveedorId,
                                          'nombre_referencia':
                                              nombreCtrl.text.trim(),
                                          'telefono_referencia':
                                              telCtrl.text.trim(),
                                          'relacion_laboral':
                                              relCtrl.text.trim(),
                                        });
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Referencia agregada correctamente'),
                                          ));
                                          safeSetState(() {});
                                        }
                                      } catch (_) {
                                        setLocal(() => saving = false);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'No se pudo agregar la referencia'),
                                          ));
                                        }
                                      }
                                    },
                              child: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nombreCtrl.dispose();
      telCtrl.dispose();
      relCtrl.dispose();
    });
  }

  Widget _referenceItem(BuildContext context, ReferenciasLaboralesRow r) {
    final iniciales = r.nombreReferencia
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlutterFlowTheme.of(context).tertiary),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _chipBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              iniciales.isEmpty ? '?' : iniciales,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                    color: _chipText,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.nombreReferencia,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        fontSize: 14,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                Text(
                  r.telefonoReferencia,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        fontSize: 13,
                        letterSpacing: 0,
                        color: const Color(0xFF0D70E7),
                      ),
                ),
                Text(
                  r.relacionLaboral,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        fontSize: 12,
                        letterSpacing: 0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _refActionButton(context, Icons.edit_outlined, 'Editar',
                  () => _editReferenciaDialog(context, r)),
              const SizedBox(height: 6),
              _refActionButton(context, Icons.remove_red_eye_outlined, 'Ver',
                  () => _verReferencia(context, r)),
              const SizedBox(height: 6),
              _refActionButton(context, Icons.phone_outlined, 'Llamar',
                  () => _llamar(context, r.telefonoReferencia)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _refActionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FlutterFlowTheme.of(context).primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: FlutterFlowTheme.of(context).primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    fontSize: 12,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _verReferencia(BuildContext context, ReferenciasLaboralesRow r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.nombreReferencia,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoText(ctx, 'Teléfono', r.telefonoReferencia),
            const SizedBox(height: 8),
            _infoText(ctx, 'Relación', r.relacionLaboral),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _llamar(BuildContext context, String telefono) async {
    try {
      await _model.llamarTelefono(telefono);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada')),
        );
      }
    }
  }

  Widget _buildLowerRow(BuildContext context, UsuariosRow? usuario) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final datos = _buildDatosBasicosCard(context, usuario);
        final factura = _buildFacturacionCard(context, usuario);
        if (narrow) {
          return Column(
            children: [
              datos,
              const SizedBox(height: 24),
              factura,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: datos),
            const SizedBox(width: 24),
            Expanded(child: factura),
          ],
        );
      },
    );
  }

  Widget _buildDatosBasicosCard(BuildContext context, UsuariosRow? usuario) {
    final instagram = usuario?.redesSociales.isNotEmpty == true
        ? usuario!.redesSociales.first
        : 'Sin Instagram';
    final facebook = (usuario?.redesSociales.length ?? 0) > 1
        ? usuario!.redesSociales.elementAt(1)
        : 'Sin Facebook';
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.person_outline, 'Datos básicos',
              onEdit: () => _editDatosBasicosDialog(context, usuario)),
          _infoText(context, 'Tipo de documento', usuario?.tipoDocumento),
          const SizedBox(height: 14),
          _infoText(context, 'Número de documento', usuario?.numeroDocumento),
          const SizedBox(height: 14),
          _infoText(context, 'Instagram', instagram),
          const SizedBox(height: 14),
          _infoText(context, 'Facebook', facebook),
          const SizedBox(height: 14),
          _infoText(context, 'Dirección', usuario?.direccion),
          const SizedBox(height: 14),
          _infoText(context, 'País', usuario?.pais),
        ],
      ),
    );
  }

  Widget _buildFacturacionCard(BuildContext context, UsuariosRow? usuario) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<CuentasBancariasRow>>(
        future: CuentasBancariasTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
        ),
        builder: (context, snapshot) {
          final cuenta = (snapshot.data?.isNotEmpty ?? false)
              ? snapshot.data!.first
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                  context, Icons.account_balance_wallet_outlined, 'Facturación',
                  onEdit: () => _editFacturacionDialog(context, usuario)),
              if (!snapshot.hasData)
                Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                )
              else ...[
                // REQ-002 v2.0.3: si no hay entidad real en backend, se muestra
                // el estado vacío ("—"); nunca un valor mock por defecto.
                _infoText(
                    context, 'Entidad', _valorReal(cuenta?.entidadBancaria)),
                const SizedBox(height: 14),
                _infoText(
                    context, 'Tipo de cuenta', _valorReal(cuenta?.tipoCuenta)),
                const SizedBox(height: 14),
                _infoText(context, 'Número de cuenta',
                    _valorReal(cuenta?.numeroCuenta)),
                const SizedBox(height: 14),
                _infoText(
                    context, 'RUT', _valorReal(usuario?.registroTributario)),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Servicios ofrecidos — REQ-005 v1.0.4: se presentan las CATEGORÍAS de los
  /// servicios del proveedor como etiquetas planas (seleccionadas / no
  /// seleccionadas). La categoría se deriva por la cadena
  /// servicio.subcategoria_id -> subcategoria.categoria_id -> categoria.
  /// "Servicios seleccionados" = categorías de los servicios del proveedor;
  /// "No seleccionados" = categorías ACTIVAS que el proveedor no ofrece.
  Widget _buildServiciosOfrecidosCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.handyman, 'Servicios ofrecidos',
              onEdit: () => _editServiciosDialog(context)),
          FutureBuilder<List<ProfesionalServiciosRow>>(
            future: ProfesionalServiciosTable().queryRows(
              queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
            ),
            builder: (context, snapProf) {
              if (!snapProf.hasData) {
                return _serviciosLoader(context);
              }
              // REQ-005 v1.0.4: se muestran las CATEGORÍAS de los servicios del
              // proveedor (no los servicios individuales). La categoría se deriva
              // por la cadena servicio.subcategoria_id -> subcategoria.categoria_id
              // -> categoria.
              final seleccionadosServIds =
                  snapProf.data!.map((e) => e.servicioId).toSet();

              return FutureBuilder<List<List<SupabaseDataRow>>>(
                future: Future.wait<List<SupabaseDataRow>>([
                  ServiciosTable().queryRows(queryFn: (q) => q),
                  SubcategoriasTable().queryRows(queryFn: (q) => q),
                  CategoriasTable().queryRows(queryFn: (q) => q),
                ]),
                builder: (context, snapCat) {
                  if (!snapCat.hasData) {
                    return _serviciosLoader(context);
                  }
                  final servicios = snapCat.data![0].cast<ServiciosRow>();
                  final subcategorias =
                      snapCat.data![1].cast<SubcategoriasRow>();
                  final categorias = snapCat.data![2].cast<CategoriasRow>();

                  // subcategoria_id -> categoria_id
                  final subToCat = <String, String>{
                    for (final sc in subcategorias) sc.id: sc.categoriaId,
                  };
                  // servicio_id -> categoria_id (vía subcategoría)
                  final servToCat = <String, String>{};
                  for (final s in servicios) {
                    final catId = subToCat[s.subcategoriaId];
                    if (catId != null) servToCat[s.id] = catId;
                  }
                  // Categorías que ofrece el proveedor (de sus servicios).
                  final catSeleccionadasIds = <String>{};
                  for (final servId in seleccionadosServIds) {
                    final catId = servToCat[servId];
                    if (catId != null) catSeleccionadasIds.add(catId);
                  }

                  // Listas de nombres (distintos por nombre).
                  // Seleccionadas: categorías ofrecidas (cualquier estado).
                  // No seleccionadas: solo categorías ACTIVAS no ofrecidas.
                  final vistosSel = <String>{};
                  final vistosNo = <String>{};
                  final seleccionados = <String>[];
                  final noSeleccionados = <String>[];
                  for (final c in categorias) {
                    final nombre = c.nombre;
                    if (nombre.isEmpty) continue;
                    if (catSeleccionadasIds.contains(c.id)) {
                      if (vistosSel.add(nombre)) seleccionados.add(nombre);
                    } else if (c.estado.trim().toLowerCase() == 'activo') {
                      if (vistosNo.add(nombre)) noSeleccionados.add(nombre);
                    }
                  }

                  if (seleccionados.isEmpty && noSeleccionados.isEmpty) {
                    return _emptyState(context, Icons.handyman_outlined,
                        'Sin servicios registrados');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _grupoServicios(
                        context,
                        titulo: 'Servicios seleccionados',
                        nombres: seleccionados,
                        seleccionado: true,
                      ),
                      const SizedBox(height: 18),
                      _grupoServicios(
                        context,
                        titulo: 'No seleccionados',
                        nombres: noSeleccionados,
                        seleccionado: false,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _serviciosLoader(BuildContext context) => Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      );

  /// Máximo de categorías visibles por grupo antes de mostrar "Ver más…".
  /// REQ-005 v1.0.4: el botón "Ver más" solo aparece si el grupo supera 10.
  static const int _maxChipsVisible = 10;

  /// Grupo de servicios (título + etiquetas con "Ver más…" si exceden el tope).
  Widget _grupoServicios(
    BuildContext context, {
    required String titulo,
    required List<String> nombres,
    required bool seleccionado,
  }) {
    final tituloColor = seleccionado
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).secondaryText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    fontSize: 13,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                    color: tituloColor,
                  ),
            ),
            if (nombres.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '(${nombres.length})',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      fontSize: 12,
                      letterSpacing: 0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (nombres.isEmpty)
          Text(
            'Ninguno',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(),
                  fontSize: 12,
                  letterSpacing: 0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...nombres.take(_maxChipsVisible).map(
                  (n) => _servicioTag(context, n, seleccionado: seleccionado)),
              if (nombres.length > _maxChipsVisible)
                _verMasChip(
                  context,
                  'Ver más (${nombres.length - _maxChipsVisible})',
                  () => _verTodosServiciosDialog(
                    context,
                    titulo: titulo,
                    nombres: nombres,
                    seleccionado: seleccionado,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Chip de acción "Ver más…" (estilo contorno, color primario).
  Widget _verMasChip(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FlutterFlowTheme.of(context).primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    fontSize: 13,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more,
                size: 16, color: FlutterFlowTheme.of(context).primary),
          ],
        ),
      ),
    );
  }

  /// Pop-up con TODOS los servicios del grupo, con scroll interno.
  void _verTodosServiciosDialog(
    BuildContext context, {
    required String titulo,
    required List<String> nombres,
    required bool seleccionado,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final screen = MediaQuery.sizeOf(ctx);
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: screen.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              seleccionado
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 20,
                              color: seleccionado
                                  ? _chipText
                                  : const Color(0xFF8A8A8A),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$titulo (${nombres.length})',
                                style: FlutterFlowTheme.of(ctx)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700),
                                      fontSize: 18,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          FlutterFlowTheme.of(ctx).primaryText,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Icon(Icons.close,
                            size: 22,
                            color: FlutterFlowTheme.of(ctx).secondaryText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: nombres
                            .map((n) => _servicioTag(ctx, n,
                                seleccionado: seleccionado))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _valueGray,
                        side: const BorderSide(color: Color(0xFF8A8A8A)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Etiqueta de servicio (seleccionado = verde con check; no = gris con X).
  Widget _servicioTag(BuildContext context, String nombre,
      {required bool seleccionado}) {
    final bg = seleccionado ? _chipBg : const Color(0xFFF0F0EF);
    final fg = seleccionado ? _chipText : const Color(0xFF8A8A8A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            seleccionado ? Icons.check_circle_outline : Icons.close,
            size: 15,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            nombre,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  fontSize: 13,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.access_time, 'Historial de servicios'),
          FutureBuilder<List<VwSolicitudesServiciosCompletaRow>>(
            future: VwSolicitudesServiciosCompletaTable().queryRows(
              queryFn: (q) => q.eqOrNull('profesional_id', widget.proveedorId),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }
              final historial = snapshot.data!.toList()
                ..sort((a, b) => (b.fecha ?? DateTime(1900))
                    .compareTo(a.fecha ?? DateTime(1900)));
              if (historial.isEmpty) {
                return _emptyState(context, Icons.history_toggle_off,
                    'Sin historial de servicios');
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < historial.length; i++) ...[
                      _timelineNode(context, historial[i]),
                      if (i < historial.length - 1)
                        Container(
                          width: 48,
                          height: 2,
                          margin: const EdgeInsets.only(top: 18),
                          color: FlutterFlowTheme.of(context).tertiary,
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _estadoLabel(String? estado) {
    switch (estado) {
      case 'finalizadas':
        return 'Servicio completado';
      case 'aceptadas':
        return 'Servicio activo';
      case 'entrantes':
        return 'Pendiente';
      case 'canceladas':
        return 'Cancelado';
      default:
        return 'Reprogramado';
    }
  }

  Widget _timelineNode(
      BuildContext context, VwSolicitudesServiciosCompletaRow item) {
    final fecha =
        item.fecha != null ? dateTimeFormat("d/M/y", item.fecha) : '—';
    final hora =
        item.hora?.time != null ? dateTimeFormat("Hm", item.hora?.time) : '';
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _chipBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 18, color: _chipText),
          ),
          const SizedBox(height: 8),
          Text(
            _estadoLabel(item.estadoSolicitud),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  fontSize: 14,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            valueOrDefault<String>(item.servicioNombre, 'Servicio'),
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(),
                  fontSize: 12,
                  letterSpacing: 0,
                  color: _labelGray,
                ),
          ),
          if ((item.clienteNombreCompleto ?? '').isNotEmpty)
            Text(
              'Cliente: ${item.clienteNombreCompleto}',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(),
                    fontSize: 12,
                    letterSpacing: 0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          const SizedBox(height: 2),
          Text(
            hora.isEmpty ? fecha : '$fecha - $hora',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(),
                  fontSize: 11,
                  letterSpacing: 0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 44, color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(height: 10),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
