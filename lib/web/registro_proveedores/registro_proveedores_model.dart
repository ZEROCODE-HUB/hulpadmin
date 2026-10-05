import '/backend/supabase/supabase.dart';
import '/components/aceptar_proveedor_widget.dart';
import '/components/crear_proveedor_widget.dart';
import '/components/dropdown_proveedor_estado_widget.dart';
import '/components/informacion_proveedor_widget.dart';
import '/components/rechazar_proveedor_widget.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web/menu/menu_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'registro_proveedores_widget.dart' show RegistroProveedoresWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegistroProveedoresModel
    extends FlutterFlowModel<RegistroProveedoresWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu component.
  late MenuModel menuModel;
  // Listado completo de pendientes (sin la caja de busqueda). Se pagina en
  // profesionales_query.dart para no toparse con el limite de 1000 filas.
  Future<List<VwProfesionalesCompletoRow>>? listaCompletaRequest;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  Completer<List<VwProfesionalesCompletoRow>>? requestCompleter;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for PaginatedDataTable widget.
  final paginatedDataTableController =
      FlutterFlowDataTableController<VwProfesionalesCompletoRow>();
  // Models for dropdownProveedorEstado dynamic component.
  late FlutterFlowDynamicModels<DropdownProveedorEstadoModel>
      dropdownProveedorEstadoModels;

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
    dropdownProveedorEstadoModels =
        FlutterFlowDynamicModels(() => DropdownProveedorEstadoModel());
  }

  @override
  void dispose() {
    menuModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    paginatedDataTableController.dispose();
    dropdownProveedorEstadoModels.dispose();
  }

  /// Additional helper methods.

  /// Invalida las dos consultas de la pantalla para que se vuelvan a pedir.
  void invalidarConsultas() {
    listaCompletaRequest = null;
    requestCompleter = null;
  }

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
