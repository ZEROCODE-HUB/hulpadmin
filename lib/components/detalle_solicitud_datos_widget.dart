import 'package:flutter/material.dart';
import '/backend/supabase/supabase.dart';
import '/components/chat_usuario_proveedor_widget.dart';
import '/components/enlace_mapa_widget.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/ubicacion_helpers.dart';

class DetalleSolicitudDatosWidget extends StatelessWidget {
  const DetalleSolicitudDatosWidget({
    super.key,
    required this.solicitud,
    required this.mostrarChat,
    required this.onAlternarChat,
  });

  final VwSolicitudesServiciosCompletaRow solicitud;
  final bool mostrarChat;
  final VoidCallback onAlternarChat;

  @override
  Widget build(BuildContext context) {
    final proveedorAsignado = (solicitud.profesionalId ?? '').trim().isNotEmpty;

    return LayoutBuilder(builder: (context, constraints) {
      final ancho = constraints.maxWidth;
      final servicio = _tarjetaServicio(context);
      final contactos = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tarjetaContacto(
            context,
            titulo: 'Usuario',
            icono: Icons.person_outline_rounded,
            nombre: nombreClienteVisible(solicitud.clienteNombreCompleto),
            telefono: solicitud.clienteTelefono,
            correo: solicitud.clienteCorreo,
          ),
          const SizedBox(height: 14),
          _tarjetaContacto(
            context,
            titulo: 'Proveedor',
            icono: Icons.work_outline_rounded,
            nombre: proveedorAsignado
                ? _valor(solicitud.proveedorNombreCompleto,
                    alternativa: 'Proveedor sin nombre')
                : 'Sin proveedor asignado',
            telefono: proveedorAsignado ? solicitud.proveedorTelefono : null,
            correo: proveedorAsignado ? solicitud.proveedorCorreo : null,
            sinContacto: !proveedorAsignado,
          ),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ancho >= 760)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: servicio),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: contactos),
                ],
              ),
            )
          else ...[
            servicio,
            const SizedBox(height: 14),
            contactos,
          ],
          const SizedBox(height: 16),
          if (ancho >= 700)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _tarjetaNota(context, 'Notas del cliente',
                        solicitud.notasCliente, Icons.sticky_note_2_outlined,
                        vacio: 'Sin notas del cliente')),
                const SizedBox(width: 16),
                Expanded(
                    child: _tarjetaNota(
                        context,
                        'Notas internas',
                        solicitud.informacionAdicional,
                        Icons.sticky_note_2_outlined,
                        vacio: 'Sin notas internas')),
              ],
            )
          else ...[
            _tarjetaNota(context, 'Notas del cliente', solicitud.notasCliente,
                Icons.sticky_note_2_outlined,
                vacio: 'Sin notas del cliente'),
            const SizedBox(height: 14),
            _tarjetaNota(context, 'Notas internas',
                solicitud.informacionAdicional, Icons.sticky_note_2_outlined,
                vacio: 'Sin notas internas'),
          ],
          if (proveedorAsignado) ...[
            const SizedBox(height: 16),
            _tarjetaChat(context),
          ],
        ],
      );
    });
  }

  Widget _tarjetaServicio(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    final ubicacion =
        _valor(solicitud.ubicacion, alternativa: 'Sin dirección especificada');
    final fechaHora = [
      if (solicitud.fecha != null) dateTimeFormat('d/M/y', solicitud.fecha),
      if (solicitud.hora?.time != null)
        dateTimeFormat('jm', solicitud.hora!.time),
    ].join(' · ');
    final coordenadas = solicitud.latitud != null && solicitud.longitud != null
        ? Coordenadas(solicitud.latitud!, solicitud.longitud!).formateadas
        : null;
    final subcategoria = solicitud.subcategoriaNombre?.trim();

    return _tarjeta(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoTarjeta(context, 'Servicio', Icons.handyman_outlined),
          const SizedBox(height: 10),
          Text(
            _valor(solicitud.servicioNombre,
                alternativa: 'Servicio sin especificar'),
            style: tema.titleLarge.copyWith(fontWeight: FontWeight.w700),
            softWrap: true,
          ),
          if (subcategoria != null && subcategoria.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(subcategoria,
                  style: tema.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 18),
          _lineaDato(
            context,
            Icons.calendar_today_outlined,
            fechaHora.isEmpty ? 'Fecha y hora sin especificar' : fechaHora,
          ),
          const SizedBox(height: 12),
          _lineaDato(context, Icons.location_on_outlined, ubicacion),
          EnlaceMapaWidget(
            latitud: solicitud.latitud,
            longitud: solicitud.longitud,
            direccion: solicitud.ubicacion,
            mostrarCoordenadas: false,
          ),
          if (coordenadas != null) ...[
            const SizedBox(height: 12),
            _lineaDato(context, Icons.my_location_outlined, coordenadas),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaContacto(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required String nombre,
    required String? telefono,
    required String? correo,
    bool sinContacto = false,
  }) {
    return _tarjeta(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoTarjeta(context, titulo, icono),
          const SizedBox(height: 12),
          if (sinContacto)
            Text(nombre, style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            _lineaContacto(
              context,
              Icons.person_outline_rounded,
              nombre,
              destacado: true,
            ),
            const SizedBox(height: 8),
            _lineaContacto(
              context,
              Icons.call_outlined,
              _valor(telefono, alternativa: 'Sin teléfono registrado'),
            ),
            const SizedBox(height: 8),
            _lineaContacto(
              context,
              Icons.mail_outline_rounded,
              _valor(correo, alternativa: 'Sin correo registrado'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineaContacto(
    BuildContext context,
    IconData icono,
    String texto, {
    bool destacado = false,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: const Color(0xFF0B6244)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: destacado ? FontWeight.w600 : FontWeight.normal,
                  ),
              softWrap: true,
            ),
          ),
        ],
      );

  Widget _tarjetaNota(
    BuildContext context,
    String titulo,
    String? contenido,
    IconData icono, {
    required String vacio,
  }) {
    final texto = contenido?.trim();
    return _tarjeta(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoTarjeta(context, titulo, icono),
          const SizedBox(height: 10),
          Text(
            texto == null || texto.isEmpty ? vacio : texto,
            style: Theme.of(context).textTheme.bodyLarge,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _tarjetaChat(BuildContext context) {
    final proveedor =
        _valor(solicitud.proveedorNombreCompleto, alternativa: 'Proveedor');
    final cliente = nombreClienteVisible(solicitud.clienteNombreCompleto);
    final tema = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F2),
        border: Border.all(color: const Color(0xFFDCE8DF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onAlternarChat,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  _iconoTarjeta(Icons.chat_bubble_outline_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat de la solicitud',
                            style: tema.titleMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('Proveedor: $proveedor  ·  Cliente: $cliente',
                            style: tema.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(mostrarChat ? Icons.expand_less : Icons.expand_more,
                      size: 26),
                ],
              ),
            ),
          ),
          if (mostrarChat) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ChatUsuarioProveedorWidget(solicitud: solicitud),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjeta(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E2DF)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _encabezadoTarjeta(
          BuildContext context, String titulo, IconData icono) =>
      Row(
        children: [
          _iconoTarjeta(icono),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: FlutterFlowTheme.of(context)
                  .titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );

  Widget _iconoTarjeta(IconData icono) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFDDF1E1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icono, color: const Color(0xFF0B6244), size: 23),
      );

  Widget _lineaDato(BuildContext context, IconData icono, String texto) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: const Color(0xFF0B6244)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: Theme.of(context).textTheme.bodyLarge, softWrap: true),
          ),
        ],
      );

  static String _valor(String? text, {required String alternativa}) {
    final value = text?.trim();
    return value == null || value.isEmpty ? alternativa : value;
  }
}
