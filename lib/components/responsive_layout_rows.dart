import 'package:flutter/material.dart';

/// Keeps the generated desktop form rows intact and stacks their fields when
/// the available dialog width is too small for comfortable two-column input.
class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.breakpoint = 560,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final double breakpoint;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.map((child) {
            if (child is Flexible) {
              return child.child;
            }
            if (child is SizedBox &&
                child.width != null &&
                child.height == null) {
              return SizedBox(height: child.width);
            }
            return child;
          }).toList(),
        );
      },
    );
  }
}

/// Uses the existing horizontal toolbar on wide screens and wraps its controls
/// into multiple rows when the route is narrowed by a small viewport or the
/// persistent desktop navigation rail.
class ResponsiveToolbarRow extends StatelessWidget {
  const ResponsiveToolbarRow({
    super.key,
    required this.children,
    this.breakpoint = 980,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final double breakpoint;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final WrapAlignment wrapAlignment;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        }

        return Wrap(
          alignment: wrapAlignment,
          spacing: spacing,
          runSpacing: runSpacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children.map((child) {
            if (child is Flexible) {
              return child.child;
            }
            if (child is SizedBox &&
                child.width != null &&
                child.height == null) {
              return const SizedBox.shrink();
            }
            return child;
          }).toList(),
        );
      },
    );
  }
}

/// Keeps controls that belong to one toolbar section together while they wrap.
class ResponsiveToolbarGroup extends StatelessWidget {
  const ResponsiveToolbarGroup({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}

/// Lays out provider filters and status counts as separate, predictable rows
/// on compact screens and as opposing groups on wide screens.
class ResponsiveProviderFilterLayout extends StatelessWidget {
  const ResponsiveProviderFilterLayout({
    super.key,
    required this.label,
    required this.filters,
    required this.summary,
    this.breakpoint = 900,
  });

  final Widget label;
  final List<Widget> filters;
  final Widget summary;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: label,
                  ),
                  const SizedBox(width: 16),
                  for (var index = 0; index < filters.length; index++) ...[
                    if (index > 0) const SizedBox(width: 12),
                    filters[index],
                  ],
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: summary,
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: label),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var index = 0; index < filters.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(child: filters[index]),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Center(child: summary),
            ],
          ),
        );
      },
    );
  }
}

/// Lets a dropdown shrink into its allocated compact filter column while
/// preserving its natural width beside the label on wide screens.
class ResponsiveFilterField extends StatelessWidget {
  const ResponsiveFilterField({
    super.key,
    required this.selector,
    this.clearAction,
  });

  final Widget selector;
  final Widget? clearAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: selector),
              if (clearAction != null) clearAction!,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [selector, if (clearAction != null) clearAction!],
        );
      },
    );
  }
}

/// Places a page heading and its primary action at opposite ends of the
/// available content width. On narrow layouts the title is centered and the
/// action fills its own row. A heading without an action stays left-aligned on
/// wide layouts and centered on compact layouts.
class ResponsiveSpaceBetween extends StatelessWidget {
  const ResponsiveSpaceBetween({
    super.key,
    required this.leading,
    this.trailing,
    this.breakpoint = 720,
    this.runSpacing = 12,
  });

  final Widget leading;
  final Widget? trailing;
  final double breakpoint;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          if (trailing == null) {
            return SizedBox(
              width: double.infinity,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: leading,
              ),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [leading, trailing!],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: leading),
            if (trailing != null) ...[
              SizedBox(height: runSpacing),
              SizedBox(width: double.infinity, child: trailing!),
            ],
          ],
        );
      },
    );
  }
}

/// Keeps a heading/action pair separated on wide screens and stacks them on
/// compact screens, centering the heading and stretching the action.
class ResponsiveHeadingActionRow extends StatelessWidget {
  const ResponsiveHeadingActionRow({
    super.key,
    required this.children,
    this.breakpoint = 900,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.runSpacing = 12,
  }) : assert(children.length == 2);

  final List<Widget> children;
  final double breakpoint;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: children[0]),
            SizedBox(height: runSpacing),
            SizedBox(width: double.infinity, child: children[1]),
          ],
        );
      },
    );
  }
}
