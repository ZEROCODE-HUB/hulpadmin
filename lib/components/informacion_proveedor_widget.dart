import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/components/documentos_proveedor.dart';
import '/components/hulp_modal_actions.dart';
import '/components/modal_con_encabezado_fijo.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';

export 'informacion_proveedor_model.dart';

class InformacionProveedorWidget extends StatefulWidget {
  const InformacionProveedorWidget({
    super.key,
    required this.proveedorId,
  });

  final String? proveedorId;

  @override
  State<InformacionProveedorWidget> createState() =>
      _InformacionProveedorWidgetState();
}

class _InformacionProveedorWidgetState
    extends State<InformacionProveedorWidget> {
  late Future<List<UsuariosRow>> _usuarioFuture;
  late Future<List<CuentasBancariasRow>> _cuentasFuture;
  late Future<List<CertificacionesRow>> _certificacionesFuture;
  late Future<List<ReferenciasLaboralesRow>> _referenciasFuture;
  late Future<List<ProfesionalServiciosRow>> _serviciosFuture;

  @override
  void initState() {
    super.initState();
    _prepararConsultas();
  }

  @override
  void didUpdateWidget(covariant InformacionProveedorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proveedorId != widget.proveedorId) {
      _prepararConsultas();
    }
  }

  void _prepararConsultas() {
    _usuarioFuture = UsuariosTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('id', widget.proveedorId),
    );
    _cuentasFuture = CuentasBancariasTable().queryRows(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
    _certificacionesFuture = CertificacionesTable().queryRows(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
    _referenciasFuture = ReferenciasLaboralesTable().queryRows(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
    _serviciosFuture = ProfesionalServiciosTable().queryRows(
      queryFn: (q) => q.eqOrNull('usuario_id', widget.proveedorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = FlutterFlowTheme.of(context);
    final modalWidth = math.min(1220.0, size.width - 32.0).toDouble();
    final modalHeight = math.min(920.0, size.height * 0.92).toDouble();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: SizedBox(
          width: modalWidth,
          height: modalHeight,
          child: Material(
            color: theme.secondaryBackground,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(20.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 16.0),
              child: FutureBuilder<List<UsuariosRow>>(
                future: _usuarioFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _modalFrame(
                      context,
                      const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _modalFrame(
                      context,
                      _emptyState(
                        context,
                        'No se pudo cargar la información del proveedor.',
                        icon: Icons.error_outline,
                      ),
                    );
                  }

                  final usuarios = snapshot.data ?? const <UsuariosRow>[];
                  if (usuarios.isEmpty) {
                    return _modalFrame(
                      context,
                      _emptyState(
                        context,
                        'No se encontró la información de este proveedor.',
                        icon: Icons.person_off_outlined,
                      ),
                    );
                  }

                  return _modalFrame(
                    context,
                    _detalleProveedor(context, usuarios.first),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalFrame(BuildContext context, Widget contenido) {
    final theme = FlutterFlowTheme.of(context);
    return ModalConEncabezadoFijo(
      encabezado: Row(
        children: [
          Expanded(
            child: Text(
              'Información del proveedor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize:
                    MediaQuery.sizeOf(context).width < 520.0 ? 18.0 : 24.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: theme.primaryText, size: 24.0),
          ),
        ],
      ),
      fijarPie: true,
      cuerpo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: contenido,
          ),
          Align(
            key: modalFixedFooterKey,
            alignment: AlignmentDirectional.centerEnd,
            child: hulpModalCloseButton(
              text: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleProveedor(BuildContext context, UsuariosRow usuario) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _resumen(context, usuario),
        const SizedBox(height: 16.0),
        _datosLaborales(context, usuario),
        const SizedBox(height: 16.0),
        _serviciosOfrecidos(context),
      ],
    );
  }

  Widget _resumen(BuildContext context, UsuariosRow usuario) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perfil = _tarjetaPerfil(context, usuario);
        final datos = Column(
          children: [
            _panel(
              context,
              titulo: 'Identificación',
              icono: Icons.badge_outlined,
              child: _cuadriculaDatos(context, [
                _DatoProveedor('Tipo de documento', usuario.tipoDocumento),
                _DatoProveedor('Número de documento', usuario.numeroDocumento),
                _DatoProveedor('País', usuario.pais),
                _DatoProveedor('Número de teléfono', _telefono(usuario)),
              ]),
            ),
            const SizedBox(height: 10.0),
            _panel(
              context,
              titulo: 'Redes sociales',
              icono: Icons.share_outlined,
              child: _cuadriculaDatos(context, [
                _DatoProveedor('Perfil de Instagram', _redSocial(usuario, 0)),
                _DatoProveedor('Perfil de Facebook', _redSocial(usuario, 1)),
              ]),
            ),
            const SizedBox(height: 10.0),
            FutureBuilder<List<CuentasBancariasRow>>(
              future: _cuentasFuture,
              builder: (context, snapshot) {
                final cuentas = snapshot.data ?? const <CuentasBancariasRow>[];
                final cuenta = cuentas.isEmpty ? null : cuentas.first;
                return _panel(
                  context,
                  titulo: 'Datos bancarios',
                  icono: Icons.account_balance_outlined,
                  child: _cuadriculaDatos(context, [
                    _DatoProveedor('Entidad', cuenta?.entidadBancaria),
                    _DatoProveedor('Tipo de cuenta', cuenta?.tipoCuenta),
                    _DatoProveedor('Número de cuenta', cuenta?.numeroCuenta),
                    _DatoProveedor('RUT / NIT', usuario.registroTributario),
                  ]),
                );
              },
            ),
          ],
        );

        if (constraints.maxWidth >= 920.0) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 270.0, child: perfil),
              const SizedBox(width: 14.0),
              Expanded(child: datos),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [perfil, const SizedBox(height: 12.0), datos],
        );
      },
    );
  }

  Widget _tarjetaPerfil(BuildContext context, UsuariosRow usuario) {
    final theme = FlutterFlowTheme.of(context);
    final correo = _valor(usuario.correoElectronico);
    final nombre = [usuario.nombres, usuario.apellidos]
        .where((parte) => parte != null && parte.trim().isNotEmpty)
        .join(' ');
    final foto = usuario.fotoPerfilUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFD8E7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox(
                width: 104.0,
                height: 104.0,
                child: foto == null || foto.isEmpty
                    ? _avatarPlaceholder(theme)
                    : Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder(theme),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            nombre.isEmpty ? 'Proveedor sin nombre' : nombre,
            style: GoogleFonts.inter(
              color: theme.customColor1,
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10.0),
          _perfilDato(
            context,
            Icons.mail_outline,
            'Correo electrónico',
            correo,
          ),
          const SizedBox(height: 10.0),
          _perfilDato(context, Icons.location_city_outlined, 'Ciudad',
              _valor(usuario.ciudad)),
          const SizedBox(height: 10.0),
          _perfilDato(context, Icons.home_outlined, 'Dirección',
              _valor(usuario.direccion)),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(FlutterFlowTheme theme) => Container(
        color: const Color(0xFFE1E4E5),
        child: Icon(Icons.person, size: 70.0, color: theme.tertiary),
      );

  Widget _perfilDato(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 19.0, color: theme.primary),
        ),
        const SizedBox(width: 9.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12.0, color: theme.secondaryText)),
              const SizedBox(height: 2.0),
              SelectableText(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cuadriculaDatos(
    BuildContext context,
    List<_DatoProveedor> datos,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 420
                ? 2
                : 1;
        const gap = 12.0;
        final ancho = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
        return Wrap(
          spacing: gap,
          runSpacing: 10.0,
          children: datos
              .map((dato) => SizedBox(
                    width: ancho,
                    child: _valorDato(context, dato.titulo, dato.valor),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _valorDato(BuildContext context, String titulo, String? valor) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.inter(
            color: theme.secondaryText,
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 2.0),
        SelectableText(
          _valor(valor),
          style: GoogleFonts.inter(
            color: theme.primaryText,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _panel(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.tertiary.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(13.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F1EE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            ),
            child: Row(
              children: [
                _iconoEncabezado(context, icono),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    titulo,
                    style: GoogleFonts.inter(
                      color: theme.customColor1,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 12.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _iconoEncabezado(
    BuildContext context,
    IconData icono, {
    double size = 40.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDFF3E5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      alignment: Alignment.center,
      child: Icon(
        icono,
        color: FlutterFlowTheme.of(context).primary,
        size: size * 0.52,
      ),
    );
  }

  Widget _datosLaborales(BuildContext context, UsuariosRow usuario) {
    return _panel(
      context,
      titulo: 'Datos laborales',
      icono: Icons.work_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final documentos = _tarjetaDocumentosRegistro(context, usuario);
          final certificaciones = _tarjetaCertificaciones(context);
          final referencias = _tarjetaReferencias(context);
          if (constraints.maxWidth >= 900.0) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: documentos),
                const SizedBox(width: 12.0),
                Expanded(child: certificaciones),
                const SizedBox(width: 12.0),
                Expanded(child: referencias),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              documentos,
              const SizedBox(height: 12.0),
              certificaciones,
              const SizedBox(height: 12.0),
              referencias,
            ],
          );
        },
      ),
    );
  }

  Widget _subtarjeta(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Widget child,
    double alto = 270.0,
    Widget? trailing,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.tertiary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 6.0, 10.0, 6.0),
            child: Row(
              children: [
                _iconoEncabezado(context, icono, size: 36.0),
                const SizedBox(width: 9.0),
                Expanded(
                  child: Text(
                    titulo,
                    style: GoogleFonts.inter(
                      color: theme.customColor1,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1.0, color: theme.tertiary.withValues(alpha: 0.35)),
          SizedBox(height: alto - 49.0, child: child),
        ],
      ),
    );
  }

  Widget _tarjetaDocumentosRegistro(
    BuildContext context,
    UsuariosRow usuario,
  ) {
    final documentos = <_DocumentoInfo>[
      _DocumentoInfo('Cédula', usuario.cedula, 'cedula'),
      _DocumentoInfo('Cuenta bancaria', usuario.cuentaBancaria, 'cuenta'),
      _DocumentoInfo('Contrato', usuario.contrato, 'contrato'),
    ];
    final disponibles = documentos
        .where((documento) => documento.url?.trim().isNotEmpty ?? false)
        .toList();

    return _subtarjeta(
      context,
      titulo: 'Documentos de registro',
      icono: Icons.description_outlined,
      child: disponibles.isEmpty
          ? _emptyState(
              context,
              'Este proveedor aún no tiene documentos de registro.',
              icon: Icons.upload_file_outlined,
              compacto: true,
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              itemCount: disponibles.length,
              separatorBuilder: (_, __) => const Divider(height: 1.0),
              itemBuilder: (context, index) => _DocumentoProveedorCompacto(
                documento: disponibles[index],
                proveedorId: widget.proveedorId,
              ),
            ),
    );
  }

  Widget _tarjetaCertificaciones(BuildContext context) {
    return FutureBuilder<List<CertificacionesRow>>(
      future: _certificacionesFuture,
      builder: (context, snapshot) {
        final certificaciones = snapshot.data ?? const <CertificacionesRow>[];
        return _subtarjeta(
          context,
          titulo: 'Certificaciones',
          icono: Icons.workspace_premium_outlined,
          child: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? _emptyState(
                      context, 'No se pudieron cargar las certificaciones.',
                      icon: Icons.error_outline, compacto: true)
                  : certificaciones.isEmpty
                      ? _emptyState(
                          context,
                          'No hay certificaciones registradas.',
                          icon: Icons.workspace_premium_outlined,
                          compacto: true,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          itemCount: certificaciones.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1.0),
                          itemBuilder: (context, index) {
                            final certificacion = certificaciones[index];
                            return _DocumentoProveedorCompacto(
                              documento: _DocumentoInfo(
                                certificacion.entidadCertificadora,
                                certificacion.documentoUrl,
                                'certificacion',
                              ),
                              proveedorId: certificacion.id,
                            );
                          },
                        ),
        );
      },
    );
  }

  Widget _tarjetaReferencias(BuildContext context) {
    return FutureBuilder<List<ReferenciasLaboralesRow>>(
      future: _referenciasFuture,
      builder: (context, snapshot) {
        final referencias = snapshot.data ?? const <ReferenciasLaboralesRow>[];
        final contador = snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF3E5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '${referencias.length}',
                  style: GoogleFonts.inter(
                    color: FlutterFlowTheme.of(context).customColor1,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null;

        return _subtarjeta(
          context,
          titulo: 'Referencias',
          icono: Icons.groups_outlined,
          trailing: contador,
          child: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? _emptyState(
                      context, 'No se pudieron cargar las referencias.',
                      icon: Icons.error_outline, compacto: true)
                  : referencias.isEmpty
                      ? _emptyState(
                          context,
                          'No hay referencias registradas.',
                          icon: Icons.people_outline,
                          compacto: true,
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                            itemCount: referencias.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 12.0,
                              color: FlutterFlowTheme.of(context)
                                  .tertiary
                                  .withValues(alpha: 0.45),
                            ),
                            itemBuilder: (context, index) {
                              final referencia = referencias[index];
                              return _referencia(context, referencia);
                            },
                          ),
                        ),
        );
      },
    );
  }

  Widget _referencia(
    BuildContext context,
    ReferenciasLaboralesRow referencia,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _referenciaDato(
            context, 'Nombre de la referencia', referencia.nombreReferencia),
        const SizedBox(height: 5.0),
        _referenciaDato(context, 'Teléfono', referencia.telefonoReferencia),
        const SizedBox(height: 5.0),
        _referenciaDato(
            context, 'Relación laboral', referencia.relacionLaboral),
      ],
    );
  }

  Widget _referenciaDato(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 11.0, color: theme.secondaryText),
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.0,
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _serviciosOfrecidos(BuildContext context) {
    return FutureBuilder<List<ProfesionalServiciosRow>>(
      future: _serviciosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _panel(
            context,
            titulo: 'Servicios ofrecidos',
            icono: Icons.layers_outlined,
            child: const SizedBox(
              height: 96.0,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return _panel(
            context,
            titulo: 'Servicios ofrecidos',
            icono: Icons.layers_outlined,
            child: _emptyState(context, 'No se pudieron cargar los servicios.',
                icon: Icons.error_outline, compacto: true),
          );
        }
        return _panel(
          context,
          titulo: 'Servicios ofrecidos',
          icono: Icons.layers_outlined,
          child: custom_widgets.CrearProveedor(
            width: double.infinity,
            serviciosid: (snapshot.data ?? const <ProfesionalServiciosRow>[])
                .map((servicio) => servicio.servicioId)
                .toList(),
            readOnly: true,
          ),
        );
      },
    );
  }

  Widget _emptyState(
    BuildContext context,
    String text, {
    required IconData icon,
    bool compacto = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8.0 : 24.0,
        vertical: compacto ? 16.0 : 48.0,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.primary.withValues(alpha: 0.7), size: 30.0),
            const SizedBox(height: 8.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: theme.secondaryText,
                fontSize: compacto ? 12.0 : 15.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _valor(String? value) =>
      value == null || value.trim().isEmpty ? 'No registrado' : value.trim();

  String _telefono(UsuariosRow usuario) {
    final codigo = usuario.codigoPais?.trim() ?? '';
    final numero = usuario.telefono?.trim() ?? '';
    return [codigo, numero].where((parte) => parte.isNotEmpty).join(' ');
  }

  String _redSocial(UsuariosRow usuario, int indice) {
    final redes = usuario.redesSociales;
    if (indice >= redes.length || redes[indice].trim().isEmpty) {
      return indice == 0 ? 'Sin Instagram' : 'Sin Facebook';
    }
    return redes[indice];
  }
}

class _DatoProveedor {
  const _DatoProveedor(this.titulo, this.valor);

  final String titulo;
  final String? valor;
}

class _DocumentoInfo {
  const _DocumentoInfo(this.titulo, this.url, this.prefijo);

  final String titulo;
  final String? url;
  final String prefijo;
}

class _DocumentoProveedorCompacto extends StatefulWidget {
  const _DocumentoProveedorCompacto({
    required this.documento,
    required this.proveedorId,
  });

  final _DocumentoInfo documento;
  final String? proveedorId;

  @override
  State<_DocumentoProveedorCompacto> createState() =>
      _DocumentoProveedorCompactoState();
}

class _DocumentoProveedorCompactoState
    extends State<_DocumentoProveedorCompacto> {
  bool _descargando = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final url = widget.documento.url;
    final tieneArchivo = url != null && url.trim().isNotEmpty;
    final nombreArchivo = nombreArchivoDocumento(url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 20.0, color: theme.customColor1),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documento.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: theme.primaryText,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tieneArchivo ? nombreArchivo : 'Sin archivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
          if (tieneArchivo) ...[
            const SizedBox(width: 4.0),
            _accionDocumento(
              context,
              tooltip: 'Ver documento',
              icon: Icons.visibility_outlined,
              onPressed: _abrir,
            ),
            _accionDocumento(
              context,
              tooltip: _descargando ? 'Descargando' : 'Descargar documento',
              icon: _descargando
                  ? Icons.hourglass_top_rounded
                  : Icons.download_outlined,
              onPressed: _descargando ? null : _descargar,
            ),
          ],
        ],
      ),
    );
  }

  Widget _accionDocumento(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 34.0, height: 34.0),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFDFF3E5),
          foregroundColor: theme.primary,
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon, size: 18.0),
      ),
    );
  }

  Future<void> _abrir() async {
    try {
      final url = await resolverUrlDocumento(widget.documento.url);
      if (url == null) throw Exception('Documento no disponible');
      await abrirDocumento(url);
    } catch (_) {
      _notificar('No se pudo abrir el documento.');
    }
  }

  Future<void> _descargar() async {
    setState(() => _descargando = true);
    try {
      final url = await resolverUrlDocumento(widget.documento.url);
      if (url == null) throw Exception('Documento no disponible');
      final archivo = nombreArchivoDocumento(widget.documento.url);
      final extension = archivo.contains('.') ? archivo.split('.').last : 'bin';
      final nombre =
          '${widget.documento.prefijo}_${widget.proveedorId ?? 'documento'}.$extension';
      await descargarDocumento(url, nombre);
    } catch (_) {
      _notificar('No se pudo descargar el documento.');
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  void _notificar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
