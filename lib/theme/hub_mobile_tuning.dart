import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mobile / narrow-viewport tuning for hub glass, ambient, and typography.
abstract final class HubMobileTuning {
  static const double narrowLayoutWidth = 600;
  static const double minTouchTarget = 44;

  static bool isNativeMobilePlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Fewer orbs + lighter blur on phones / narrow web.
  static bool useMobileAmbientOptimizations(BuildContext context) {
    if (isNativeMobilePlatform()) return true;
    if (kIsWeb && MediaQuery.sizeOf(context).shortestSide < narrowLayoutWidth) {
      return true;
    }
    return false;
  }

  static int ambientBlobCount(BuildContext context) {
    return useMobileAmbientOptimizations(context) ? 2 : 3;
  }

  static double ambientOrbBlurSigma(BuildContext context) {
    const base = 120.0;
    return useMobileAmbientOptimizations(context) ? base * 0.62 : base;
  }

  /// Glass panel [BackdropFilter] sigma: 18 → 12 on narrow layouts.
  static double panelBackdropBlurSigma(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < narrowLayoutWidth) return 12;
    // Keep in sync with [HubVisualLanguage.glassBlurSigma] (full-quality desktop).
    return 18;
  }

  /// ~15% smaller “F1 Wide” below [narrowLayoutWidth] to avoid header overflow.
  static double f1WideFontScale(BuildContext context) {
    return MediaQuery.sizeOf(context).width < narrowLayoutWidth ? 0.85 : 1.0;
  }

  /// [IconButton] / small controls: 44×44 minimum hit area (Material 3 / HIG).
  static ButtonStyle iconButtonTouchTarget(BuildContext context) {
    return IconButton.styleFrom(
      minimumSize: const Size(minTouchTarget, minTouchTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
