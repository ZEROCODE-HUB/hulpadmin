import 'package:flutter/material.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Protege el contenido y la barrera del diálogo frente a mapas HTML debajo.
Future<T?> showMapSafeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _MapSafeDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierColor: DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
    ),
  );
}

class _MapSafeDialogRoute<T> extends DialogRoute<T> {
  _MapSafeDialogRoute({
    required super.context,
    required super.builder,
    required super.themes,
    required super.barrierColor,
  });

  @override
  // La barrera ocupa toda la ventana y se pinta debajo del contenido del
  // diálogo. Su capa HTML protege ambos sin bloquear el cierre al pulsar fuera.
  Widget buildModalBarrier() =>
      PointerInterceptor(child: super.buildModalBarrier());
}

/// Mantiene el anclaje del desplegable y protege también su barrera exterior.
Future<T?> showMapSafeAlignedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor = Colors.transparent,
  Alignment followerAnchor = Alignment.center,
  Alignment targetAnchor = Alignment.center,
  bool avoidOverflow = false,
  bool isGlobal = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final target = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final position = isGlobal
      ? overlay.localToGlobal(followerAnchor.alongSize(overlay.size))
      : target.localToGlobal(targetAnchor.alongSize(target.size),
          ancestor: overlay);

  return navigator.push<T>(
    _MapSafeAlignedDialogRoute<T>(
      context: context,
      builder: builder,
      position: position,
      followerAlignment: followerAnchor,
      barrierColor: barrierColor,
      useSafeArea: isGlobal,
      avoidOverflow: avoidOverflow,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

class _MapSafeAlignedDialogRoute<T> extends AlignedDialogRoute<T> {
  _MapSafeAlignedDialogRoute({
    required super.context,
    required super.builder,
    required super.position,
    required super.followerAlignment,
    required super.barrierColor,
    required super.useSafeArea,
    required super.avoidOverflow,
    required super.themes,
  });

  @override
  Widget buildModalBarrier() =>
      PointerInterceptor(child: super.buildModalBarrier());
}

Future<void> showCenteredDialog(BuildContext context, Widget child) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: AlignmentDirectional(0.0, 0.0)
            .resolve(Directionality.of(context)),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        ),
      );
    },
  );
}

void navigateWithFade(BuildContext context, String routeName) {
  context.pushNamed(
    routeName,
    extra: <String, dynamic>{
      '__transition_info__': TransitionInfo(
        hasTransition: true,
        transitionType: PageTransitionType.fade,
        duration: Duration(milliseconds: 0),
      ),
    },
  );
}
