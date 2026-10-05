import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/web/menu_seleccion/menu_seleccion_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'menu_widget.dart' show MenuWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MenuModel extends FlutterFlowModel<MenuWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel1;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel2;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel3;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel4;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel5;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel6;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel7;
  // Model for MenuSeleccion component.
  late MenuSeleccionModel menuSeleccionModel8;
  // Model for MenuSeleccion component (Ciudades).
  late MenuSeleccionModel menuSeleccionModel9;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered = false;

  @override
  void initState(BuildContext context) {
    menuSeleccionModel1 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel2 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel3 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel4 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel5 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel6 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel7 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel8 = createModel(context, () => MenuSeleccionModel());
    menuSeleccionModel9 = createModel(context, () => MenuSeleccionModel());
  }

  @override
  void dispose() {
    menuSeleccionModel1.dispose();
    menuSeleccionModel2.dispose();
    menuSeleccionModel3.dispose();
    menuSeleccionModel4.dispose();
    menuSeleccionModel5.dispose();
    menuSeleccionModel6.dispose();
    menuSeleccionModel7.dispose();
    menuSeleccionModel8.dispose();
    menuSeleccionModel9.dispose();
  }
}
