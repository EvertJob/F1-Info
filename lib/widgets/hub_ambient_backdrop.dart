import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';

/// Soft blurred orbs behind hub shell (muted team red + deep indigo).
/// Opacity stays very low so depth is felt more than seen.
///
/// On mobile / narrow web: at most **two** orbs and a lower blur sigma for FPS.
class HubAmbientBackdrop extends StatelessWidget {
  const HubAmbientBackdrop({super.key});

  static const Color _teamRed = Color(0xFFE10600);
  static const Color _indigoOrb = Color(0xFF1A2744);

  @override
  Widget build(BuildContext context) {
    final n = HubMobileTuning.ambientBlobCount(context);
    final sigma = HubMobileTuning.ambientOrbBlurSigma(context);
    final isDark = HubTheme.isDark(context);
    final mobile = HubMobileTuning.useMobileAmbientOptimizations(context);
    final oDark = mobile
        ? HubVisualLanguage.ambientBackdropBlobOpacityDark * 0.9
        : HubVisualLanguage.ambientBackdropBlobOpacityDark;
    final oLight = mobile
        ? HubVisualLanguage.ambientBackdropBlobOpacityLight * 0.85
        : HubVisualLanguage.ambientBackdropBlobOpacityLight;

    Widget blob({
      required double size,
      required Color color,
      required double opacity,
      double? left,
      double? top,
      double? right,
      double? bottom,
    }) {
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity),
            ),
          ),
        ),
      );
    }

    final blobOpacity = isDark ? oDark : oLight;
    final blobs = <Widget>[
      blob(
        size: 400,
        color: _teamRed,
        opacity: blobOpacity,
        left: -150,
        top: -130,
      ),
      blob(
        size: 420,
        color: _indigoOrb,
        opacity: blobOpacity,
        right: -140,
        top: 20,
      ),
      if (n >= 3)
        blob(
          size: 380,
          color: _teamRed,
          opacity: blobOpacity,
          left: 60,
          bottom: -110,
        ),
    ];

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? HubTheme.darkCanvas : HubTheme.lightCanvas,
              ),
            ),
          ),
          ...blobs,
        ],
      ),
    );
  }
}
