import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Uses the space left by the sidebar, including on small desktop windows.
class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid(
      {super.key, required this.children, this.minWidth = 150});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final scale =
            math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16);
        final columns = math.max(
            1,
            math.min(children.length,
                ((size.maxWidth + 12) / (minWidth * scale + 12)).floor()));
        final width = (size.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child)
          ],
        );
      });
}

class DashboardSummaryLayout extends StatelessWidget {
  const DashboardSummaryLayout(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max,
      this.crossAxisAlignment = CrossAxisAlignment.start});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        if (size.maxWidth >= 1100) {
          return Row(
              mainAxisSize: mainAxisSize,
              crossAxisAlignment: crossAxisAlignment,
              children: children);
        }
        final panels = children.where((child) => child is! SizedBox).toList();
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < panels.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                panels[i] is Expanded
                    ? (panels[i] as Expanded).child
                    : panels[i],
              ],
            ]);
      });
}

class DashboardMetricLink extends StatelessWidget {
  const DashboardMetricLink(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max,
      this.crossAxisAlignment = CrossAxisAlignment.center});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Row(
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (final child in children)
              child is Text ? Flexible(child: child) : child,
          ]);
}

/// Keeps headers and rows aligned inside a single horizontal scroll area.
class DashboardTablaScroll extends StatefulWidget {
  const DashboardTablaScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  State<DashboardTablaScroll> createState() => _DashboardTablaScrollState();
}

class _DashboardTablaScrollState extends State<DashboardTablaScroll> {
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
        final width = math.max(size.maxWidth, 700.0 * scale);
        final scrollable = size.maxWidth < width;
        return Scrollbar(
          controller: _controller,
          thumbVisibility: scrollable,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(bottom: scrollable ? 12 : 0),
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        );
      });
}

class DashboardTituloResumen extends StatelessWidget {
  const DashboardTituloResumen(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children);
}
