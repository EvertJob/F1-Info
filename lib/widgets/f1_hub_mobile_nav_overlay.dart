import 'dart:ui' as ui;

import 'package:f1/theme/hub_theme.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/widgets/constructor_hub_theme.dart';
import 'package:f1/widgets/hub_legal_dialog.dart';
import 'package:f1/widgets/next_race_hub_mini_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen blurred menu (σ25) with nav rows (min 56px) and optional next race.
///
/// **Light** shell: light frosted panel; branding + close are in [F1HubMobileGlassAppBar].
/// **Dark** shell: cockpit scrim. Accent: [ConstructorHubColors.railLogoRed].
class F1HubMobileNavOverlay extends StatelessWidget {
  const F1HubMobileNavOverlay({
    super.key,
    required this.hubCockpitDark,
    required this.selectedIndex,
    required this.entries,
    required this.onDestinationSelected,
    required this.onClose,
    this.nextRaceName,
    this.nextRaceDate,
  });

  /// `true` when the hub shell is dark ([ThemeData.brightness] is dark).
  final bool hubCockpitDark;

  final int selectedIndex;
  final List<F1HubMobileNavEntry> entries;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onClose;
  final String? nextRaceName;
  final DateTime? nextRaceDate;

  static const Color _menuAccent = ConstructorHubColors.railLogoRed;

  @override
  Widget build(BuildContext context) {
    if (hubCockpitDark) {
      final menuTheme = Theme.of(context).copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _menuAccent,
          brightness: Brightness.dark,
        ),
      );

      return Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BackdropBlur(
              onDismiss: onClose,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        ConstructorHubColors.surface,
                        Colors.white,
                        0.05,
                      )!,
                      ConstructorHubColors.surface,
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: Theme(
                  data: menuTheme,
                  child: _MenuColumn(
                    hubCockpitDark: true,
                    selectedIndex: selectedIndex,
                    entries: entries,
                    onDestinationSelected: onDestinationSelected,
                    nextRaceName: nextRaceName,
                    nextRaceDate: nextRaceDate,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BackdropBlur(
            onDismiss: onClose,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: HubTheme.lightCanvas.withValues(alpha: 0.92),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: _MenuColumn(
                hubCockpitDark: false,
                selectedIndex: selectedIndex,
                entries: entries,
                onDestinationSelected: onDestinationSelected,
                nextRaceName: nextRaceName,
                nextRaceDate: nextRaceDate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropBlur extends StatelessWidget {
  const _BackdropBlur({
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: HubVisualLanguage.fullScreenNavMenuBlurSigma,
            sigmaY: HubVisualLanguage.fullScreenNavMenuBlurSigma,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MenuColumn extends StatelessWidget {
  const _MenuColumn({
    required this.hubCockpitDark,
    required this.selectedIndex,
    required this.entries,
    required this.onDestinationSelected,
    this.nextRaceName,
    this.nextRaceDate,
  });

  final bool hubCockpitDark;
  final int selectedIndex;
  final List<F1HubMobileNavEntry> entries;
  final ValueChanged<int> onDestinationSelected;
  final String? nextRaceName;
  final DateTime? nextRaceDate;

  static const Color _menuAccent = ConstructorHubColors.railLogoRed;

  @override
  Widget build(BuildContext context) {
    // Explicit light/dark ink so labels never follow a mismatched [Theme].
    final muted = hubCockpitDark
        ? Colors.white.withValues(alpha: 0.72)
        : HubTheme.f1DeepCharcoal.withValues(alpha: 0.78);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 0, bottom: 12),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = entries[i];
              final selected = i == selectedIndex;
              final iconColor = selected ? _menuAccent : muted;
              final labelStyle = GoogleFonts.titilliumWeb(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: iconColor,
                height: 1.25,
              );
              return _NavRow(
                minHeight: 56,
                selected: selected,
                accent: _menuAccent,
                hubCockpitDark: hubCockpitDark,
                onTap: () => onDestinationSelected(i),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(
                            color: iconColor,
                            size: 22,
                          ),
                          child: selected ? e.selectedIcon : e.icon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        NextRaceHubMiniCard(
          raceName: nextRaceName,
          raceDate: nextRaceDate,
          lightForegroundOnDarkPanel: hubCockpitDark,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: HubLegalNavLink(
            hubCockpit: hubCockpitDark,
            compact: false,
          ),
        ),
      ],
    );
  }
}

class F1HubMobileNavEntry {
  const F1HubMobileNavEntry({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.minHeight,
    required this.selected,
    required this.accent,
    required this.hubCockpitDark,
    required this.onTap,
    required this.child,
  });

  final double minHeight;
  final bool selected;
  final Color accent;
  final bool hubCockpitDark;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;
    final scheme = Theme.of(context).colorScheme;

    final BoxDecoration decoration;
    if (hubCockpitDark) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: selected
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              )
            : null,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    ConstructorHubColors.surfaceElevated,
                    accent,
                    0.42,
                  )!,
                  ConstructorHubColors.surfaceElevated.withValues(alpha: 0.94),
                ],
              )
            : null,
        color: selected ? null : Colors.transparent,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      );
    } else {
      final high = scheme.surfaceContainerHigh;
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: selected
            ? Border.all(
                color: accent.withValues(alpha: 0.65),
                width: 1.1,
              )
            : null,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(high, accent, 0.26)!,
                  high.withValues(alpha: 0.96),
                ],
              )
            : null,
        color: selected ? null : Colors.transparent,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: decoration,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
