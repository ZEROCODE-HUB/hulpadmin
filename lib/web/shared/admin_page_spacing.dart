import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/app_state.dart';
import '/web/menu/menu_widget.dart';

/// Shared outer spacing for the admin screens, based on the Solicitudes page.
class AdminPageSpacing {
  static const double compactBreakpoint = 700.0;
  static const double compactHorizontal = 12.0;
  static const double regularHorizontal = 24.0;

  static double workAreaWidth(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = MenuWidget.esMovil(context)
        ? 0.0
        : (FFAppState().MenuAbierto ? 280.0 : 112.0);
    return math.max(0.0, viewportWidth - sidebarWidth).toDouble();
  }

  static double contentHorizontal(BuildContext context) =>
      horizontalForWidth(workAreaWidth(context));

  static double horizontalForWidth(double width) => width < compactBreakpoint
      ? compactHorizontal
      : regularHorizontal;

  /// Solicitudes uses the mobile breakpoint for spacing inside its header.
  static double headerHorizontal(BuildContext context) =>
      MenuWidget.esMovil(context)
          ? compactHorizontal
          : regularHorizontal;
}
