import 'package:flutter/material.dart';

import '../theme/f1_ui_theme.dart';
import '../widgets/f1_module.dart';

/// Hub-style card: lichte/opaque surface + primaire aflopende rand (zelfde idee als [F1Module]).
class SimulatorGlassPanel extends StatelessWidget {
  const SimulatorGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f1Ui = Theme.of(context).extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final radius = borderRadius ?? f1Ui.cardBorderRadius;
    final blend = f1Ui.moduleSurfaceSolidBlend.clamp(0.0, 1.0);
    final bgBase = scheme.surfaceContainerLow;
    final bg = blend > 0
        ? Color.lerp(bgBase, scheme.surface, blend)!
        : bgBase;
    final drawFading = f1Ui.showFadingBorder;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: f1Ui.moduleShadow,
          ),
          child: child,
        ),
        if (drawFading)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FadingBorderPainter(
                  color: scheme.primary,
                  borderRadius: radius,
                  borderWidth: kF1ModuleBorderWidth,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
