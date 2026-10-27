import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_drop_down.dart';

class SoporteResponsiveContent extends StatelessWidget {
  const SoporteResponsiveContent(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final items = children.where((child) => child is! SizedBox).toList();
        final table = (items.last as Expanded).child;
        return CustomScrollView(slivers: [
          SliverList.list(children: items.sublist(0, items.length - 1)),
          SliverLayoutBuilder(builder: (context, constraints) {
            final height = (constraints.viewportMainAxisExtent -
                    constraints.precedingScrollExtent)
                .clamp(360.0, double.infinity);
            return SliverToBoxAdapter(
                child: SizedBox(height: height, child: table));
          }),
        ]);
      });
}

class SoporteResponsiveTitle extends StatelessWidget {
  const SoporteResponsiveTitle(
      {super.key,
      required this.children,
      this.mainAxisSize = MainAxisSize.max,
      this.mainAxisAlignment = MainAxisAlignment.spaceBetween});

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        if (size.maxWidth < 750) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: children.first),
                const SizedBox(height: 12),
                ...children.skip(1),
              ]);
        }
        return Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            children: children);
      });
}

class SoporteResponsiveFilters extends StatelessWidget {
  const SoporteResponsiveFilters(
      {super.key, required this.children, required this.counter});

  final List<Widget> children;
  final Text counter;

  @override
  Widget build(BuildContext context) {
    final items = children.where((child) => child is! SizedBox).toList();
    final label =
        items.first is Padding ? (items.first as Padding).child! : items.first;
    final groups = <List<Widget>>[];
    for (final item in items.skip(1)) {
      if (item is FlutterFlowDropDown<String>) {
        groups.add([item]);
      } else {
        groups.last.add(item);
      }
    }
    Widget field(int index, double width) => SizedBox(
        width: width,
        child: Row(children: [
          Expanded(child: groups[index].first),
          ...groups[index]
              .skip(1)
              .expand((child) => [const SizedBox(width: 4), child]),
        ]));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x7C766C4D), width: 0.5)),
      child: LayoutBuilder(builder: (context, size) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        if (size.maxWidth < 750) {
          final columns =
              size.maxWidth >= 292 * scale.clamp(1, double.infinity) ? 2 : 1;
          final width = (size.maxWidth - (columns - 1) * 12) / columns;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: label),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [field(0, width), field(1, width)]),
                const SizedBox(height: 12),
                Center(child: counter),
              ]);
        }
        final widths = [
          for (final group in groups) 200.0 + (group.length > 1 ? 28 : 0)
        ];
        double measure(InlineSpan span) {
          final painter = TextPainter(
              text: span,
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: Directionality.of(context))
            ..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final labelText = label as Text;
        final requiredWidth = widths[0] +
            widths[1] +
            40 +
            measure(TextSpan(text: labelText.data, style: labelText.style)) +
            measure(
                TextSpan(style: counter.style, children: [counter.textSpan!]));
        if (size.maxWidth >= requiredWidth) {
          return Row(children: [
            label,
            const SizedBox(width: 12),
            field(0, widths[0]),
            const SizedBox(width: 12),
            field(1, widths[1]),
            const SizedBox(width: 16),
            const Spacer(),
            counter
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [label, counter]),
              const SizedBox(height: 12),
              Row(children: [
                field(0, widths[0]),
                const SizedBox(width: 12),
                field(1, widths[1])
              ]),
            ]);
      }),
    );
  }
}
