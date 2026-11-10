import '/backend/supabase/supabase.dart';
import '/components/crear_solicitud_widget.dart';
import '/components/detalle_solicitud_widget.dart';
import '/components/dropdown_solicitud_estado_widget.dart';
import '/components/edicion_solicitud_widget.dart';
import '/components/notificacion2_widget.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web/menu/menu_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'solicitudes_widget.dart' show SolicitudesWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SolicitudesModel extends FlutterFlowModel<SolicitudesWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu component.
  late MenuModel menuModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  Completer<List<VwSolicitudesServiciosCompletaRow>>? requestCompleter;
  Stream<List<VwSolicitudesServiciosCompletaRow>>? containerSupabaseStream;
  // State field(s) for DropDownOrden widget.
  String? dropDownOrdenValue;
  FormFieldController<String>? dropDownOrdenValueController;
  // State fields for filter dropdowns (estado / servicio / ciudad).
  String? dropDownValue1;
  String? dropDownValue2;
  String? dropDownValue3;
  DateTime? datePicked;
  DateTime? dateStart;
  DateTime? dateEnd;
  // State field(s) for PaginatedDataTable widget.
  final paginatedDataTableController =
      FlutterFlowDataTableController<VwSolicitudesServiciosCompletaRow>();

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    menuModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    paginatedDataTableController.dispose();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
