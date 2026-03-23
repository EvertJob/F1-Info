import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/f1_theme_tokens.dart';
import '../theme/f1_ui_theme.dart';
import '../utils/l10n_extension.dart';
import 'f1_module.dart';

/// Project-wide horizontal inset for shell content and the app header, before
/// safe-area sides (see [f1HubShellHorizontalPadding]).
const double kF1HubContentHorizontalInset = 16;

/// Symmetric horizontal padding: [kF1HubContentHorizontalInset] plus the
/// larger of [MediaQuery.padding] and [MediaQuery.viewPadding] on each side
/// (landscape notch, Dynamic Island, edge-to-edge).
EdgeInsets f1HubShellHorizontalPadding(BuildContext context) {
  final pad = MediaQuery.paddingOf(context);
  final viewPad = MediaQuery.viewPaddingOf(context);
  final left = kF1HubContentHorizontalInset +
      math.max(pad.left, viewPad.left);
  final right = kF1HubContentHorizontalInset +
      math.max(pad.right, viewPad.right);
  return EdgeInsets.fromLTRB(left, 0, right, 0);
}

double _f1HubTitleFontSize(double width) {
  if (width < 360) return 19;
  if (width < 480) return 21;
  if (width < 600) return 22;
  if (width < 900) return 24;
  if (width < 1200) return 26;
  return 27;
}

double _f1HubTitleVerticalPadding(double width) {
  if (width < 600) return 10;
  if (width < 900) return 11;
  return 12;
}

double _f1HubHeaderTopInset(
  BuildContext context, {
  required bool isDesktopLayout,
}) {
  final top = MediaQuery.paddingOf(context).top;
  if (isDesktopLayout) {
    return 8;
  }
  return top;
}

/// Persistent glass / flat title bar matching [NavigationRail] and
/// [BottomNavigationBar] via [F1UiTheme].
class F1HubAppHeader extends StatelessWidget {
  const F1HubAppHeader({
    required this.isDesktopLayout,
    this.trailing,
    super.key,
  });

  /// When true, the parent shell already applies [SafeArea]; only a small top
  /// gap is used so the bar stays compact on desktop and tablet rail layouts.
  final bool isDesktopLayout;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Phone: no grey title pill — keeps status-bar inset + spacing below.
    if (!isDesktopLayout) {
      final top = MediaQuery.paddingOf(context).top;
      return Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: const SizedBox.shrink(),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final f1Ui =
        Theme.of(context).extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final tokens = Theme.of(context).extension<F1ThemeTokens>();
    final panelStrong = tokens?.panelStrong ?? scheme.surfaceContainerHighest;
    final outlineColor =
        tokens?.outline.withValues(alpha: 0.7) ??
        Colors.grey.withValues(alpha: 0.7);
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = _f1HubTitleFontSize(width);
    final innerV = _f1HubTitleVerticalPadding(width);
    final topInset = _f1HubHeaderTopInset(
      context,
      isDesktopLayout: isDesktopLayout,
    );
    final radius = BorderRadius.circular(f1Ui.cardBorderRadius);
    final fill = f1Ui.glassBlur > 0
        ? panelStrong.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.42
                : 0.55,
          )
        : panelStrong;

    final title = Text(
      context.l10n.app_title.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'TitilliumWeb',
        fontSize: titleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1 + titleSize * 0.02,
        height: 1.05,
        color: scheme.onSurface,
      ),
    );

    Widget bar = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: innerV, horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: outlineColor, width: 1.2),
        boxShadow: f1Ui.moduleShadow,
      ),
      child: trailing == null
          ? title
          : Row(
              children: [
                Expanded(child: title),
                trailing!,
              ],
            ),
    );

    if (f1Ui.glassBlur > 0) {
      bar = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: f1Ui.glassBlur,
            sigmaY: f1Ui.glassBlur,
          ),
          child: bar,
        ),
      );
    } else {
      bar = ClipRRect(borderRadius: radius, child: bar);
    }

    if (f1Ui.showFadingBorder) {
      bar = Stack(
        clipBehavior: Clip.none,
        children: [
          bar,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FadingBorderPainter(
                  color: scheme.primary,
                  borderRadius: f1Ui.cardBorderRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topInset, bottom: 8),
      child: bar,
    );
  }
}
