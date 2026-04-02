import 'package:f1/theme/f1_theme_tokens.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/theme/hub_mobile_tuning.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/constructor_hub_theme.dart';
import 'package:flutter/material.dart';

/// Narrow-hub top bar: **F1 HUB** + trailing ☰ / ✕.
///
/// Uses a **solid opaque** background (no [BackdropFilter], no translucent fill).
/// Semi-transparent “glass” + [Stack] layers caused invisible foreground text/icons
/// on Flutter web in this shell; parity with the closed state is more important
/// than blur on this strip.
///
/// Sits above the content [Stack] in [MainNavigation] so layout survives menu open.
class F1HubMobileGlassAppBar extends StatelessWidget {
  const F1HubMobileGlassAppBar({
    super.key,
    required this.onMenuPressed,
    this.hubCockpitDark = false,
    this.navMenuOpen = false,
    this.onNavMenuClose,
  });

  final VoidCallback onMenuPressed;
  final bool hubCockpitDark;
  final bool navMenuOpen;
  final VoidCallback? onNavMenuClose;

  static const Color _lightInk = Color(0xFF0A0A0A);
  static const Color _darkInk = Color(0xFFFFFFFF);

  /// Vertical space to pad body content so it clears this bar (floating in [Stack]).
  static double reservedHeight(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // SafeArea top + padding (6+10) + ~44 icon row
    return top + 56;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<F1ThemeTokens>();

    // Opaque: avoids web compositing bugs with blur + same luminance as glyphs.
    final Color barBg = hubCockpitDark
        ? ConstructorHubColors.surface
        : (tokens?.panelStrong ?? scheme.surfaceContainerHighest).withValues(
            alpha: 1,
          );

    final Color ink = hubCockpitDark ? _darkInk : _lightInk;

    // Do not use inherit:false + ad-hoc fontFamily on web (glyphs can fail to paint).
    final titleStyle = (theme.textTheme.titleLarge ?? theme.textTheme.bodyLarge!)
        .copyWith(
      color: ink,
      fontSize: 20 * HubMobileTuning.f1WideFontScale(context),
      fontWeight: FontWeight.w800,
      letterSpacing: HubVisualLanguage.letterSpacingF1Wide,
      height: 1.05,
    );

    final f1Ui = theme.extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final boxShadow = hubCockpitDark
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: f1Ui.glassBlur > 0 ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ];

    final title = context.l10n.app_title.trim().toUpperCase();
    final titleText = title.isEmpty ? 'F1 HUB' : title;

    return Material(
      color: barBg,
      elevation: hubCockpitDark ? 2 : 0,
      shadowColor: Colors.black26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: barBg,
          boxShadow: boxShadow,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                IconButton(
                  tooltip: navMenuOpen
                      ? MaterialLocalizations.of(context).closeButtonTooltip
                      : context.l10n.hub_nav_menu,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      HubMobileTuning.minTouchTarget,
                      HubMobileTuning.minTouchTarget,
                    ),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    foregroundColor: ink,
                  ),
                  onPressed: navMenuOpen && onNavMenuClose != null
                      ? onNavMenuClose
                      : onMenuPressed,
                  icon: Icon(
                    navMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                    color: ink,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
