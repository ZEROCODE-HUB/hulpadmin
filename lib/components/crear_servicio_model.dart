import '/flutter_flow/validacion_precio_servicio.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/components/notificacion2_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'crear_servicio_widget.dart' show CrearServicioWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CrearServicioModel extends FlutterFlowModel<CrearServicioWidget> {
  ///  Local state fields for this component.

  List<String> items = [];
  void addToItems(String item) => items.add(item);
  void removeFromItems(String item) => items.remove(item);
  void removeAtIndexFromItems(int index) => items.removeAt(index);
  void insertAtIndexInItems(int index, String item) =>
      items.insert(index, item);
  void updateItemsAtIndex(int index, Function(String) updateFn) =>
      items[index] = updateFn(items[index]);

  List<ItemsReciboStruct> preciosAdicionales = [];
  void addToPreciosAdicionales(ItemsReciboStruct item) =>
      preciosAdicionales.add(item);
  void removeFromPreciosAdicionales(ItemsReciboStruct item) =>
      preciosAdicionales.remove(item);
  void removeAtIndexFromPreciosAdicionales(int index) =>
      preciosAdicionales.removeAt(index);
  void insertAtIndexInPreciosAdicionales(int index, ItemsReciboStruct item) =>
      preciosAdicionales.insert(index, item);

  String? foto1;

  String? foto2;

  String? foto3;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for nombreservicio widget.
  FocusNode? nombreservicioFocusNode;
  TextEditingController? nombreservicioTextController;
  String? Function(BuildContext, String?)?
      nombreservicioTextControllerValidator;
  String? _nombreservicioTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el nombre del servicio';
    }

    return null;
  }

  bool isDataUploading_subirfoto1 = false;
  FFUploadedFile uploadedLocalFile_subirfoto1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfoto1 = '';

  bool isDataUploading_subirfoto2 = false;
  FFUploadedFile uploadedLocalFile_subirfoto2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfoto2 = '';

  bool isDataUploading_subirfoto3 = false;
  FFUploadedFile uploadedLocalFile_subirfoto3 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfoto3 = '';

  // State field(s) for preciobase widget.
  FocusNode? preciobaseFocusNode;
  TextEditingController? preciobaseTextController;
  String? Function(BuildContext, String?)? preciobaseTextControllerValidator;
  String? _preciobaseTextControllerValidator(
      BuildContext context, String? val) => validarPrecioNuevoServicio(val);

  // State field(s) for descripcion widget.
  FocusNode? descripcionFocusNode1;
  TextEditingController? descripcionTextController1;
  String? Function(BuildContext, String?)? descripcionTextController1Validator;
  String? _descripcionTextController1Validator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la descripción';
    }

    return null;
  }

  // State field(s) for descripcion widget.
  FocusNode? descripcionFocusNode2;
  TextEditingController? descripcionTextController2;
  String? Function(BuildContext, String?)? descripcionTextController2Validator;
  // State field(s) for items widget.
  FocusNode? itemsFocusNode;
  TextEditingController? itemsTextController;
  String? Function(BuildContext, String?)? itemsTextControllerValidator;
  // State field(s) for estado widget.
  String? estadoValue;
  FormFieldController<String>? estadoValueController;
  // State field(s) for informacionrelevante widget.
  FocusNode? informacionrelevanteFocusNode;
  TextEditingController? informacionrelevanteTextController;
  String? Function(BuildContext, String?)?
      informacionrelevanteTextControllerValidator;
  String? _informacionrelevanteTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la información relevante';
    }

    return null;
  }

  // State field(s) for SwitchDestacado widget.
  bool? switchDestacadoValue;

  @override
  void initState(BuildContext context) {
    nombreservicioTextControllerValidator =
        _nombreservicioTextControllerValidator;
    preciobaseTextControllerValidator = _preciobaseTextControllerValidator;
    descripcionTextController1Validator = _descripcionTextController1Validator;
    informacionrelevanteTextControllerValidator =
        _informacionrelevanteTextControllerValidator;
  }

  @override
  void dispose() {
    nombreservicioFocusNode?.dispose();
    nombreservicioTextController?.dispose();

    preciobaseFocusNode?.dispose();
    preciobaseTextController?.dispose();

    descripcionFocusNode1?.dispose();
    descripcionTextController1?.dispose();

    descripcionFocusNode2?.dispose();
    descripcionTextController2?.dispose();

    itemsFocusNode?.dispose();
    itemsTextController?.dispose();

    informacionrelevanteFocusNode?.dispose();
    informacionrelevanteTextController?.dispose();
  }
}
