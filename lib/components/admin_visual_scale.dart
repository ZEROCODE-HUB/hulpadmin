import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Presents the web UI at the same visual density as browser zoom at 80%.
///
/// The child receives a virtual viewport 1 / [factor] times larger, so existing
/// responsive layouts and breakpoints behave as they do at 80% browser zoom.
/// Painting and hit testing are then scaled back into the real viewport.
class AdminVisualScale extends StatelessWidget {
  const AdminVisualScale({super.key, required this.child});

  static const double factor = 0.85;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || factor == 1) return child;

    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return child;
        }

        final viewport = constraints.biggest;
        if (!viewport.width.isFinite ||
            !viewport.height.isFinite ||
            viewport.width <= 0 ||
            viewport.height <= 0) {
          return child;
        }

        final virtualViewport = Size(
          viewport.width / factor,
          viewport.height / factor,
        );
        final virtualMediaQuery = mediaQuery.copyWith(
          size: virtualViewport,
          devicePixelRatio: mediaQuery.devicePixelRatio * factor,
        );

        return SizedBox.fromSize(
          size: viewport,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: virtualViewport.width,
              maxWidth: virtualViewport.width,
              minHeight: virtualViewport.height,
              maxHeight: virtualViewport.height,
              child: Transform.scale(
                scale: factor,
                alignment: Alignment.topLeft,
                child: MediaQuery(
                  data: virtualMediaQuery,
                  child: SizedBox.fromSize(
                    size: virtualViewport,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
