import 'dart:convert';
import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import '/components/hulp_modal_actions.dart';
import '/backend/supabase/supabase.dart';
import '/backend/direcciones_cliente.dart';
import '/backend/actualizar_cliente_solicitud.dart';
import '/flutter_flow/cliente_nombre_helpers.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'searchable_dropdown_widget.dart';
import 'selector_ubicacion_widget.dart';

class EditarClienteModal extends StatefulWidget {
  const EditarClienteModal(
      {super.key,
      required this.perfil,
      this.repository,
      this.guardarContacto,
      this.mapaBuilder});
  final UsuariosRow perfil;
  final DireccionesClienteRepository? repository;
  final Future<void> Function(String telefono, String correo)? guardarContacto;
  final Widget Function(ValueChanged<Coordenadas?> onCambio)? mapaBuilder;
  @override
  State<EditarClienteModal> createState() => _EditarClienteModalState();
}

class _EditarClienteModalState extends State<EditarClienteModal> {
  static const verde = Color(0xFF086349);
  late final DireccionesClienteRepository repo =
      widget.repository ?? DireccionesClienteRepository();
  final contactoForm = GlobalKey<FormState>();
  final direccionForm = GlobalKey<FormState>();
  late final telefono =
      TextEditingController(text: widget.perfil.telefono ?? '');
  late final correo =
      TextEditingController(text: widget.perfil.correoElectronico ?? '');
  final nombre = TextEditingController(),
      direccion = TextEditingController(),
      complemento = TextEditingController(),
      referencia = TextEditingController();
  late String contactoInicial;
  String direccionInicial = '';
  List<DireccionCliente> direcciones = [];
  List<CiudadesRow> ciudades = [];
  DireccionCliente? seleccion;
  String tipo = 'casa';
  String? ciudad;
  Coordenadas? punto;
  bool nuevo = false, cargando = true, guardando = false, cambiado = false;
  int tab = 0, revisionMapa = 0;
  String? error, aviso;
  String get contactoActual =>
      jsonEncode([telefono.text.trim(), correo.text.trim()]);
  String get direccionActual => jsonEncode([
        tipo,
        nombre.text.trim(),
        direccion.text.trim(),
        complemento.text.trim(),
        referencia.text.trim(),
        ciudad,
        punto?.latitud,
        punto?.longitud
      ]);
  bool get contactoSucio => contactoActual != contactoInicial;
  bool get direccionSucia =>
      (seleccion != null || nuevo) && direccionActual != direccionInicial;
  bool get sucio => tab == 0 ? contactoSucio : direccionSucia;
  @override
  void initState() {
    super.initState();
    contactoInicial = contactoActual;
    for (final c in [
      telefono,
      correo,
      nombre,
      direccion,
      complemento,
      referencia
    ]) {
      c.addListener(_actualizar);
    }
    _cargar();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      telefono,
      correo,
      nombre,
      direccion,
      complemento,
      referencia
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar({String? seleccionar}) async {
    try {
      final values = await Future.wait([
        repo.cargarTodas(widget.perfil.id),
        repo.ciudades(soloActivas: true)
      ]);
      if (!mounted) return;
      direcciones = values[0] as List<DireccionCliente>;
      ciudades = values[1] as List<CiudadesRow>;
      final id = seleccionar ?? seleccion?.id;
      final actual = direcciones.where((d) => d.id == id).firstOrNull;
      _seleccionar(actual ?? (direcciones.isEmpty ? null : direcciones.first));
      setState(() {
        cargando = false;
        error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          cargando = false;
          error = 'No se pudieron cargar las direcciones. Inténtalo de nuevo.';
        });
    }
  }

  void _seleccionar(DireccionCliente? d, {bool crear = false}) {
    seleccion = d;
    nuevo = crear;
    tipo = d?.data['tipo'] as String? ?? 'casa';
    nombre.text = d?.data['nombre'] as String? ?? '';
    direccion.text = d?.data['direccion'] as String? ?? '';
    complemento.text = d?.data['complemento'] as String? ?? '';
    referencia.text = d?.data['referencia'] as String? ?? '';
    ciudad = d?.ciudadId;
    punto = d?.punto;
    revisionMapa++;
    direccionInicial = direccionActual;
  }

  Future<bool> _confirmarDescarte() async {
    if (!sucio) return true;
    return await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('Cambios sin guardar'),
                  content: const Text(
                      '¿Deseas descartar los cambios que aún no guardaste?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Seguir editando')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Descartar'))
                  ],
                )) ??
        false;
  }

  Future<void> _cambiarTab(int value) async {
    if (value == tab || guardando || !await _confirmarDescarte() || !mounted)
      return;
    if (tab == 0) {
      final a = jsonDecode(contactoInicial) as List;
      telefono.text = a[0] as String;
      correo.text = a[1] as String;
    } else {
      _seleccionar(seleccion);
    }
    setState(() {
      tab = value;
      error = null;
      aviso = null;
    });
  }

  Future<void> _cambiarDireccion(DireccionCliente? d,
      {bool crear = false}) async {
    if (!crear && !nuevo && d?.id == seleccion?.id) return;
    if (guardando || !await _confirmarDescarte() || !mounted) return;
    setState(() {
      _seleccionar(d, crear: crear);
      error = null;
      aviso = null;
    });
  }

  Future<bool> _puedeCerrar() async => !guardando && await _confirmarDescarte();
  Future<void> _cerrar() async {
    if (await _puedeCerrar() && mounted) Navigator.of(context).pop(cambiado);
  }

  Future<void> _guardarContacto() async {
    if (guardando || !(contactoForm.currentState?.validate() ?? false)) return;
    setState(() {
      guardando = true;
      error = null;
      aviso = null;
    });
    try {
      if (widget.guardarContacto != null) {
        await widget.guardarContacto!(telefono.text.trim(), correo.text.trim());
      } else {
        final ciudadPerfil = widget.perfil.ciudad?.trim() ?? '';
        await actualizarClienteSolicitud(
            usuarioId: widget.perfil.id,
            telefono: telefono.text.trim(),
            correoElectronico: correo.text.trim(),
            direccion: widget.perfil.direccion ?? '',
            ciudad: ciudadPerfil,
            soloContacto: true);
      }
      if (!mounted) return;
      setState(() {
        contactoInicial = contactoActual;
        widget.perfil.telefono = telefono.text.trim();
        widget.perfil.correoElectronico =
            correo.text.trim().isEmpty ? null : correo.text.trim();
        cambiado = true;
        aviso = 'Datos de contacto guardados.';
      });
    } on ActualizarClienteSolicitudException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted)
        setState(() => error = 'No se pudieron guardar los datos de contacto.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _guardarDireccion() async {
    if (guardando || !(direccionForm.currentState?.validate() ?? false)) return;
    if (ciudad == null || !ciudades.any((c) => c.id == ciudad)) {
      setState(() => error = 'Selecciona una ciudad activa.');
      return;
    }
    setState(() {
      guardando = true;
      error = null;
      aviso = null;
    });
    try {
      final datos = <String, dynamic>{
        'tipo': tipo,
        'nombre': tipo == 'otra' ? nombre.text.trim() : null,
        'direccion': direccion.text.trim(),
        'complemento':
            complemento.text.trim().isEmpty ? null : complemento.text.trim(),
        'referencia':
            referencia.text.trim().isEmpty ? null : referencia.text.trim(),
        'ciudad_id': ciudad,
        'latitud': punto?.latitud,
        'longitud': punto?.longitud
      };
      final guardada = nuevo
          ? await repo.guardar({...datos, 'usuario_id': widget.perfil.id})
          : await repo.actualizar(widget.perfil.id, seleccion!.id, datos,
              activa: seleccion!.activa);
      if (!mounted) return;
      cambiado = true;
      _seleccionar(guardada);
      await _cargar(seleccionar: guardada.id);
      if (mounted && error == null)
        setState(() => aviso = 'Dirección guardada.');
    } catch (_) {
      if (mounted)
        setState(() => error =
            'No se pudo guardar la dirección. Revisa los datos e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _archivar() async {
    if (seleccion == null ||
        guardando ||
        !await _confirmarDescarte() ||
        !mounted) return;
    final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Archivar dirección'),
                    content: const Text(
                        'La dirección quedará archivada y no podrá seleccionarse para nuevas solicitudes.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Archivar'))
                    ])) ??
        false;
    if (!ok || !mounted) return;
    setState(() {
      guardando = true;
      error = null;
      aviso = null;
    });
    try {
      final id = seleccion!.id;
      await repo.archivar(widget.perfil.id, id);
      if (!mounted) return;
      cambiado = true;
      await _cargar(seleccionar: id);
      if (mounted && error == null)
        setState(() => aviso = 'Dirección archivada.');
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo archivar la dirección.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _desarchivar() async {
    if (seleccion == null || seleccion!.activa || guardando) return;
    if (direccionSucia) {
      setState(() =>
          error = 'Guarda los cambios de la dirección antes de desarchivarla.');
      return;
    }
    if (ciudad == null || !ciudades.any((c) => c.id == ciudad)) {
      setState(() => error =
          'Selecciona una ciudad activa y guarda la dirección antes de desarchivarla.');
      return;
    }
    final id = seleccion!.id;
    setState(() {
      guardando = true;
      error = null;
      aviso = null;
    });
    try {
      await repo.desarchivar(widget.perfil.id, id);
      if (!mounted) return;
      cambiado = true;
      await _cargar(seleccionar: id);
      if (mounted && error == null)
        setState(() => aviso = 'Dirección desarchivada.');
    } catch (_) {
      if (mounted)
        setState(() => error =
            'No se pudo desarchivar la dirección. Verifica que la ciudad siga activa.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  InputDecoration _input(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFBFAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD5D0CA))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD5D0CA))));
  Widget _campo(String label, TextEditingController controller,
          {String hint = '', String? Function(String?)? validator}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label),
            const SizedBox(height: 6),
            TextFormField(
                controller: controller,
                decoration: decorarInputHulp(
                  context,
                  _input(hint),
                  etiqueta: label,
                ),
                validator: validator)
          ]));
  Widget _contacto() => Form(
      key: contactoForm,
      child: LayoutBuilder(builder: (context, constraints) {
        final fields = [
          _campo('Teléfono', telefono, hint: 'Teléfono'),
          _campo('Correo electrónico', correo, hint: 'Correo electrónico',
              validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty &&
                (widget.perfil.correoElectronico?.trim().isEmpty ?? true))
              return null;
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text))
              return 'Ingresa un correo electrónico válido.';
            return null;
          }),
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Datos de contacto',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          if (constraints.maxWidth < 520)
            ...fields
          else
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: fields[0]),
              const SizedBox(width: 16),
              Expanded(child: fields[1])
            ]),
          const SizedBox(height: 10),
          const Text(
              'Las direcciones se administran en la pestaña Direcciones.',
              style: TextStyle(color: Colors.grey)),
        ]);
      }));
  Widget _lista() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Direcciones',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final d in direcciones)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: seleccion?.id == d.id && !nuevo
                      ? const Color(0xFFE5F2E9)
                      : const Color(0xFFFBFAF9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: seleccion?.id == d.id && !nuevo
                              ? verde
                              : const Color(0xFFD5D0CA))),
                  child: InkWell(
                      onTap: () => _cambiarDireccion(d),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            const Icon(Icons.location_on_outlined,
                                color: verde),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(d.etiqueta,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Tooltip(
                                      message: d.completa,
                                      child: Text(
                                          [
                                            (d.data['direccion'] as String? ??
                                                    '')
                                                .trim(),
                                            ciudades
                                                    .where((c) =>
                                                        c.id == d.ciudadId)
                                                    .firstOrNull
                                                    ?.nombre ??
                                                '',
                                          ]
                                              .where((s) => s.isNotEmpty)
                                              .join(', '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis))
                                ])),
                            const SizedBox(width: 6),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                    color: d.activa
                                        ? const Color(0xFFD8F2DC)
                                        : const Color(0xFFE9E9E9),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(d.activa ? 'Activa' : 'Archivada',
                                    style: TextStyle(
                                        color:
                                            d.activa ? verde : Colors.black54,
                                        fontSize: 12)))
                          ]))))),
        OutlinedButton.icon(
            onPressed:
                guardando ? null : () => _cambiarDireccion(null, crear: true),
            icon: const Icon(Icons.add),
            label: const Text('Agregar dirección'),
            style: OutlinedButton.styleFrom(foregroundColor: verde)),
      ]);
  Widget _editorDireccion() {
    if (seleccion == null && !nuevo)
      return const Center(child: Text('Agrega una dirección para comenzar.'));
    final seleccionada = ciudades.where((c) => c.id == ciudad).firstOrNull;
    return Form(
        key: direccionForm,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tipo *'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (final t in ['casa', 'oficina', 'otra'])
              ChoiceChip(
                  label: Text({
                    'casa': 'Casa',
                    'oficina': 'Oficina',
                    'otra': 'Otra'
                  }[t]!),
                  selected: tipo == t,
                  selectedColor: verde,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                      side: const BorderSide(color: Color(0xFFD5D0CA))),
                  backgroundColor: const Color(0xFFFBFAF9),
                  labelStyle: TextStyle(
                      color: tipo == t ? Colors.white : Colors.black87),
                  onSelected:
                      guardando ? null : (_) => setState(() => tipo = t))
          ]),
          const SizedBox(height: 12),
          if (tipo == 'otra')
            _campo('Nombre de la dirección *', nombre,
                hint: 'Ej. Casa de mamá',
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Ingresa un nombre.' : null),
          _campo('Dirección *', direccion,
              hint: 'Calle y número',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Ingresa la dirección.' : null),
          LayoutBuilder(builder: (context, constraints) {
            final complementoField = _campo(
                'Complemento (opcional)', complemento,
                hint: 'Ej. Apto 101, Torre A');
            final referenciaField = _campo('Referencia (opcional)', referencia,
                hint: 'Ej. Portería norte');
            if (constraints.maxWidth < 400) {
              return Column(children: [complementoField, referenciaField]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: complementoField),
              const SizedBox(width: 12),
              Expanded(child: referenciaField),
            ]);
          }),
          const Text('Ciudad *'),
          const SizedBox(height: 6),
          SearchableDropdown(
              values: ciudades.map((c) => c.id).toList(),
              labels: ciudades.map((c) => c.nombre).toList(),
              selectedValue: seleccionada?.id,
              hint: 'Seleccionar ciudad...',
              onChanged: (id) {
                if (guardando || id == ciudad) return;
                setState(() {
                  ciudad = id;
                  punto = null;
                  revisionMapa++;
                });
              }),
          if (ciudad != null && seleccionada == null)
            const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Selecciona una ciudad activa.',
                    style: TextStyle(color: Colors.red))),
          const SizedBox(height: 14),
          widget.mapaBuilder != null
              ? widget.mapaBuilder!((v) => setState(() => punto = v))
              : SelectorUbicacionWidget(
                  key: ValueKey('direccion-$revisionMapa'),
                  coordenadasIniciales: punto,
                  ciudadId: ciudad,
                  nombreCiudad: seleccionada?.nombre,
                  direccionActual: () => direccion.text,
                  onDireccionSugerida: (v) => direccion.text = v,
                  onCambio: (v) {
                    if (mounted) setState(() => punto = v);
                  }),
        ]));
  }

  Widget _direcciones() {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null && ciudades.isEmpty)
      return Column(children: [
        Text(error!),
        TextButton(
            onPressed: () {
              setState(() => cargando = true);
              _cargar();
            },
            child: const Text('Reintentar'))
      ]);
    return LayoutBuilder(
        builder: (context, c) => c.maxWidth < 660
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _lista(),
                const Divider(height: 30),
                _editorDireccion()
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 240, child: _lista()),
                const SizedBox(width: 16),
                Container(
                    width: 1, height: 350, color: const Color(0xFFE5E1DD)),
                const SizedBox(width: 16),
                Expanded(child: _editorDireccion())
              ]));
  }

  @override
  Widget build(BuildContext context) {
    final nombreCliente =
        nombreClienteDePerfil(widget.perfil.nombres, widget.perfil.apellidos);
    final origen =
        widget.perfil.usuarioExterno == true ? 'Externo' : 'Aplicativo';
    return WillPopScope(
        onWillPop: _puedeCerrar,
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 850),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const SizedBox(width: 40),
                    const Expanded(
                        child: Text('Editar cliente',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600))),
                    IconButton(
                        onPressed: _cerrar, icon: const Icon(Icons.close))
                  ]),
                  Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text(nombreCliente,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('Origen: $origen',
                            style: const TextStyle(color: Colors.grey)),
                      ]),
                  const SizedBox(height: 4),
                  Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (telefono.text.trim().isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.phone_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text(telefono.text.trim())
                          ]),
                        if (correo.text.trim().isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.mail_outline, size: 16),
                            const SizedBox(width: 6),
                            Text(correo.text.trim())
                          ]),
                      ]),
                  const SizedBox(height: 18),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(spacing: 0, runSpacing: 4, children: [
                        _tab('Datos del cliente', 0),
                        _tab('Direcciones (${direcciones.length})', 1)
                      ])),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Flexible(
                      child: AbsorbPointer(
                          absorbing: guardando,
                          child: SingleChildScrollView(
                              child: tab == 0 ? _contacto() : _direcciones()))),
                  if (error != null && !(tab == 1 && ciudades.isEmpty))
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(error!,
                            style: const TextStyle(color: Colors.red))),
                  if (aviso != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child:
                            Text(aviso!, style: const TextStyle(color: verde))),
                  const Divider(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            hulpModalCloseButton(
                                text: 'Cancelar',
                                onPressed: guardando ? null : _cerrar),
                            if (tab == 1 && seleccion != null && !nuevo)
                              hulpModalCloseButton(
                                  text: seleccion!.activa
                                      ? 'Archivar dirección'
                                      : 'Desarchivar dirección',
                                  onPressed: guardando
                                      ? null
                                      : (seleccion!.activa
                                          ? _archivar
                                          : _desarchivar)),
                            if (tab == 0 || seleccion != null || nuevo)
                              hulpModalPrimaryButton(
                                  context: context,
                                  text: guardando
                                      ? 'Guardando...'
                                      : tab == 0
                                          ? 'Guardar cambios'
                                          : 'Guardar dirección',
                                  onPressed: guardando
                                      ? null
                                      : (tab == 0
                                          ? _guardarContacto
                                          : _guardarDireccion)),
                          ])),
                ])),
          ),
        ));
  }

  Widget _tab(String label, int index) => SizedBox(
      width: 180,
      child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: OutlinedButton(
              onPressed: () => _cambiarTab(index),
              style: OutlinedButton.styleFrom(
                  backgroundColor:
                      tab == index ? verde : const Color(0xFFFBFAF9),
                  foregroundColor: tab == index ? Colors.white : Colors.black87,
                  side: const BorderSide(color: Color(0xFFD5D0CA))),
              child: Text(label, textAlign: TextAlign.center))));
}
