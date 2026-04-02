import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hub_mobile_tuning.dart';
import 'hub_theme.dart';

/// Visual tokens for “Glassmorphic Ambient” parity (f1hub reference).
abstract final class HubVisualLanguage {
  static const double glassBlurSigma = 18;
  static const double searchBlurSigma = 15;
  static const double cardRadius = 20;
  static const double letterSpacingF1Wide = 1.2;
  static const double glassBorderWidth = 0.8;
  static const double glassBorderOpacity = 0.12;
  static const double glassFillOpacity = 0.08;
  static const double glassSheenTopOpacity = 0.1;

  /// F1 brand red when no team accent resolves.
  static const Color f1DefaultAccent = Color(0xFFE10600);

  /// Blurred modal barrier (dialogs / fullscreen charts).
  static const double dialogBarrierBlurSigma = 15;

  /// Mobile hub top strip ([F1HubMobileGlassAppBar]).
  static const double mobileHubTopBarBlurSigma = 15;

  /// Full-screen navigation overlay (hamburger menu).
  static const double fullScreenNavMenuBlurSigma = 25;

  /// Soft orbs behind hub shell ([HubAmbientBackdrop]).
  static const double ambientBackdropBlurSigma = 120;
  static const double ambientBackdropBlobOpacityDark = 0.05;
  static const double ambientBackdropBlobOpacityLight = 0.08;

  /// “F1 Wide” stand-in: [GoogleFonts.orbitron] + [letterSpacingF1Wide].
  static TextStyle f1Wide(
    BuildContext context, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) {
    final c = color ?? HubTheme.primaryOnGlassText(context);
    final scaled =
        fontSize * HubMobileTuning.f1WideFontScale(context);
    return GoogleFonts.orbitron(
      fontSize: scaled,
      fontWeight: fontWeight,
      letterSpacing: letterSpacingF1Wide,
      height: height ?? 1.1,
      color: c,
    );
  }

  /// Secondary body in Titillium. With [color] null, uses hub secondary (dark: white 0.7, light: black 0.6).
  static TextStyle titilliumSecondary(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double opacity = 0.7,
    double? letterSpacing,
    double? height,
  }) {
    final Color resolved = color != null
        ? color.withValues(alpha: opacity)
        : HubTheme.secondaryOnGlassText(context);
    return GoogleFonts.titilliumWeb(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height ?? 1.35,
      letterSpacing: letterSpacing,
      color: resolved,
    );
  }

  static TextStyle titilliumInput(BuildContext context, {Color? color}) {
    return GoogleFonts.titilliumWeb(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: color ?? HubTheme.primaryOnGlassText(context),
    );
  }

  /// Theme-aware glass panel shell (border + fill gradient). Prefer [glassPanel] for full blur stack.
  static BoxDecoration glassPanelDecoration(
    BuildContext context, {
    double radius = cardRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: glassBorderWidth,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: glassSheenTopOpacity),
            Colors.white.withValues(alpha: glassFillOpacity),
          ],
        ),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.06),
        width: glassBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      color: Colors.white.withValues(alpha: 0.65),
    );
  }

  /// Glass stack: blur σ + layered fills + [child] (no outer padding).
  /// Dark: existing cockpit stack. Light: milky frosted fill (Base44-style).
  static Widget blurredGlassLayer({
    required BuildContext context,
    required Widget child,
    double blurSigma = glassBlurSigma,
    Color? accentGlow,
    double accentGlowOpacity = 0.085,
    EdgeInsetsGeometry? padding,
    /// Standings legend chips: light α 0.4, dark minimal α 0.08 (see [glassPanel]).
    bool legendChipDense = false,
  }) {
    final content =
        padding != null ? Padding(padding: padding, child: child) : child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowOpacity =
        isDark ? accentGlowOpacity : accentGlowOpacity * 0.55;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (accentGlow != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.92, 0.96),
                    radius: 1.22,
                    colors: [
                      accentGlow.withValues(alpha: glowOpacity),
                      accentGlow.withValues(alpha: isDark ? 0.045 : 0.028),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
          if (legendChipDense)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: glassFillOpacity)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            )
          else if (isDark) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1C1C20).withValues(alpha: 0.92),
                      const Color(0xFF0E0E11).withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: glassSheenTopOpacity),
                      Colors.white.withValues(alpha: glassFillOpacity * 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ] else
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          // Non-positioned: gives the Stack a finite size when the parent is
          // unbounded (Column/ListView). All-[Positioned.fill] stacks use
          // constraints.biggest and assert !size.isFinite.
          content,
        ],
      ),
    );
  }

  /// Rounded glass panel with border (full formula).
  ///
  /// No top accent strip (flat shell in light and dark). [topAccent] / [topAccentHeight]
  /// are ignored; [accentGlow] (or [topAccent] as glow fallback) still tints the glass.
  ///
  /// [context] drives light “Frosted” vs dark cockpit styling.
  static Widget glassPanel({
    required BuildContext context,
    required Widget child,
    double radius = cardRadius,
    double? blurSigma,
    Color? topAccent,
    double topAccentHeight = 4,
    Color? accentGlow,
    double accentGlowOpacity = 0.085,
    EdgeInsetsGeometry? padding,
    bool legendChipDense = false,
    /// e.g. desktop light rail: [Border] with only a right edge.
    BoxBorder? panelBorder,
  }) {
    final sigma = blurSigma ??
        HubMobileTuning.panelBackdropBlurSigma(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = accentGlow ?? topAccent;

    final blurBody = blurredGlassLayer(
      context: context,
      blurSigma: sigma,
      accentGlow: glow,
      accentGlowOpacity: accentGlowOpacity,
      padding: padding,
      legendChipDense: legendChipDense,
      child: child,
    );

    final rim = panelBorder ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          width: glassBorderWidth,
        );

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: rim,
        ),
        child: blurBody,
      ),
    );

    if (isDark) {
      return inner;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: inner,
    );
  }
}
