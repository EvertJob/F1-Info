import '../display_settings.dart';

/// Fixed hub list metrics for Circuits, Drivers, and Teams (profile-driven).
abstract final class HubListCardStyle {
  HubListCardStyle._();

  /// Vertical gap between hub list rows app-wide.
  static const double listRowSeparatorHeight = 12.0;

  /// [HubListRowShell] horizontal inset from screen edge.
  static const double shellHorizontalMargin = 16.0;

  /// Corner radius for parity list shells (distinct from large [F1Module] cards).
  static const double shellBorderRadius = 12.0;

  /// Inner horizontal padding for the row inside the shell.
  static const double shellInnerPaddingH = 16.0;

  /// Standard + compact.
  static const double _heightStandardCompact = 64.0;

  /// Standard + normal density.
  static const double _heightStandardNormal = 92.0;

  /// Simple mode scales heights by 10% (tighter).
  static const double _simpleHeightFactor = 0.9;

  static double rowHeight(DisplaySettings settings) {
    final base = settings.compact
        ? _heightStandardCompact
        : _heightStandardNormal;
    return settings.uiMode == UiMode.simple ? base * _simpleHeightFactor : base;
  }

  /// Primary title (circuit / driver / team name): compact 14, normal 16.
  static double titleFontSize(DisplaySettings settings) =>
      settings.compact ? 14.0 : 16.0;

  static Duration shellAnimationDuration(DisplaySettings settings) =>
      settings.motionReduced
      ? Duration.zero
      : const Duration(milliseconds: 200);

  /// Secondary line under title (GP name, meta).
  static double subtitleFontSize(DisplaySettings settings) =>
      settings.compact ? 11.0 : 12.0;
}
