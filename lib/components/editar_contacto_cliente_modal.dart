import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import '/components/hulp_modal_actions.dart';
import '/backend/actualizar_cliente_solicitud.dart';
import 'modal_con_encabezado_fijo.dart';

class ContactoClienteEditado {
  const ContactoClienteEditado(this.telefono, this.correo);
  final String telefono, correo;
}

class EditarContactoClienteModal extends StatefulWidget {
  const EditarContactoClienteModal(
      {super.key,
      required this.usuarioId,
      required this.nombreCliente,
      required this.telefono,
      required this.correo,
      this.guardar});
  final String usuarioId, nombreCliente, telefono, correo;
  final Future<void> Function(String telefono, String correo)? guardar;
  @override
  State<EditarContactoClienteModal> createState() =>
      _EditarContactoClienteModalState();
}

class _EditarContactoClienteModalState
    extends State<EditarContactoClienteModal> {
  static const verde = Color(0xFF086349);
  final form = GlobalKey<FormState>();
  late final telefono = TextEditingController(text: widget.telefono);
  late final correo = TextEditingController(text: widget.correo);
  bool guardando = false;
  String? error;
  @override
  void dispose() {
    telefono.dispose();
    correo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (guardando || !(form.currentState?.validate() ?? false)) return;
    final t = telefono.text.trim(), c = correo.text.trim().toLowerCase();
    setState(() {
      guardando = true;
      error = null;
    });
    try {
      if (widget.guardar != null) {
        await widget.guardar!(t, c);
      } else {
        await actualizarClienteSolicitud(
            usuarioId: widget.usuarioId,
            telefono: t,
            correoElectronico: c,
            direccion: '',
            ciudad: '',
            soloContacto: true);
      }
      if (mounted) Navigator.of(context).pop(ContactoClienteEditado(t, c));
    } on ActualizarClienteSolicitudException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted)
        setState(() =>
            error = 'No se pudo guardar el contacto. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  InputDecoration _decoracion() => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFBFAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFD5D0CA))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFD5D0CA))));
  Widget _campo(String label, TextEditingController controller,
          TextInputType tipo, String? Function(String?) validar) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
            controller: controller,
            enabled: !guardando,
            keyboardType: tipo,
            decoration: decorarInputHulp(
              context,
              _decoracion(),
              etiqueta: label,
              soloLectura: guardando,
            ),
            validator: validar)
      ]);
  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !guardando,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                EncabezadoModal(
                    habilitado: !guardando,
                    titulo: const Text('Editar contacto del cliente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600))),
                const SizedBox(height: 4),
                Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 7,
                    children: [
                      const Icon(Icons.person_outline,
                          color: Color(0xFF606B70), size: 18),
                      Text(widget.nombreCliente,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15))
                    ]),
                const SizedBox(height: 22),
                Flexible(
                    child: SingleChildScrollView(
                        child: Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LayoutBuilder(builder: (context, c) {
                                    final campos = [
                                      _campo(
                                          'Teléfono *',
                                          telefono,
                                          TextInputType.phone,
                                          (v) => (v?.trim().isEmpty ?? true)
                                              ? 'Ingresa el teléfono.'
                                              : null),
                                      _campo(
                                          widget.correo.trim().isEmpty
                                              ? 'Correo electrónico'
                                              : 'Correo electrónico *',
                                          correo,
                                          TextInputType.emailAddress, (v) {
                                        final text = v?.trim() ?? '';
                                        if (text.isEmpty &&
                                            widget.correo.trim().isEmpty)
                                          return null;
                                        return RegExp(
                                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                .hasMatch(text)
                                            ? null
                                            : 'Ingresa un correo válido.';
                                      }),
                                    ];
                                    if (c.maxWidth < 460)
                                      return Column(children: [
                                        campos[0],
                                        const SizedBox(height: 14),
                                        campos[1]
                                      ]);
                                    return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: campos[0]),
                                          const SizedBox(width: 14),
                                          Expanded(child: campos[1])
                                        ]);
                                  }),
                                  const SizedBox(height: 16),
                                  const Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 14, color: Color(0xFF757575)),
                                        SizedBox(width: 6),
                                        Expanded(
                                            child: Text(
                                                'Estos cambios se guardan en el perfil del cliente.',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: Color(0xFF757575))))
                                      ]),
                                  if (error != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(error!,
                                            style: const TextStyle(
                                                color: Colors.red))),
                                ])))),
                const Divider(height: 26),
                Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          hulpModalCloseButton(
                              text: 'Cancelar',
                              onPressed: guardando
                                  ? null
                                  : () => Navigator.pop(context)),
                          hulpModalPrimaryButton(
                              context: context,
                              text: guardando
                                  ? 'Guardando...'
                                  : 'Guardar contacto',
                              onPressed: guardando ? null : _guardar),
                        ])),
              ])),
        ),
      ));
}
