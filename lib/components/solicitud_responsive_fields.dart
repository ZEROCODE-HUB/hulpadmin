import 'package:flutter/material.dart';

/// Stacks form fields when their actual container becomes too narrow.
class SolicitudResponsiveFields extends StatelessWidget {
  const SolicitudResponsiveFields({
    super.key,
    required this.children,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        if (size.maxWidth >= 700 * scale.clamp(1, double.infinity)) {
          return Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        }
        final fields = children.where((child) => child is! SizedBox).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              fields[i] is Flexible ? (fields[i] as Flexible).child : fields[i],
            ],
          ],
        );
      });
}
