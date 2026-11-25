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

class DashboardOverviewLoadingSkeleton extends StatelessWidget {
  const DashboardOverviewLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEE4D3)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          children: [
            DashboardMetricGrid(
              minWidth: 170,
              children: List.generate(
                6,
                (_) => const _DashboardMetricSkeletonCard(height: 215),
              ),
            ),
            const SizedBox(height: 24),
            DashboardMetricGrid(
              minWidth: 180,
              children: List.generate(
                5,
                (_) => const _DashboardMetricSkeletonCard(height: 220),
              ),
            ),
          ],
        ),
      );
}

class DashboardSummaryLoadingSkeleton extends StatelessWidget {
  const DashboardSummaryLoadingSkeleton({
    super.key,
    this.rowCount = 4,
  });

  final int rowCount;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4D4B9)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _DashboardSkeletonBlock(width: 190, height: 22),
                  const Spacer(),
                  _DashboardSkeletonBlock(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    const Expanded(
                      child: _DashboardSkeletonBlock(height: 58),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const _DashboardSkeletonBlock(width: 150, height: 16),
              const SizedBox(height: 8),
              for (var index = 0; index < rowCount; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _DashboardSkeletonBlock(
                        width: 30,
                        height: 30,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DashboardSkeletonBlock(
                              width: index.isEven ? 150 : 110,
                              height: 14,
                            ),
                            const SizedBox(height: 6),
                            _DashboardSkeletonBlock(
                              width: index.isEven ? 95 : 130,
                              height: 11,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _DashboardSkeletonBlock(width: 44, height: 14),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

class _DashboardMetricSkeletonCard extends StatelessWidget {
  const _DashboardMetricSkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minHeight: height),
        clipBehavior: Clip.antiAlias,
        foregroundDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF075D3F), width: 3)),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0EAE2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardSkeletonBlock(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 8),
            const _DashboardSkeletonBlock(width: 125, height: 16),
            const SizedBox(height: 12),
            const _DashboardSkeletonBlock(width: 70, height: 28),
            const SizedBox(height: 12),
            const Divider(height: 16, thickness: 1, color: Color(0xFFECEDEB)),
            const _DashboardSkeletonBlock(width: 110, height: 13),
            const SizedBox(height: 8),
            const _DashboardSkeletonBlock(width: 80, height: 13),
          ],
        ),
      );
}

class _DashboardSkeletonBlock extends StatelessWidget {
  const _DashboardSkeletonBlock({
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECE9),
          borderRadius: borderRadius,
        ),
      );
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
              child is Text
                  ? (mainAxisSize == MainAxisSize.max
                      ? Expanded(child: child)
                      : Flexible(child: child))
                  : child,
          ]);
}

class DashboardMetricHeader extends StatelessWidget {
  const DashboardMetricHeader({
    super.key,
    required this.icon,
    required this.child,
    this.vertical = false,
  });

  final IconData icon;
  final Widget child;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final icono = Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE9F4EC),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: const Color(0xFF075D3F)),
    );
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [icono, const SizedBox(height: 8), child],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [icono, const SizedBox(width: 10), Expanded(child: child)],
    );
  }
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
