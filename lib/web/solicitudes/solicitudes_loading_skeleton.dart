import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/web/shared/admin_page_spacing.dart';

class SolicitudesLoadingSkeleton extends StatelessWidget {
  const SolicitudesLoadingSkeleton({
    super.key,
    required this.showFinancials,
    required this.topBar,
  });

  final bool showFinancials;
  final Widget topBar;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, viewport) {
          final horizontal =
              AdminPageSpacing.horizontalForWidth(viewport.maxWidth);
          final tableHeight =
              (MediaQuery.sizeOf(context).height - 500).clamp(360.0, 520.0);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: topBar),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                sliver: SliverList.list(
                  children: [
                    const _SolicitudesTitleSkeleton(),
                    const SizedBox(height: 24),
                    const _SolicitudesFiltersSkeleton(),
                  ],
                ),
              ),
              if (showFinancials)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                  sliver: const SliverToBoxAdapter(
                    child: _SolicitudesFinancialSummarySkeleton(),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                sliver: SliverToBoxAdapter(
                  child: _SolicitudesTableSkeleton(
                    height: tableHeight.toDouble(),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _SolicitudesTitleSkeleton extends StatelessWidget {
  const _SolicitudesTitleSkeleton();

  @override
  Widget build(BuildContext context) => const Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          _SolicitudesSkeletonBlock(width: 190, height: 34),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _SolicitudesSkeletonBlock(width: 200, height: 40),
              _SolicitudesSkeletonBlock(width: 120, height: 40),
              _SolicitudesSkeletonBlock(width: 180, height: 40),
            ],
          ),
        ],
      );
}

class _SolicitudesFiltersSkeleton extends StatelessWidget {
  const _SolicitudesFiltersSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCFC4B1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _SolicitudesSkeletonBlock(width: 58, height: 18),
            _SolicitudesSkeletonBlock(width: 220, height: 48),
            _SolicitudesSkeletonBlock(width: 220, height: 48),
            _SolicitudesSkeletonBlock(width: 220, height: 48),
            _SolicitudesSkeletonBlock(width: 220, height: 48),
            _SolicitudesSkeletonBlock(width: 180, height: 20),
          ],
        ),
      );
}

class _SolicitudesFinancialSummarySkeleton extends StatelessWidget {
  const _SolicitudesFinancialSummarySkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFFD9E1D9),
                ),
              Expanded(
                child: Row(
                  children: [
                    _SolicitudesSkeletonBlock(
                      width: 26,
                      height: 26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: _SolicitudesSkeletonBlock(height: 18),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _SolicitudesTableSkeleton extends StatelessWidget {
  const _SolicitudesTableSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, 1800.0);

          return Container(
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: height,
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      color: const Color(0xFFFAF9F8),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const _SolicitudesTableRowSkeleton(
                        isHeader: true,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: List.generate(
                            6,
                            (index) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: _SolicitudesTableRowSkeleton(
                                  rowIndex: index,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _SolicitudesSkeletonBlock(width: 100, height: 14),
                          SizedBox(width: 28),
                          _SolicitudesSkeletonBlock(width: 70, height: 14),
                          SizedBox(width: 32),
                          _SolicitudesSkeletonBlock(width: 128, height: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _SolicitudesTableRowSkeleton extends StatelessWidget {
  const _SolicitudesTableRowSkeleton({
    this.isHeader = false,
    this.rowIndex = 0,
  });

  final bool isHeader;
  final int rowIndex;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var column = 0; column < 11; column++) ...[
            if (column > 0) const SizedBox(width: 18),
            Expanded(
              flex: const [1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1][column],
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SolicitudesSkeletonBlock(
                  width: isHeader
                      ? const [
                          42.0,
                          58.0,
                          78.0,
                          108.0,
                          54.0,
                          90.0,
                          64.0,
                          72.0,
                          50.0,
                          48.0,
                          62.0,
                        ][column]
                      : _rowBlockWidth(column, rowIndex),
                  height: isHeader ? 17 : 15,
                  borderRadius: BorderRadius.circular(isHeader ? 4 : 6),
                  color: isHeader
                      ? const Color(0xFFE7E5E2)
                      : const Color(0xFFE8ECE9),
                ),
              ),
            ),
          ],
        ],
      );

  double _rowBlockWidth(int column, int index) {
    const patterns = [
      [42.0, 58.0, 76.0, 106.0, 56.0, 142.0, 78.0, 88.0, 58.0, 58.0, 64.0],
      [48.0, 68.0, 62.0, 112.0, 64.0, 118.0, 82.0, 72.0, 52.0, 68.0, 48.0],
      [42.0, 58.0, 84.0, 124.0, 54.0, 154.0, 76.0, 80.0, 60.0, 56.0, 62.0],
    ];
    return patterns[index % patterns.length][column];
  }
}

class _SolicitudesSkeletonBlock extends StatelessWidget {
  const _SolicitudesSkeletonBlock({
    this.width,
    required this.height,
    this.color = const Color(0xFFE8ECE9),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double height;
  final Color color;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      );
}
