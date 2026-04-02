import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hub_theme.dart';
import 'hub_visual_language.dart';

/// Blurred dark scrim + centered dialog (replaces default [showDialog] barrier).
Future<T?> hubShowDialogWithBlurBarrier<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    useRootNavigator: true,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: curved,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible ? () => Navigator.of(ctx).pop() : null,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: HubVisualLanguage.dialogBarrierBlurSigma,
                  sigmaY: HubVisualLanguage.dialogBarrierBlurSigma,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// Modal bottom sheet with σ=15 blur barrier (transparent framework barrier).
Future<T?> hubShowModalBottomSheetWithBlurBarrier<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    barrierColor: Colors.transparent,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(ctx).pop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: HubVisualLanguage.dialogBarrierBlurSigma,
                sigmaY: HubVisualLanguage.dialogBarrierBlurSigma,
              ),
              child: Container(
                color: HubTheme.isDark(ctx)
                    ? Colors.black.withValues(alpha: 0.48)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          builder(ctx),
        ],
      );
    },
  );
}
