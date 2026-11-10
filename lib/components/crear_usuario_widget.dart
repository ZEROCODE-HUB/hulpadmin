import 'dart:convert';
import 'package:flutter/material.dart';
import '/components/hulp_input_decoration.dart';
import '/components/hulp_modal_actions.dart';
import '/backend/supabase/supabase.dart';
import '/backend/direcciones_cliente.dart';
import '/custom_code/actions/create_user.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/ubicacion_helpers.dart';
import 'modal_con_encabezado_fijo.dart';
import 'searchable_dropdown_widget.dart';
import 'selector_ubicacion_widget.dart';

/// Conserva las direcciones en memoria hasta confirmar el alta completa.
class CrearUsuarioWidget extends StatefulWidget {
  const CrearUsuarioWidget(
      {super.key,
      this.repository,
      this.crearIdentidad,
      this.guardarPerfil,
      this.guardarDirecciones,
      this.mapaBuilder});
  final DireccionesClienteRepository? repository;
  final Future<String?> Function(String correo, String clave)? crearIdentidad;
  final Future<void> Function(Map<String, dynamic>)? guardarPerfil;
  final Future<void> Function(List<Map<String, dynamic>>)? guardarDirecciones;
  final Widget Function(ValueChanged<Coordenadas?>)? mapaBuilder;
  @override
  State<CrearUsuarioWidget> createState() => _CrearUsuarioWidgetState();
}

class _CrearUsuarioWidgetState extends State<CrearUsuarioWidget> {
  static const verde = Color(0xFF086349);
  late final repo = widget.repository ?? DireccionesClienteRepository();
  final datosForm = GlobalKey<FormState>();
  final direccionForm = GlobalKey<FormState>();
  final nombres = TextEditingController(), apellidos = TextEditingController();
  final documento = TextEditingController(), telefono = TextEditingController();
  final correo = TextEditingController(),
      confirmarCorreo = TextEditingController();
  final clave = TextEditingController(),
      confirmarClave = TextEditingController();
  final nombre = TextEditingController(), direccion = TextEditingController();
  final complemento = TextEditingController(),
      referencia = TextEditingController();
  List<CiudadesRow> ciudades = [];
  final direcciones = <Map<String, dynamic>>[];
  String tipo = 'casa';
  String? ciudad, tipoDocumento, pais, error, usuarioId;
  Coordenadas? punto;
  int tab = 0, revisionMapa = 0;
  int? seleccion;
  bool guardando = false, cargando = true, perfilGuardado = false;
  bool ocultarClave = true, ocultarConfirmar = true;
  String firmaInicial = '';
  Map<String, dynamic>? perfilPendiente;

  @override
  void initState() {
    super.initState();
    firmaInicial = jsonEncode(_datosDireccion());
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      ciudades = await repo.ciudades(soloActivas: true);
    } catch (_) {
      error = 'No se pudieron cargar las ciudades. Intenta de nuevo.';
    }
    if (mounted) setState(() => cargando = false);
  }

  @override
  void dispose() {
    for (final c in [
      nombres,
      apellidos,
      documento,
      telefono,
      correo,
      confirmarCorreo,
      clave,
      confirmarClave,
      nombre,
      direccion,
      complemento,
      referencia
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _datosDireccion() => {
        'tipo': tipo,
        'nombre': tipo == 'otra' ? nombre.text.trim() : null,
        'direccion': direccion.text.trim(),
        'complemento': complemento.text.trim(),
        'referencia': referencia.text.trim(),
        'ciudad_id': ciudad,
        'latitud': punto?.latitud,
        'longitud': punto?.longitud,
      };
  bool get cambiosDireccion => jsonEncode(_datosDireccion()) != firmaInicial;
  bool _agregarLista() {
    if (!(direccionForm.currentState?.validate() ?? false)) return false;
    if (!ciudades.any((c) => c.id == ciudad && c.activo == true)) {
      setState(() => error = 'Selecciona una ciudad activa.');
      return false;
    }
    final data = _datosDireccion();
    setState(() {
      error = null;
      if (seleccion == null) {
        direcciones.add({...data, 'id': functions.generateUUIDv4()});
        seleccion = direcciones.length - 1;
      } else {
        direcciones[seleccion!] = {
          ...data,
          'id': direcciones[seleccion!]['id']
        };
      }
      firmaInicial = jsonEncode(data);
    });
    return true;
  }

  void _seleccionar(int? indice) {
    if (cambiosDireccion && !_agregarLista()) return;
    final d = indice == null ? <String, dynamic>{} : direcciones[indice];
    setState(() {
      seleccion = indice;
      tipo = d['tipo'] ?? 'casa';
      nombre.text = d['nombre'] ?? '';
      direccion.text = d['direccion'] ?? '';
      complemento.text = d['complemento'] ?? '';
      referencia.text = d['referencia'] ?? '';
      ciudad = d['ciudad_id'];
      punto = d['latitud'] == null
          ? null
          : Coordenadas(d['latitud'], d['longitud']);
      revisionMapa++;
      error = null;
      firmaInicial = jsonEncode(_datosDireccion());
    });
  }

  bool _validarDatos() {
    final valida = datosForm.currentState?.validate() ?? false;
    if (!valida) return false;
    if (tipoDocumento == null || pais == null) {
      setState(() => error = 'Selecciona el tipo de documento y el país.');
      return false;
    }
    if (correo.text.trim() != confirmarCorreo.text.trim()) {
      setState(() => error = 'Los correos no coinciden.');
      return false;
    }
    if (clave.text != confirmarClave.text) {
      setState(() => error = 'Las contraseñas no coinciden.');
      return false;
    }
    setState(() => error = null);
    return true;
  }

  Future<void> _registrar() async {
    if (guardando) return;
    if (usuarioId == null) {
      if (!_validarDatos()) {
        setState(() => tab = 0);
        return;
      }
      if (cambiosDireccion || direcciones.isEmpty) {
        if (tab != 1) {
          setState(() {
            tab = 1;
            error = 'Agrega al menos una dirección.';
          });
          return;
        }
        if (!_agregarLista()) return;
      }
      final primera = direcciones.first;
      perfilPendiente = {
        'codigo_pais': '+57',
        'nombres': nombres.text.trim(),
        'apellidos': apellidos.text.trim(),
        'tipo_documento': tipoDocumento,
        'numero_documento': documento.text.trim(),
        'pais': pais,
        'ciudad':
            ciudades.firstWhere((c) => c.id == primera['ciudad_id']).nombre,
        'direccion': [
          primera['direccion'],
          primera['complemento'],
          primera['referencia']
        ].where((v) => v != null && v.toString().isNotEmpty).join(', '),
        'telefono': telefono.text.trim(),
        'correo_electronico': correo.text.trim(),
        'rol': 'usuario',
        'fecha_registro': DateTime.now().toIso8601String(),
        'usuario_externo': true,
      };
    }
    setState(() {
      guardando = true;
      error = null;
    });
    try {
      // Se mantiene el alta REST que conserva la sesión del administrador.
      usuarioId ??= await (widget.crearIdentidad ?? actions.createUser)(
          correo.text.trim(),
          clave.text.isEmpty ? functions.generateUUIDv4() : clave.text);
      if (usuarioId == null || usuarioId!.isEmpty) {
        usuarioId = null;
        throw StateError('No se pudo crear el usuario');
      }
      if (!perfilGuardado) {
        final perfil = {...perfilPendiente!, 'id': usuarioId};
        if (widget.guardarPerfil != null) {
          await widget.guardarPerfil!(perfil);
        } else {
          await UsuariosTable().insert(perfil);
        }
        perfilGuardado = true;
      }
      final rows = direcciones
          .map((d) => {...d, 'usuario_id': usuarioId, 'activo': true})
          .toList();
      if (widget.guardarDirecciones != null) {
        await widget.guardarDirecciones!(rows);
      } else {
        // IDs estables: reintentar una respuesta perdida no duplica direcciones.
        await SupaFlow.client
            .from('direcciones_usuario')
            .upsert(rows, onConflict: 'id');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => error = usuarioId == null
            ? 'No se pudo crear el usuario. Verifica el correo e intenta de nuevo.'
            : 'El alta quedó incompleta. Pulsa Registrar cliente para reintentar sin crear otro usuario.');
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget _fila(Widget a, Widget b) => LayoutBuilder(
      builder: (context, c) => c.maxWidth < 520
          ? Column(children: [a, b])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b)
            ]));
  String? _requerido(String? v) =>
      v == null || v.trim().isEmpty ? 'Completa este campo.' : null;
  Widget _dato(String label, TextEditingController c,
          {bool email = false,
          bool password = false,
          bool confirmar = false,
          int? maxLength}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label),
            const SizedBox(height: 6),
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: ValueKey(label),
              controller: c,
              maxLength: maxLength,
              obscureText:
                  password && (confirmar ? ocultarConfirmar : ocultarClave),
              decoration: decorarInputHulp(
                context,
                _input(label.replaceAll(' *', '')).copyWith(
                  prefixIcon: email
                      ? const Icon(Icons.mail_outline, size: 20)
                      : password
                          ? const Icon(Icons.key, size: 20)
                          : null,
                  suffixIcon: password
                      ? IconButton(
                          icon: Icon(
                            (confirmar ? ocultarConfirmar : ocultarClave)
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => confirmar
                              ? ocultarConfirmar = !ocultarConfirmar
                              : ocultarClave = !ocultarClave),
                        )
                      : null,
                ),
                etiqueta: label.replaceAll(' *', ''),
              ),
              validator: password
                  ? null
                  : (v) {
                      final e = _requerido(v);
                      if (e != null) return e;
                      if (email &&
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!)) {
                        return 'Ingresa un correo válido.';
                      }
                      return null;
                    },
            )
          ]));
  Widget _opciones(String label, List<String> options, String? value,
          ValueChanged<String?> changed) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label),
            const SizedBox(height: 6),
            SearchableDropdown(
                values: options,
                labels: options,
                selectedValue: value,
                onChanged: changed,
                hint: 'Seleccionar...')
          ]));
  Widget _datos() => Form(
      key: datosForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Datos básicos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        _fila(_dato('Nombres *', nombres), _dato('Apellidos *', apellidos)),
        _fila(
            _opciones(
                'Tipo de documento *',
                [
                  'Cédula de ciudadania',
                  'Carnet de extranjería',
                  'Pasaporte',
                  'NIT',
                  'PPT'
                ],
                tipoDocumento,
                (v) => setState(() => tipoDocumento = v)),
            _dato('Número de documento *', documento)),
        _fila(
            _opciones('País *', ['+57'], pais, (v) => setState(() => pais = v)),
            _dato('Número de teléfono *', telefono, maxLength: 11)),
        const SizedBox(height: 10),
        const Text('Datos de usuario',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        _fila(
            _dato('Correo electrónico *', correo, email: true),
            _dato('Confirmar correo electrónico *', confirmarCorreo,
                email: true)),
        _fila(
            _dato('Contraseña', clave, password: true),
            _dato('Confirmar contraseña', confirmarClave,
                password: true, confirmar: true)),
      ]));
  Widget _lista() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Direcciones',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < direcciones.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: seleccion == i
                      ? const Color(0xFFE5F2E9)
                      : const Color(0xFFFBFAF9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: seleccion == i
                              ? verde
                              : const Color(0xFFD5D0CA))),
                  child: InkWell(
                      onTap: () => _seleccionar(i),
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
                                  Text(
                                      DireccionCliente(direcciones[i]).etiqueta,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${direcciones[i]['direccion']}, ${ciudades.where((c) => c.id == direcciones[i]['ciudad_id']).firstOrNull?.nombre ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)
                                ]))
                          ]))))),
        OutlinedButton.icon(
            onPressed: () => _seleccionar(null),
            icon: const Icon(Icons.add),
            label: const Text('Agregar dirección'),
            style: OutlinedButton.styleFrom(
                foregroundColor: verde,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)))),
      ]);
  Widget _direcciones() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (cargando)
          const Center(child: CircularProgressIndicator())
        else if (ciudades.isEmpty)
          TextButton(
              onPressed: _cargar,
              child: const Text('Reintentar carga de ciudades'))
        else
          LayoutBuilder(
              builder: (context, c) => c.maxWidth < 660
                  ? Column(children: [
                      _lista(),
                      const Divider(height: 30),
                      _editorDireccion()
                    ])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          SizedBox(width: 240, child: _lista()),
                          const SizedBox(width: 16),
                          Container(
                              width: 1,
                              height: 540,
                              color: const Color(0xFFE5E1DD)),
                          const SizedBox(width: 16),
                          Expanded(child: _editorDireccion())
                        ])),
        const SizedBox(height: 14),
        Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
                onPressed: cargando ? null : _agregarLista,
                style: OutlinedButton.styleFrom(
                    foregroundColor: verde,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7))),
                child: const Text('Agregar a la lista'))),
      ]);
  Widget _tab(String label, int index) => SizedBox(
      width: 195,
      child: OutlinedButton(
          onPressed: guardando
              ? null
              : () => setState(() {
                    tab = index;
                    error = null;
                  }),
          style: OutlinedButton.styleFrom(
              backgroundColor: tab == index ? verde : const Color(0xFFFBFAF9),
              foregroundColor: tab == index ? Colors.white : Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5))),
          child: Text(label)));
  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !guardando,
      child: Align(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(20),
                child: Material(
                    color: Colors.transparent,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EncabezadoModal(
                              habilitado: !guardando,
                              titulo: const Text('Registrar cliente',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500))),
                          if (tab == 1)
                            Text(
                                '${nombres.text.trim()} ${apellidos.text.trim()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 18),
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: [
                                _tab('Datos del cliente', 0),
                                const SizedBox(width: 6),
                                _tab('Direcciones (${direcciones.length})', 1)
                              ])),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                          Flexible(
                              child: SingleChildScrollView(
                                  child: AbsorbPointer(
                                      absorbing: guardando || usuarioId != null,
                                      child: Column(children: [
                                        // Mantener montado el formulario conserva controles y validación al cambiar de pestaña.
                                        Offstage(
                                            offstage: tab != 0,
                                            child: _datos()),
                                        Offstage(
                                            offstage: tab != 1,
                                            child: _direcciones()),
                                      ])))),
                          if (error != null)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(error!,
                                    style: const TextStyle(color: Colors.red))),
                          const Divider(height: 28),
                          LayoutBuilder(
                              builder: (context, c) => Wrap(
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 12,
                                      runSpacing: 10,
                                      children: [
                                        if (tab == 1)
                                          SizedBox(
                                              width: c.maxWidth > 800
                                                  ? c.maxWidth - 330
                                                  : c.maxWidth,
                                              child: const Text(
                                                  'El cliente y sus direcciones se guardarán al registrar.',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54))),
                                        hulpModalCloseButton(
                                            text: 'Cancelar',
                                            onPressed: guardando
                                                ? null
                                                : () => Navigator.pop(context)),
                                        hulpModalPrimaryButton(
                                            context: context,
                                            onPressed: guardando
                                                ? null
                                                : tab == 0
                                                    ? () {
                                                        if (_validarDatos()) {
                                                          setState(
                                                              () => tab = 1);
                                                        }
                                                      }
                                                    : _registrar,
                                            child: guardando
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white))
                                                : Text(tab == 0
                                                    ? 'Continuar a direcciones'
                                                    : 'Registrar cliente')),
                                      ])),
                        ])),
              ))));
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
          borderSide: const BorderSide(color: Color(0xFFD5D0CA))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: verde)));
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
  Widget _editorDireccion() {
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
          // La vista HTML de Google Maps necesita dimensiones visibles al montarse.
          // Los campos siguen montados para conservar datos y validación.
          if (tab == 1)
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
}
