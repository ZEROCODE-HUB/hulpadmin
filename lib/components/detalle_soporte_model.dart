import '/backend/supabase/supabase.dart';
import '/components/hulp_numeric_input.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'detalle_soporte_widget.dart' show DetalleSoporteWidget;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DetalleSoporteModel extends FlutterFlowModel<DetalleSoporteWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for DropDownAsunto widget.
  String? dropDownAsuntoValue;
  FormFieldController<String>? dropDownAsuntoValueController;
  // State field(s) for servicio widget.
  FocusNode? servicioFocusNode;
  TextEditingController? servicioTextController;
  String? Function(BuildContext, String?)? servicioTextControllerValidator;
  String? _servicioTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El servicio es obligatorio';
    }

    return null;
  }

  // State field(s) for subcategoriaInput widget.
  FocusNode? subcategoriaInputFocusNode;
  TextEditingController? subcategoriaInputTextController;
  String? Function(BuildContext, String?)?
      subcategoriaInputTextControllerValidator;
  String? _subcategoriaInputTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Subcategoria es obligatoria';
    }

    return null;
  }

  DateTime? datePicked;
  // State field(s) for direccion widget.
  FocusNode? direccionFocusNode;
  TextEditingController? direccionTextController;
  String? Function(BuildContext, String?)? direccionTextControllerValidator;
  String? _direccionTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Direccion es obligatorio';
    }

    return null;
  }

  // State field(s) for precio widget.
  FocusNode? precioFocusNode;
  TextEditingController? precioTextController;
  String? Function(BuildContext, String?)? precioTextControllerValidator;
  String? _precioTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Precio es obligatorio';
    }
    return HulpNumericInput.validateDecimal(val, fieldName: 'el precio');
  }

  // State field(s) for proveedor_id widget.
  FocusNode? proveedorIdFocusNode;
  TextEditingController? proveedorIdTextController;
  String? Function(BuildContext, String?)? proveedorIdTextControllerValidator;
  String? _proveedorIdTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Proveedor id es obligatorio';
    }

    return null;
  }

  // State field(s) for nombre_usuario widget.
  FocusNode? nombreUsuarioFocusNode;
  TextEditingController? nombreUsuarioTextController;
  String? Function(BuildContext, String?)? nombreUsuarioTextControllerValidator;
  String? _nombreUsuarioTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Nombre de usuario es obligatorio';
    }

    return null;
  }

  // State field(s) for telefono_usuario widget.
  FocusNode? telefonoUsuarioFocusNode;
  TextEditingController? telefonoUsuarioTextController;
  String? Function(BuildContext, String?)?
      telefonoUsuarioTextControllerValidator;
  String? _telefonoUsuarioTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Telefono del usuario es obligatorio';
    }
    return HulpNumericInput.validateInteger(val, fieldName: 'el teléfono');
  }

  // State field(s) for email_usuario widget.
  FocusNode? emailUsuarioFocusNode;
  TextEditingController? emailUsuarioTextController;
  String? Function(BuildContext, String?)? emailUsuarioTextControllerValidator;
  String? _emailUsuarioTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Email del usuario es obligatorio';
    }

    return null;
  }

  // State field(s) for nombre_proveedor widget.
  FocusNode? nombreProveedorFocusNode;
  TextEditingController? nombreProveedorTextController;
  String? Function(BuildContext, String?)?
      nombreProveedorTextControllerValidator;
  String? _nombreProveedorTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Nombre del proveedor es oblgatorio';
    }

    return null;
  }

  // State field(s) for telefono_proveedor widget.
  FocusNode? telefonoProveedorFocusNode;
  TextEditingController? telefonoProveedorTextController;
  String? Function(BuildContext, String?)?
      telefonoProveedorTextControllerValidator;
  String? _telefonoProveedorTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Telefono proveedor es obligatorio';
    }
    return HulpNumericInput.validateInteger(val, fieldName: 'el teléfono');
  }

  // State field(s) for email_proveedor widget.
  FocusNode? emailProveedorFocusNode;
  TextEditingController? emailProveedorTextController;
  String? Function(BuildContext, String?)?
      emailProveedorTextControllerValidator;
  String? _emailProveedorTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Email del proveedor es obligatorio';
    }

    return null;
  }

  // State field(s) for notas widget.
  FocusNode? notasFocusNode;
  TextEditingController? notasTextController;
  String? Function(BuildContext, String?)? notasTextControllerValidator;
  String? _notasTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Notas es obligatorio';
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    servicioTextControllerValidator = _servicioTextControllerValidator;
    subcategoriaInputTextControllerValidator =
        _subcategoriaInputTextControllerValidator;
    direccionTextControllerValidator = _direccionTextControllerValidator;
    precioTextControllerValidator = _precioTextControllerValidator;
    proveedorIdTextControllerValidator = _proveedorIdTextControllerValidator;
    nombreUsuarioTextControllerValidator =
        _nombreUsuarioTextControllerValidator;
    telefonoUsuarioTextControllerValidator =
        _telefonoUsuarioTextControllerValidator;
    emailUsuarioTextControllerValidator = _emailUsuarioTextControllerValidator;
    nombreProveedorTextControllerValidator =
        _nombreProveedorTextControllerValidator;
    telefonoProveedorTextControllerValidator =
        _telefonoProveedorTextControllerValidator;
    emailProveedorTextControllerValidator =
        _emailProveedorTextControllerValidator;
    notasTextControllerValidator = _notasTextControllerValidator;
  }

  @override
  void dispose() {
    servicioFocusNode?.dispose();
    servicioTextController?.dispose();

    subcategoriaInputFocusNode?.dispose();
    subcategoriaInputTextController?.dispose();

    direccionFocusNode?.dispose();
    direccionTextController?.dispose();

    precioFocusNode?.dispose();
    precioTextController?.dispose();

    proveedorIdFocusNode?.dispose();
    proveedorIdTextController?.dispose();

    nombreUsuarioFocusNode?.dispose();
    nombreUsuarioTextController?.dispose();

    telefonoUsuarioFocusNode?.dispose();
    telefonoUsuarioTextController?.dispose();

    emailUsuarioFocusNode?.dispose();
    emailUsuarioTextController?.dispose();

    nombreProveedorFocusNode?.dispose();
    nombreProveedorTextController?.dispose();

    telefonoProveedorFocusNode?.dispose();
    telefonoProveedorTextController?.dispose();

    emailProveedorFocusNode?.dispose();
    emailProveedorTextController?.dispose();

    notasFocusNode?.dispose();
    notasTextController?.dispose();
  }
}
