import '/backend/supabase/supabase.dart';
import '/components/chat_usuario_proveedor_widget.dart';
import '/components/dropdown_solicitud_estado_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'detalle_solicitud_widget.dart' show DetalleSolicitudWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DetalleSolicitudModel extends FlutterFlowModel<DetalleSolicitudWidget> {
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
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode6;
  TextEditingController? nombreTextController6;
  String? Function(BuildContext, String?)? nombreTextController6Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode7;
  TextEditingController? nombreTextController7;
  String? Function(BuildContext, String?)? nombreTextController7Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode8;
  TextEditingController? nombreTextController8;
  String? Function(BuildContext, String?)? nombreTextController8Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode9;
  TextEditingController? nombreTextController9;
  String? Function(BuildContext, String?)? nombreTextController9Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode10;
  TextEditingController? nombreTextController10;
  String? Function(BuildContext, String?)? nombreTextController10Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode11;
  TextEditingController? nombreTextController11;
  String? Function(BuildContext, String?)? nombreTextController11Validator;
  String? _nombreTextController11Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa el nombre';
    }

    return null;
  }

  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode12;
  TextEditingController? nombreTextController12;
  String? Function(BuildContext, String?)? nombreTextController12Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode13;
  TextEditingController? nombreTextController13;
  String? Function(BuildContext, String?)? nombreTextController13Validator;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode14;
  TextEditingController? nombreTextController14;
  String? Function(BuildContext, String?)? nombreTextController14Validator;
  // Model for chatUsuarioProveedor component.
  late ChatUsuarioProveedorModel chatUsuarioProveedorModel;

  @override
  void initState(BuildContext context) {
    nombreTextController11Validator = _nombreTextController11Validator;
    chatUsuarioProveedorModel =
        createModel(context, () => ChatUsuarioProveedorModel());
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

    nombreFocusNode13?.dispose();
    nombreTextController13?.dispose();

    nombreFocusNode14?.dispose();
    nombreTextController14?.dispose();

    chatUsuarioProveedorModel.dispose();
  }
}
