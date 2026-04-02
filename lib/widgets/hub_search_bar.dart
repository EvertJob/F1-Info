import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';

/// Pill-shaped glass search field (hub parity — same structure light / dark).
class HubSearchBar extends StatelessWidget {
  const HubSearchBar({
    required this.controller,
    required this.hintText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  static const double _radius = 30;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);
    final iconMuted = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: HubVisualLanguage.searchBlurSigma,
          sigmaY: HubVisualLanguage.searchBlurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: borderColor,
              width: HubVisualLanguage.glassBorderWidth,
            ),
            color: fillColor,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: HubVisualLanguage.titilliumInput(
              context,
              color: HubTheme.primaryOnGlassText(context),
            ),
            cursorColor: Theme.of(context).colorScheme.primary,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: GoogleFonts.titilliumWeb(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: HubTheme.secondaryOnGlassText(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: iconMuted,
                size: 22,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
