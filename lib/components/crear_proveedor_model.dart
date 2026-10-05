import '/backend/supabase/supabase.dart';
import '/components/notificacion2_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'crear_proveedor_widget.dart' show CrearProveedorWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CrearProveedorModel extends FlutterFlowModel<CrearProveedorWidget> {
  /// Ciudades activas, leidas de la tabla `ciudades`.
  ///
  /// Antes era una lista escrita a mano con cuatro ciudades (sin Bogota ni
  /// Medellin, que son las que mas mueven) y distinta de las otras dos listas
  /// que habia por el codigo.
  List<String> ciudades = [];

  Future<void> cargarCiudades() async {
    try {
      final filas = await CiudadesTable().queryRows(
        queryFn: (q) =>
            q.eqOrNull('activo', true).order('nombre', ascending: true),
      );
      ciudades = filas.map((c) => c.nombre).toList();
    } catch (e) {
      print('No se pudieron cargar las ciudades: $e');
    }
  }

  ///  Local state fields for this component.

  List<String> serviciosid = [];
  void addToServiciosid(String item) => serviciosid.add(item);
  void removeFromServiciosid(String item) => serviciosid.remove(item);
  void removeAtIndexFromServiciosid(int index) => serviciosid.removeAt(index);
  void insertAtIndexInServiciosid(int index, String item) =>
      serviciosid.insert(index, item);
  void updateServiciosidAtIndex(int index, Function(String) updateFn) =>
      serviciosid[index] = updateFn(serviciosid[index]);

  String? foto1;

  String? foto2;

  String? foto3;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode;
  TextEditingController? nombreTextController;
  String? Function(BuildContext, String?)? nombreTextControllerValidator;
  String? _nombreTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el nombre';
    }

    return null;
  }

  // State field(s) for apellido widget.
  FocusNode? apellidoFocusNode;
  TextEditingController? apellidoTextController;
  String? Function(BuildContext, String?)? apellidoTextControllerValidator;
  String? _apellidoTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el los apellidos';
    }

    return null;
  }

  // State field(s) for ciudad widget.
  String? ciudadValue;
  FormFieldController<String>? ciudadValueController;
  // State field(s) for direccion widget.
  FocusNode? direccionFocusNode;
  TextEditingController? direccionTextController;
  String? Function(BuildContext, String?)? direccionTextControllerValidator;
  String? _direccionTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la dirección';
    }

    return null;
  }

  // State field(s) for tipodocumento widget.
  String? tipodocumentoValue;
  FormFieldController<String>? tipodocumentoValueController;
  // State field(s) for numerodocumento widget.
  FocusNode? numerodocumentoFocusNode;
  TextEditingController? numerodocumentoTextController;
  String? Function(BuildContext, String?)?
      numerodocumentoTextControllerValidator;
  String? _numerodocumentoTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el teléfono';
    }

    return null;
  }

  // State field(s) for pais widget.
  String? paisValue;
  FormFieldController<String>? paisValueController;
  // State field(s) for telefono widget.
  FocusNode? telefonoFocusNode;
  TextEditingController? telefonoTextController;
  String? Function(BuildContext, String?)? telefonoTextControllerValidator;
  String? _telefonoTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Digite su telefono ed rquerido';
    }

    return null;
  }

  // State field(s) for entidad widget.
  String? entidadValue;
  FormFieldController<String>? entidadValueController;
  // State field(s) for tipocuenta widget.
  String? tipocuentaValue;
  FormFieldController<String>? tipocuentaValueController;
  // State field(s) for numerocuenta widget.
  FocusNode? numerocuentaFocusNode;
  TextEditingController? numerocuentaTextController;
  String? Function(BuildContext, String?)? numerocuentaTextControllerValidator;
  String? _numerocuentaTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el número de cuenta';
    }

    return null;
  }

  // State field(s) for rutnit widget.
  FocusNode? rutnitFocusNode;
  TextEditingController? rutnitTextController;
  String? Function(BuildContext, String?)? rutnitTextControllerValidator;
  String? _rutnitTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el RUT / NIT';
    }

    return null;
  }

  // State field(s) for correo1 widget.
  FocusNode? correo1FocusNode;
  TextEditingController? correo1TextController;
  String? Function(BuildContext, String?)? correo1TextControllerValidator;
  String? _correo1TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el correo';
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  // State field(s) for correo2 widget.
  FocusNode? correo2FocusNode;
  TextEditingController? correo2TextController;
  String? Function(BuildContext, String?)? correo2TextControllerValidator;
  String? _correo2TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Confirme el corre';
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  // State field(s) for password1 widget.
  FocusNode? password1FocusNode;
  TextEditingController? password1TextController;
  late bool password1Visibility;
  String? Function(BuildContext, String?)? password1TextControllerValidator;
  String? _password1TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la contraseña ';
    }

    if (val.length < 6) {
      return 'Se requieren mínimo 6 caracteres';
    }

    return null;
  }

  // State field(s) for password2 widget.
  FocusNode? password2FocusNode;
  TextEditingController? password2TextController;
  late bool password2Visibility;
  String? Function(BuildContext, String?)? password2TextControllerValidator;
  String? _password2TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Confirme la contraseña ';
    }

    if (val.length < 6) {
      return 'Se requieren mínimo 6 caracteres';
    }

    return null;
  }

  // Stores action output result for [Custom Action - createUser] action in Button widget.
  String? creado;

  @override
  void initState(BuildContext context) {
    nombreTextControllerValidator = _nombreTextControllerValidator;
    apellidoTextControllerValidator = _apellidoTextControllerValidator;
    direccionTextControllerValidator = _direccionTextControllerValidator;
    numerodocumentoTextControllerValidator =
        _numerodocumentoTextControllerValidator;
    telefonoTextControllerValidator = _telefonoTextControllerValidator;
    numerocuentaTextControllerValidator = _numerocuentaTextControllerValidator;
    rutnitTextControllerValidator = _rutnitTextControllerValidator;
    correo1TextControllerValidator = _correo1TextControllerValidator;
    correo2TextControllerValidator = _correo2TextControllerValidator;
    password1Visibility = false;
    password1TextControllerValidator = _password1TextControllerValidator;
    password2Visibility = false;
    password2TextControllerValidator = _password2TextControllerValidator;
  }

  @override
  void dispose() {
    nombreFocusNode?.dispose();
    nombreTextController?.dispose();

    apellidoFocusNode?.dispose();
    apellidoTextController?.dispose();

    direccionFocusNode?.dispose();
    direccionTextController?.dispose();

    numerodocumentoFocusNode?.dispose();
    numerodocumentoTextController?.dispose();

    telefonoFocusNode?.dispose();
    telefonoTextController?.dispose();

    numerocuentaFocusNode?.dispose();
    numerocuentaTextController?.dispose();

    rutnitFocusNode?.dispose();
    rutnitTextController?.dispose();

    correo1FocusNode?.dispose();
    correo1TextController?.dispose();

    correo2FocusNode?.dispose();
    correo2TextController?.dispose();

    password1FocusNode?.dispose();
    password1TextController?.dispose();

    password2FocusNode?.dispose();
    password2TextController?.dispose();
  }
}
