import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Acciones de pie para los modales de Hulp Admin.
Widget hulpModalActionRow({
  BuildContext? context,
  required List<Widget> actions,
}) {
  final primaryColor =
      context == null ? null : FlutterFlowTheme.of(context).primary;
  return SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: primaryColor == null
          ? actions
          : actions
              .map((action) =>
                  _normalizarAccionPrimaria(action, context!, primaryColor))
              .toList(),
    ),
  );
}

Widget _normalizarAccionPrimaria(
  Widget action,
  BuildContext context,
  Color primaryColor,
) {
  if (action is! FFButtonWidget || action.options.color != primaryColor) {
    return action;
  }

  return _HulpModalPrimaryButton(
    key: action.key,
    text: action.text,
    onPressed: action.onPressed,
    icon: action.icon ??
        (action.iconData == null
            ? null
            : Icon(action.iconData, size: action.options.iconSize)),
    showLoadingIndicator: action.showLoadingIndicator,
  );
}

class _HulpModalPrimaryButton extends StatefulWidget {
  const _HulpModalPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.showLoadingIndicator,
    this.icon,
  });

  final String text;
  final Function()? onPressed;
  final bool showLoadingIndicator;
  final Widget? icon;

  @override
  State<_HulpModalPrimaryButton> createState() =>
      _HulpModalPrimaryButtonState();
}

class _HulpModalPrimaryButtonState extends State<_HulpModalPrimaryButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    final action = widget.onPressed;
    if (action == null || _loading) return;

    if (!widget.showLoadingIndicator) {
      await action();
      return;
    }

    setState(() => _loading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => hulpModalPrimaryButton(
        context: context,
        onPressed: widget.onPressed == null ? null : _onPressed,
        child: _loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : widget.icon == null
                ? Text(widget.text)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.icon!,
                      const SizedBox(width: 8),
                      Text(widget.text),
                    ],
                  ),
      );
}

OutlinedButton hulpModalCloseButton({
  required String text,
  required VoidCallback? onPressed,
}) =>
    OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3C3C3C),
        side: const BorderSide(color: Color(0xFFB8B2A8)),
        minimumSize: const Size(110, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16),
      ),
      onPressed: onPressed,
      child: Text(text),
    );

OutlinedButton hulpModalSecondaryButton({
  required BuildContext context,
  required String text,
  required VoidCallback? onPressed,
}) =>
    OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: FlutterFlowTheme.of(context).primary,
        side: BorderSide(color: FlutterFlowTheme.of(context).primary),
        minimumSize: const Size(190, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(text),
    );

FilledButton hulpModalPrimaryButton({
  required BuildContext context,
  String? text,
  Widget? child,
  required VoidCallback? onPressed,
}) =>
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(190, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: child ?? Text(text ?? ''),
    );
