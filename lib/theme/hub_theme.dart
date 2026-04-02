import 'package:flutter/material.dart';

/// Theme-aware tokens for hub / glass DNA (light “Frosted” vs dark cockpit).
abstract final class HubTheme {
  /// F1 deep charcoal — primary headers on frosted light surfaces.
  static const Color f1DeepCharcoal = Color(0xFF15151E);

  /// Light canvas behind ambient blobs.
  static const Color lightCanvas = Color(0xFFF3F3F5);

  /// Dark canvas (matches [ConstructorHubColors.background]).
  static const Color darkCanvas = Color(0xFF0D0D0D);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary text on glass (F1 Wide / wide headers).
  static Color primaryOnGlassText(BuildContext context) =>
      isDark(context) ? Colors.white : f1DeepCharcoal;

  /// Secondary / supporting text on glass (Titillium-style callers).
  static Color secondaryOnGlassText(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.7)
          : Colors.black.withValues(alpha: 0.6);

  /// Icons on glass: prefer [Theme.iconTheme], else same as primary on glass.
  static Color iconOnGlass(BuildContext context) =>
      Theme.of(context).iconTheme.color ?? primaryOnGlassText(context);

  /// Nested stat cells on frosted panels (light: black 0.03; dark: elevated surface).
  static Color statsTrioNestedFill(
    BuildContext context, {
    double darkAlpha = 0.65,
  }) =>
      isDark(context)
          ? const Color(0xFF1C1C1C).withValues(alpha: darkAlpha)
          : Colors.black.withValues(alpha: 0.03);

  /// Stat cell border (accent edge for points cell, else subtle rim).
  static Color statsTrioCellBorder(
    BuildContext context, {
    required bool pointsCell,
    required Color accent,
  }) {
    if (pointsCell) return accent.withValues(alpha: 0.92);
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
  }
}
