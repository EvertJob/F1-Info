import 'package:flutter/material.dart';

import '../display_settings.dart';

/// Look & feel tokens for **Standard** (glass-style) vs **Simple** (flat) UI.
///
/// Injected via [ThemeData.extensions] so the same values apply everywhere
/// ([NavigationRail], [NavigationBar], sheets, [F1Module]) without branching on
/// [UiMode] in leaf widgets.
///
/// **Glass:** use [glassBlur] as `sigmaX`/`sigmaY` for [ImageFilter.blur] on a
/// [BackdropFilter] wrapping panel chrome (desktop rail container, mobile
/// bottom-bar background, etc.) so the formula stays identical across form factors.
@immutable
class F1UiTheme extends ThemeExtension<F1UiTheme> {
  const F1UiTheme({
    required this.cardPadding,
    required this.cardBorderRadius,
    required this.glassBlur,
    required this.moduleShadow,
    required this.showFadingBorder,
    this.moduleSurfaceSolidBlend = 0,
    this.useInstantTransitions = false,
  });

  /// Default padding inside cards / modules when the widget does not override.
  final EdgeInsets cardPadding;

  /// Corner radius for modules and aligned surfaces (rail panel, cards).
  final double cardBorderRadius;

  /// Backdrop blur sigma for glass panels (0 in [simple]).
  final double glassBlur;

  /// Module elevation; `null` in flat mode.
  final List<BoxShadow>? moduleShadow;

  /// Primary fading perimeter on [F1Module]-style surfaces.
  final bool showFadingBorder;

  /// Pulls [F1Module] fill toward [ColorScheme.surface] (0 = none). Non-zero in
  /// [simple] improves contrast on ambient / patterned shells without glass.
  final double moduleSurfaceSolidBlend;

  /// When true (from [DisplaySettings.motionReduced]), prefer zero-duration
  /// theme transitions and non-animated chrome swaps.
  final bool useInstantTransitions;

  /// Glassmorphism-style defaults: generous padding, soft shadow, strong blur.
  factory F1UiTheme.standard({bool compact = false}) {
    return F1UiTheme(
      cardPadding: EdgeInsets.all(compact ? 14 : 20),
      cardBorderRadius: compact ? 16 : 20,
      glassBlur: compact ? 14 : 18,
      moduleShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: compact ? 12 : 18,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: compact ? 4 : 6,
          offset: const Offset(0, 1),
        ),
      ],
      showFadingBorder: true,
    );
  }

  /// Flat, data-first look: no blur, no module shadow, tighter geometry.
  factory F1UiTheme.simple({bool compact = false}) {
    return F1UiTheme(
      cardPadding: EdgeInsets.all(compact ? 8 : 12),
      cardBorderRadius: compact ? 10 : 14,
      glassBlur: 0,
      moduleSurfaceSolidBlend: compact ? 0.16 : 0.12,
      moduleShadow: null,
      showFadingBorder: false,
    );
  }

  /// Resolves from persisted / runtime [DisplaySettings].
  static F1UiTheme fromSettings(DisplaySettings settings) {
    final F1UiTheme base = switch (settings.uiMode) {
      UiMode.simple => F1UiTheme.simple(compact: settings.compact),
      UiMode.standard => F1UiTheme.standard(compact: settings.compact),
    };
    if (!settings.motionReduced) {
      return base;
    }
    return base.copyWith(
      glassBlur: 0,
      moduleShadow: null,
      useInstantTransitions: true,
    );
  }

  /// Safe fallback before [DisplaySettingsController] has run.
  static F1UiTheme fallback() => F1UiTheme.standard();

  @override
  F1UiTheme copyWith({
    EdgeInsets? cardPadding,
    double? cardBorderRadius,
    double? glassBlur,
    List<BoxShadow>? moduleShadow,
    bool? showFadingBorder,
    double? moduleSurfaceSolidBlend,
    bool? useInstantTransitions,
  }) {
    return F1UiTheme(
      cardPadding: cardPadding ?? this.cardPadding,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      glassBlur: glassBlur ?? this.glassBlur,
      moduleShadow: moduleShadow ?? this.moduleShadow,
      showFadingBorder: showFadingBorder ?? this.showFadingBorder,
      moduleSurfaceSolidBlend:
          moduleSurfaceSolidBlend ?? this.moduleSurfaceSolidBlend,
      useInstantTransitions:
          useInstantTransitions ?? this.useInstantTransitions,
    );
  }

  @override
  F1UiTheme lerp(ThemeExtension<F1UiTheme>? other, double t) {
    if (other is! F1UiTheme) return this;
    return F1UiTheme(
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      cardBorderRadius:
          cardBorderRadius + (other.cardBorderRadius - cardBorderRadius) * t,
      glassBlur: glassBlur + (other.glassBlur - glassBlur) * t,
      moduleShadow: t < 0.5 ? moduleShadow : other.moduleShadow,
      showFadingBorder: t < 0.5 ? showFadingBorder : other.showFadingBorder,
      moduleSurfaceSolidBlend: moduleSurfaceSolidBlend +
          (other.moduleSurfaceSolidBlend - moduleSurfaceSolidBlend) * t,
      useInstantTransitions: t < 0.5
          ? useInstantTransitions
          : other.useInstantTransitions,
    );
  }
}

/// Merges [F1UiTheme] into [base] while keeping other extensions (e.g. [F1ThemeTokens]).
ThemeData themeWithF1Ui(ThemeData base, F1UiTheme ui) {
  final next = Map<Object, ThemeExtension<dynamic>>.from(base.extensions);
  next[ui.type] = ui;
  return base.copyWith(extensions: next.values);
}
