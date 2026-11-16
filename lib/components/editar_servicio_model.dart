import '/backend/supabase/supabase.dart';
import '/components/hulp_numeric_input.dart';
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
import 'editar_servicio_widget.dart' show EditarServicioWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EditarServicioModel extends FlutterFlowModel<EditarServicioWidget> {
  ///  Local state fields for this component.

  List<String> items = [];
  void addToItems(String item) => items.add(item);
  void removeFromItems(String item) => items.remove(item);
  void removeAtIndexFromItems(int index) => items.removeAt(index);
  void insertAtIndexInItems(int index, String item) =>
      items.insert(index, item);
  void updateItemsAtIndex(int index, Function(String) updateFn) =>
      items[index] = updateFn(items[index]);

  String? foto1;

  String? foto2;

  String? foto3;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // Stores action output result for [Backend Call - Query Rows] action in EditarServicio widget.
  List<ServiciosRow>? servid;
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

  bool isDataUploading_subirfotoeditserivce1 = false;
  FFUploadedFile uploadedLocalFile_subirfotoeditserivce1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfotoeditserivce1 = '';

  bool isDataUploading_subirfotoeditserivce2 = false;
  FFUploadedFile uploadedLocalFile_subirfotoeditserivce2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfotoeditserivce2 = '';

  bool isDataUploading_subirfotoeditserivce3 = false;
  FFUploadedFile uploadedLocalFile_subirfotoeditserivce3 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_subirfotoeditserivce3 = '';

  // State field(s) for preciobase widget.
  FocusNode? preciobaseFocusNode;
  TextEditingController? preciobaseTextController;
  String? Function(BuildContext, String?)? preciobaseTextControllerValidator;
  String? _preciobaseTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el precio base';
    }

    return HulpNumericInput.validateDecimal(val, fieldName: 'el precio base');
  }

  // State field(s) for descripcion widget.
  FocusNode? descripcionFocusNode;
  TextEditingController? descripcionTextController;
  String? Function(BuildContext, String?)? descripcionTextControllerValidator;
  String? _descripcionTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la descripción';
    }

    return null;
  }

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
    descripcionTextControllerValidator = _descripcionTextControllerValidator;
    informacionrelevanteTextControllerValidator =
        _informacionrelevanteTextControllerValidator;
  }

  @override
  void dispose() {
    nombreservicioFocusNode?.dispose();
    nombreservicioTextController?.dispose();

    preciobaseFocusNode?.dispose();
    preciobaseTextController?.dispose();

    descripcionFocusNode?.dispose();
    descripcionTextController?.dispose();

    itemsFocusNode?.dispose();
    itemsTextController?.dispose();

    informacionrelevanteFocusNode?.dispose();
    informacionrelevanteTextController?.dispose();
  }
}
