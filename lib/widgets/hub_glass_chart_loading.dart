import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/hub_mobile_tuning.dart';

Color _hubShimmerBase(BuildContext context) {
  final b = Theme.of(context).brightness;
  return b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);
}

Color _hubShimmerHi(BuildContext context) {
  final b = Theme.of(context).brightness;
  return b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.16)
      : Colors.black.withValues(alpha: 0.1);
}

/// Tiny shimmer for pill-sized [FutureBuilder] waits (replaces 20px spinners).
class HubGlassInlineLoadingPlaceholder extends StatelessWidget {
  const HubGlassInlineLoadingPlaceholder({
    super.key,
    this.width = 22,
    this.height = 22,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _hubShimmerBase(context),
      highlightColor: _hubShimmerHi(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for chart data fetch (no raw loading strings / spinners).
class HubGlassChartLoadingPlaceholder extends StatelessWidget {
  const HubGlassChartLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final base = _hubShimmerBase(context);
    final hi = _hubShimmerHi(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: hi,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final titleW = (constraints.maxWidth * 0.55).clamp(120.0, 280.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: titleW,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Full-body or large-pane shimmer for [FutureBuilder] / [StreamBuilder] waits.
class HubGlassPageLoadingPlaceholder extends StatelessWidget {
  const HubGlassPageLoadingPlaceholder({
    super.key,
    this.minHeight = 200,
    this.fixedHeight,
  });

  final double minHeight;
  /// When set, uses this height instead of a fraction of screen height (e.g. inline lists).
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final base = _hubShimmerBase(context);
    final hi = _hubShimmerHi(context);
    final h = fixedHeight ??
        (MediaQuery.sizeOf(context).height * 0.32).clamp(minHeight, 420.0);

    final hPad = MediaQuery.sizeOf(context).width <
            HubMobileTuning.narrowLayoutWidth
        ? 12.0
        : 28.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: hi,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleW =
                    (constraints.maxWidth * 0.5).clamp(100.0, 240.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 22,
                      width: titleW,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    SizedBox(height: fixedHeight != null ? 12 : 20),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
