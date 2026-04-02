import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../display_settings.dart';
import '../display_settings_controller.dart';
import '../theme/f1_ui_theme.dart';
import '../theme/hub_list_card_style.dart';
import 'f1_module.dart';
import 'hub_interactive_glass.dart';

/// Shared glass / simple shell for Circuits, Driver standings, and Team rows.
///
/// Honors [DisplaySettings]: [UiMode], [DisplaySettings.compact] (via [HubListCardStyle.rowHeight]),
/// and [DisplaySettings.motionReduced] for [AnimatedContainer] duration.
class HubListRowShell extends StatelessWidget {
  const HubListRowShell({
    super.key,
    required this.child,
    this.onTap,
    this.selectionTint,
    this.selectionBorder,
  });

  /// Typically a [Row] with [CrossAxisAlignment.center].
  final Widget child;
  final VoidCallback? onTap;
  final Color? selectionTint;
  final Color? selectionBorder;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DisplaySettingsController>().settings;
    final f1Ui =
        Theme.of(context).extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final scheme = Theme.of(context).colorScheme;
    final standard = settings.uiMode == UiMode.standard;
    final h = HubListCardStyle.rowHeight(settings);
    final duration = HubListCardStyle.shellAnimationDuration(settings);
    final blur = f1Ui.glassBlur;
    final effectiveBlur = standard && blur > 0 ? blur * 0.42 : 0.0;

    final isDark = scheme.brightness == Brightness.dark;
    // Standard: fading stroke uses theme primary (or team color when selected).
    final fadingBorderColor = selectionBorder ?? scheme.primary;
    final simpleOutlineColor =
        selectionBorder ??
        scheme.outline.withValues(alpha: isDark ? 0.55 : 0.45);

    final shadows = standard ? f1Ui.moduleShadow : null;

    /// Matches desktop zomerstop calendar row: [F1Module] with
    /// `backgroundColor: ColorScheme.surface` (light/dark from theme).
    Color hubRowFill() => scheme.surface;

    Widget backdropFill() {
      final fill = hubRowFill();
      if (effectiveBlur > 0) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: ColoredBox(color: fill),
        );
      }
      return ColoredBox(color: fill);
    }

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      height: h,
      margin: const EdgeInsets.symmetric(
        horizontal: HubListCardStyle.shellHorizontalMargin,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HubListCardStyle.shellBorderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HubListCardStyle.shellBorderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: backdropFill()),
            if (selectionTint != null)
              Positioned.fill(
                child: IgnorePointer(child: Container(color: selectionTint)),
              ),
            Builder(
              builder: (context) {
                final padded = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HubListCardStyle.shellInnerPaddingH,
                  ),
                  child: SizedBox.expand(child: child),
                );
                if (onTap == null) {
                  return padded;
                }
                return Material(
                  color: Colors.transparent,
                  child: HubInteractiveGlass(
                    borderRadius: HubListCardStyle.shellBorderRadius,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(
                        HubListCardStyle.shellBorderRadius,
                      ),
                      child: padded,
                    ),
                  ),
                );
              },
            ),
            if (standard)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: FadingBorderPainter(
                      color: fadingBorderColor,
                      borderRadius: HubListCardStyle.shellBorderRadius,
                      borderWidth: kF1ModuleBorderWidth,
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        HubListCardStyle.shellBorderRadius,
                      ),
                      border: Border.all(color: simpleOutlineColor, width: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
