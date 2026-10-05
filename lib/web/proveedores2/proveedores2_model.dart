import '/backend/supabase/supabase.dart';
import '/components/editar_proveedor_widget.dart';
import '/components/historial_servicios_widget.dart';
import '/components/informacion_proveedor_widget.dart';
import '/components/notificacion2_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web/menu/menu_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'dart:async';
import 'proveedores2_widget.dart' show Proveedores2Widget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Proveedores2Model extends FlutterFlowModel<Proveedores2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu component.
  late MenuModel menuModel;
  // State field(s) for TextFieldbuscar widget.
  FocusNode? textFieldbuscarFocusNode;
  TextEditingController? textFieldbuscarTextController;
  String? Function(BuildContext, String?)?
      textFieldbuscarTextControllerValidator;
  Completer<List<VwProfesionalesCompletoRow>>? requestCompleter;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Listado de la categoria (sin la caja de busqueda). Se pagina en
  // profesionales_query.dart para no toparse con el limite de 1000 filas.
  Future<List<VwProfesionalesCompletoRow>>? listaCompletaRequest;

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    menuModel.dispose();
    textFieldbuscarFocusNode?.dispose();
    textFieldbuscarTextController?.dispose();
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
