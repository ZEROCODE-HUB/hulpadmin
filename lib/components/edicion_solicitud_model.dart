import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/components/dropdown_solicitud_estado_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'dart:ui';
import 'edicion_solicitud_widget.dart' show EdicionSolicitudWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EdicionSolicitudModel extends FlutterFlowModel<EdicionSolicitudWidget> {
  ///  Local state fields for this component.

  bool showChat = false;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for nroSolicitud widget.
  FocusNode? nroSolicitudFocusNode;
  TextEditingController? nroSolicitudTextController;
  String? Function(BuildContext, String?)? nroSolicitudTextControllerValidator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode1;
  TextEditingController? nombreTextController1;
  String? Function(BuildContext, String?)? nombreTextController1Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode2;
  TextEditingController? nombreTextController2;
  String? Function(BuildContext, String?)? nombreTextController2Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode3;
  TextEditingController? nombreTextController3;
  String? Function(BuildContext, String?)? nombreTextController3Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode4;
  TextEditingController? nombreTextController4;
  String? Function(BuildContext, String?)? nombreTextController4Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode5;
  TextEditingController? nombreTextController5;
  String? Function(BuildContext, String?)? nombreTextController5Validator;
  DateTime? datePicked1;
  DateTime? datePicked2;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode6;
  TextEditingController? nombreTextController6;
  String? Function(BuildContext, String?)? nombreTextController6Validator;
  // Punto exacto de la solicitud. El selector lo siembra con lo que ya estaba
  // guardado, asi que guardar sin tocarlo NO lo borra.
  Coordenadas? coordenadas;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode7;
  TextEditingController? nombreTextController7;
  String? Function(BuildContext, String?)? nombreTextController7Validator;
  List<ItemsReciboStruct> preciosAdicionalesSolicitud = [];
  void addToPreciosAdicionalesSolicitud(ItemsReciboStruct item) =>
      preciosAdicionalesSolicitud.add(item);
  void removeAtIndexFromPreciosAdicionalesSolicitud(int index) =>
      preciosAdicionalesSolicitud.removeAt(index);

  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode8;
  TextEditingController? nombreTextController8;
  String? Function(BuildContext, String?)? nombreTextController8Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode9;
  TextEditingController? nombreTextController9;
  String? Function(BuildContext, String?)? nombreTextController9Validator;
  String? _nombreTextController9Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el nombre';
    }

    return null;
  }

  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode10;
  TextEditingController? nombreTextController10;
  String? Function(BuildContext, String?)? nombreTextController10Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode11;
  TextEditingController? nombreTextController11;
  String? Function(BuildContext, String?)? nombreTextController11Validator;
  // State field(s) for profesionalNuevo widget.
  // Servicio elegido en el selector (antes el campo era de solo lectura).
  String? servicioNuevoValue;
  String? servicioNuevoNombre;
  String? profesionalNuevoValue;
  FormFieldController<String>? profesionalNuevoValueController;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode12;
  TextEditingController? nombreTextController12;
  String? Function(BuildContext, String?)? nombreTextController12Validator;
  // Stores action output result for [Backend Call - API (sendNotificationUser)] action in Button widget.
  ApiCallResponse? apiResult0mz;

  @override
  void initState(BuildContext context) {
    nombreTextController9Validator = _nombreTextController9Validator;
  }

  @override
  void dispose() {
    nroSolicitudFocusNode?.dispose();
    nroSolicitudTextController?.dispose();

    nombreFocusNode1?.dispose();
    nombreTextController1?.dispose();

    nombreFocusNode2?.dispose();
    nombreTextController2?.dispose();

    nombreFocusNode3?.dispose();
    nombreTextController3?.dispose();

    nombreFocusNode4?.dispose();
    nombreTextController4?.dispose();

    nombreFocusNode5?.dispose();
    nombreTextController5?.dispose();

    nombreFocusNode6?.dispose();
    nombreTextController6?.dispose();

    nombreFocusNode7?.dispose();
    nombreTextController7?.dispose();

    nombreFocusNode8?.dispose();
    nombreTextController8?.dispose();

    nombreFocusNode9?.dispose();
    nombreTextController9?.dispose();

    nombreFocusNode10?.dispose();
    nombreTextController10?.dispose();

    nombreFocusNode11?.dispose();
    nombreTextController11?.dispose();

    nombreFocusNode12?.dispose();
    nombreTextController12?.dispose();
  }
}
