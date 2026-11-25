import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/components/hulp_input_decoration.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/web/menu/menu_widget.dart';
import '/web/shared/admin_page_spacing.dart';

class AdminPageLoadingSkeleton extends StatelessWidget {
  const AdminPageLoadingSkeleton({
    super.key,
    this.topBar,
    this.filterCount = 2,
    this.summaryCount = 0,
    this.actionCount = 1,
    this.columnCount = 6,
    this.rowCount = 6,
    this.asCards = false,
  });

  final Widget? topBar;
  final int filterCount;
  final int summaryCount;
  final int actionCount;
  final int columnCount;
  final int rowCount;
  final bool asCards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, viewport) {
          final horizontal =
              AdminPageSpacing.horizontalForWidth(viewport.maxWidth);
          return CustomScrollView(
            slivers: [
              if (topBar != null) SliverToBoxAdapter(child: topBar!),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                sliver: SliverList.list(
                  children: [
                    _AdminHeadingSkeleton(actionCount: actionCount),
                    if (filterCount > 0) ...[
                      const SizedBox(height: 24),
                      _AdminFiltersSkeleton(count: filterCount),
                    ],
                  ],
                ),
              ),
              if (summaryCount > 0)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                  sliver: SliverToBoxAdapter(
                    child: _AdminSummarySkeleton(count: summaryCount),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                sliver: SliverToBoxAdapter(
                  child: AdminResultsLoadingSkeleton(
                    columnCount: columnCount,
                    rowCount: rowCount,
                    asCards: asCards,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class AdminPageHeaderBar extends StatelessWidget {
  const AdminPageHeaderBar({
    super.key,
    required this.routeTitle,
    required this.searchHint,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.trailingPadding,
  });

  final String routeTitle;
  final String searchHint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final double? trailingPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = AdminPageSpacing.headerHorizontal(context);
          final rightPadding = trailingPadding ?? horizontal;
          final theme = FlutterFlowTheme.of(context);
          final showBreadcrumb =
              MenuWidget.breadcrumbEnBarraSuperior(context);
          final availableWidth =
              constraints.maxWidth - horizontal - rightPadding;
          final reservedWidth = (showBreadcrumb ? 16.0 + 160.0 : 0.0) + 52.0;
          final searchWidth = math.min(
            AdminHeaderSearchWidth.standardWidth,
            math.max(0.0, availableWidth - reservedWidth),
          ).toDouble();
          final breadcrumbWidth = math.max(
            0.0,
            availableWidth - searchWidth - 52.0 - (showBreadcrumb ? 16.0 : 0.0),
          ).toDouble();

          return Container(
            height: 72,
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontal,
              0,
              rightPadding,
              0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECE8),
              border: Border.all(color: const Color(0xFFD9C19C), width: 0.5),
            ),
            child: Row(
              children: [
                if (showBreadcrumb) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: breadcrumbWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Inicio',
                          style: TextStyle(
                            color: Color(0xFF5E252B),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF5E252B),
                            size: 22,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            routeTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5E252B),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12.0),
                  child: SizedBox(
                    width: searchWidth,
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onFieldSubmitted: onFieldSubmitted,
                      decoration: decorarInputHulp(
                        context,
                        InputDecoration(
                          isDense: true,
                          hintText: searchHint,
                          hintStyle: TextStyle(
                            color: theme.secondary,
                            fontSize: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF8A8A8A),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.secondaryBackground,
                        ),
                        etiqueta: searchHint,
                        busqueda: true,
                        placeholder: searchHint,
                      ),
                      style: theme.bodyMedium,
                      cursorColor: theme.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.notifications_none,
                  color: theme.accent3,
                  size: 24,
                ),
              ],
            ),
          );
        },
      );
}

class AdminHeaderSearchWidth extends StatelessWidget {
  static const double standardWidth = 394;

  const AdminHeaderSearchWidth({
    super.key,
    required this.child,
    this.maxWidth = standardWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? math.min(maxWidth, constraints.maxWidth)
              : maxWidth;
          return SizedBox(width: width, child: child);
        },
      );
}

class AdminResultsLoadingSkeleton extends StatelessWidget {
  const AdminResultsLoadingSkeleton({
    super.key,
    this.columnCount = 6,
    this.rowCount = 6,
    this.asCards = false,
    this.height,
  });

  final int columnCount;
  final int rowCount;
  final bool asCards;
  final double? height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = height ??
              (constraints.maxHeight.isFinite
                  ? math.max(360.0, constraints.maxHeight)
                  : (MediaQuery.sizeOf(context).height - 400)
                      .clamp(360.0, 540.0)
                      .toDouble());

          return asCards
              ? _AdminCardRowsSkeleton(
                  height: panelHeight,
                  rowCount: rowCount,
                )
              : _AdminTableSkeleton(
                  height: panelHeight,
                  columnCount: columnCount,
                  rowCount: rowCount,
                );
        },
      );
}

class AdminSkeletonBlock extends StatelessWidget {
  const AdminSkeletonBlock({
    super.key,
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

class _AdminHeadingSkeleton extends StatelessWidget {
  const _AdminHeadingSkeleton({required this.actionCount});

  final int actionCount;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          const AdminSkeletonBlock(width: 190, height: 34),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              actionCount,
              (index) => AdminSkeletonBlock(
                width: index == 0 ? 180 : 120,
                height: 40,
              ),
            ),
          ),
        ],
      );
}

class _AdminFiltersSkeleton extends StatelessWidget {
  const _AdminFiltersSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCFC4B1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < count; index++)
              AdminSkeletonBlock(
                width: index == 0 ? 210 : 190,
                height: 48,
              ),
          ],
        ),
      );
}

class _AdminSummarySkeleton extends StatelessWidget {
  const _AdminSummarySkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (var index = 0; index < count; index++) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFFD9E1D9),
                ),
              Expanded(
                child: Row(
                  children: [
                    AdminSkeletonBlock(
                      width: 26,
                      height: 26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: AdminSkeletonBlock(height: 18)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _AdminTableSkeleton extends StatelessWidget {
  const _AdminTableSkeleton({
    required this.height,
    required this.columnCount,
    required this.rowCount,
  });

  final double height;
  final int columnCount;
  final int rowCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, 1400.0);
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
                      height: 60,
                      color: const Color(0xFFFAF9F8),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _AdminTableRowSkeleton(
                        columnCount: columnCount,
                        isHeader: true,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: List.generate(
                            rowCount,
                            (index) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: _AdminTableRowSkeleton(
                                  columnCount: columnCount,
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
                          AdminSkeletonBlock(width: 92, height: 14),
                          SizedBox(width: 28),
                          AdminSkeletonBlock(width: 64, height: 14),
                          SizedBox(width: 32),
                          AdminSkeletonBlock(width: 124, height: 18),
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

class _AdminTableRowSkeleton extends StatelessWidget {
  const _AdminTableRowSkeleton({
    required this.columnCount,
    this.isHeader = false,
    this.rowIndex = 0,
  });

  final int columnCount;
  final bool isHeader;
  final int rowIndex;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var column = 0; column < columnCount; column++) ...[
            if (column > 0) const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminSkeletonBlock(
                  width: isHeader
                      ? (column.isEven ? 90 : 72)
                      : 62.0 + ((rowIndex + column * 2) % 5) * 15,
                  height: isHeader ? 17 : 15,
                  color: isHeader
                      ? const Color(0xFFE7E5E2)
                      : const Color(0xFFE8ECE9),
                  borderRadius: BorderRadius.circular(isHeader ? 4 : 6),
                ),
              ),
            ),
          ],
        ],
      );
}

class _AdminCardRowsSkeleton extends StatelessWidget {
  const _AdminCardRowsSkeleton({required this.height, required this.rowCount});

  final double height;
  final int rowCount;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Column(
          children: List.generate(
            rowCount,
            (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD9C19C)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: AdminSkeletonBlock(width: 160, height: 18),
                      ),
                      AdminSkeletonBlock(
                        width: 54,
                        height: 24,
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE9F4EC),
                      ),
                      const SizedBox(width: 14),
                      const AdminSkeletonBlock(width: 34, height: 34),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
