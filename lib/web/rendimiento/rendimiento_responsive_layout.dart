import 'dart:math' as math;

import 'package:flutter/material.dart';

double rendimientoChartHeight(BuildContext context) {
  final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16);
  return 400 + (scale - 1) * 180;
}

class RendimientoGrid extends StatelessWidget {
  const RendimientoGrid(
      {super.key,
      required this.children,
      this.minWidth = 420,
      this.charts = true,
      this.mainAxisSize = MainAxisSize.max});

  final List<Widget> children;
  final double minWidth;
  final bool charts;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final items = children.where((child) => child is! SizedBox).toList();
        final scale =
            math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16);
        final columns = math.max(
            1,
            math.min(items.length,
                ((size.maxWidth + 16) / (minWidth * scale + 16)).floor()));
        final width = (size.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final item in items)
            SizedBox(
                width: width,
                child: charts
                    ? RendimientoChartViewport(
                        child: item is Flexible ? item.child : item)
                    : (item is Flexible ? item.child : item)),
        ]);
      });
}

class RendimientoChartViewport extends StatefulWidget {
  const RendimientoChartViewport({super.key, required this.child});

  final Widget child;

  @override
  State<RendimientoChartViewport> createState() =>
      _RendimientoChartViewportState();
}

class _RendimientoChartViewportState extends State<RendimientoChartViewport> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final scale =
            math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16);
        final width = math.max(size.maxWidth, 400 * scale);
        return Scrollbar(
            controller: _controller,
            thumbVisibility: width > size.maxWidth,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.only(bottom: width > size.maxWidth ? 12 : 0),
                child: SizedBox(width: width, child: widget.child)));
      });
}

class RendimientoHeading extends StatelessWidget {
  const RendimientoHeading(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final compact = size.maxWidth < 750;
        return DefaultTextStyle.merge(
            textAlign: compact ? TextAlign.center : TextAlign.start,
            child: Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: children));
      });
}
