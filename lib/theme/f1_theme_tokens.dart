import 'package:flutter/material.dart';

/// Wraps content with MouseRegion hover: on hover, 10% primary tint from
/// [F1ThemeTokens.hoverHighlight]. Use for data rows and cards.
class F1Hoverable extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const F1Hoverable({required this.child, this.borderRadius, super.key});

  @override
  State<F1Hoverable> createState() => _F1HoverableState();
}

class _F1HoverableState extends State<F1Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<F1ThemeTokens>();
    final hoverColor = tokens?.hoverHighlight ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_hovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: hoverColor,
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

/// Theme extension tokens derived from [ColorScheme].
/// Use [F1ThemeTokens.fromColorScheme] to create dynamic tokens
/// so panels and hero headers change with the selected F1 team theme.
@immutable
class F1ThemeTokens extends ThemeExtension<F1ThemeTokens> {
  const F1ThemeTokens({
    required this.panel,
    required this.panelStrong,
    required this.outline,
    required this.accentSoft,
    required this.heroStart,
    required this.heroEnd,
    required this.scaffoldTint,
    required this.hoverHighlight,
    required this.statusError,
    required this.statusWarning,
    required this.statusSuccess,
    required this.borderSubtle,
  });

  final Color panel;
  final Color panelStrong;
  final Color outline;
  final Color accentSoft;
  final Color heroStart;
  final Color heroEnd;

  /// Scaffold background: surface blended with 3% primary tint.
  final Color scaffoldTint;

  /// Hover highlight: primary at 9% opacity for table rows & nav items.
  final Color hoverHighlight;

  /// Status colors from scheme: error (cancelled), tertiary (ongoing), primary (success).
  final Color statusError;
  final Color statusWarning;
  final Color statusSuccess;

  /// Muted border (e.g. surface dividers). scheme.outline with reduced alpha.
  final Color borderSubtle;

  /// Text on colored backgrounds: white if bg.luminance < 0.5, else black. Use for team headers, hero cards.
  static Color textOnBackground(Color background) {
    return background.computeLuminance() < 0.5 ? Colors.white : Colors.black;
  }

  /// Creates [F1ThemeTokens] from a [ColorScheme], mapping scheme colors to tokens.
  ///
  /// - [panel]: surfaceContainer (softer surface for inputs, cards)
  /// - [panelStrong]: surfaceContainerHighest (stronger surface for panels, nav)
  /// - [outline]: outlineVariant (borders, dividers)
  /// - [accentSoft]: primary at 10% opacity (subtle highlights)
  /// - [heroStart], [heroEnd]: gradient based on primary/primaryContainer for hero headers
  /// - [scaffoldTint]: surface + 3% primary for subtle background warmth
  /// - [hoverHighlight]: primary at 9% for hover effects
  factory F1ThemeTokens.fromColorScheme(ColorScheme scheme) {
    final panel = scheme.surfaceContainer;
    final panelStrong = scheme.surfaceContainerHighest;
    final outline = scheme.outlineVariant;
    final accentSoft = scheme.primary.withValues(alpha: 0.1);
    final scaffoldTint = Color.lerp(scheme.surface, scheme.primary, 0.025)!;
    final hoverHighlight = scheme.primary.withValues(alpha: 0.10);

    // Hero gradient: distinct primary → primaryContainer for visible team-colored headers.
    final heroStart = scheme.primary;
    final heroEnd = scheme.primaryContainer;
    final statusError = scheme.error;
    final statusWarning = scheme.tertiary;
    final statusSuccess = scheme.primary;
    final borderSubtle = scheme.outlineVariant.withValues(alpha: 0.5);

    return F1ThemeTokens(
      panel: panel,
      panelStrong: panelStrong,
      outline: outline,
      accentSoft: accentSoft,
      heroStart: heroStart,
      heroEnd: heroEnd,
      scaffoldTint: scaffoldTint,
      hoverHighlight: hoverHighlight,
      statusError: statusError,
      statusWarning: statusWarning,
      statusSuccess: statusSuccess,
      borderSubtle: borderSubtle,
    );
  }

  @override
  F1ThemeTokens copyWith({
    Color? panel,
    Color? panelStrong,
    Color? outline,
    Color? accentSoft,
    Color? heroStart,
    Color? heroEnd,
    Color? scaffoldTint,
    Color? hoverHighlight,
    Color? statusError,
    Color? statusWarning,
    Color? statusSuccess,
    Color? borderSubtle,
  }) {
    return F1ThemeTokens(
      panel: panel ?? this.panel,
      panelStrong: panelStrong ?? this.panelStrong,
      outline: outline ?? this.outline,
      accentSoft: accentSoft ?? this.accentSoft,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      scaffoldTint: scaffoldTint ?? this.scaffoldTint,
      hoverHighlight: hoverHighlight ?? this.hoverHighlight,
      statusError: statusError ?? this.statusError,
      statusWarning: statusWarning ?? this.statusWarning,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  F1ThemeTokens lerp(ThemeExtension<F1ThemeTokens>? other, double t) {
    if (other is! F1ThemeTokens) return this;
    return F1ThemeTokens(
      panel: Color.lerp(panel, other.panel, t)!,
      panelStrong: Color.lerp(panelStrong, other.panelStrong, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      scaffoldTint: Color.lerp(scaffoldTint, other.scaffoldTint, t)!,
      hoverHighlight: Color.lerp(hoverHighlight, other.hoverHighlight, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}
