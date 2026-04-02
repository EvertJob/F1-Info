import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/hub_visual_language.dart';
import 'constructor_hub_theme.dart';

/// Glass-style placeholder when a portrait / logo asset fails to load.
class F1HubImageGlassFallback extends StatelessWidget {
  const F1HubImageGlassFallback({
    super.key,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.all(12),
    this.accentGradient,
  });

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  /// Gradient from this color (top-left) to transparent; defaults to F1 accent.
  final Color? accentGradient;

  static const String _logoAsset = 'assets/images/f1_hub_logo.svg';

  @override
  Widget build(BuildContext context) {
    final accent = accentGradient ?? HubVisualLanguage.f1DefaultAccent;

    return HubVisualLanguage.glassPanel(
      context: context,
      topAccent: accent,
      accentGlow: accent,
      accentGlowOpacity: 0.06,
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.38),
                      accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: SvgPicture.asset(
                _logoAsset,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  ConstructorHubColors.textSecondary.withValues(alpha: 0.28),
                  BlendMode.srcIn,
                ),
                placeholderBuilder: (_) => Icon(
                  Icons.speed_rounded,
                  size: 40,
                  color: ConstructorHubColors.textSecondary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
