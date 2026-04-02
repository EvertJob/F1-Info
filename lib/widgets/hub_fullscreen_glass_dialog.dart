import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';

/// Full-screen style dialog: dark **blurred** barrier + large [HubVisualLanguage.glassPanel].
Future<T?> showHubFullscreenGlassDialog<T>({
  required BuildContext context,
  required Widget body,
  Color? topAccent,
}) {
  final accent = topAccent ?? HubVisualLanguage.f1DefaultAccent;
  final barrierLabel =
      MaterialLocalizations.of(context).modalBarrierDismissLabel;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(dialogContext);
      final maxW = size.width * 0.94;
      final maxH = size.height * 0.92;
      final closeTip =
          MaterialLocalizations.of(dialogContext).closeButtonTooltip;

      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: HubVisualLanguage.dialogBarrierBlurSigma,
                  sigmaY: HubVisualLanguage.dialogBarrierBlurSigma,
                ),
                child: Container(
                  color: HubTheme.isDark(dialogContext)
                      ? Colors.black.withValues(alpha: 0.48)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(8),
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxW,
                      maxHeight: maxH,
                    ),
                    child: HubVisualLanguage.glassPanel(
                      context: dialogContext,
                      topAccent: accent,
                      accentGlow: accent,
                      accentGlowOpacity: 0.09,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              tooltip: closeTip,
                              style: HubMobileTuning.iconButtonTouchTarget(
                                dialogContext,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 26),
                              color: HubTheme.iconOnGlass(dialogContext),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
