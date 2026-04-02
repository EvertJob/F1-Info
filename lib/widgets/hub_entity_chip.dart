import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';
import 'hub_interactive_glass.dart';

/// Glass legend chip for standings charts (drivers & constructors).
class HubEntityChip extends StatelessWidget {
  const HubEntityChip({
    required this.label,
    required this.teamColor,
    required this.active,
    this.onTap,
    this.labelMaxWidth,
    super.key,
  });

  final String label;
  final Color teamColor;
  final bool active;
  final VoidCallback? onTap;

  /// When set (e.g. horizontal legend strip), avoids unbounded [Row] width.
  final double? labelMaxWidth;

  static const double _height = 38;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final primary = HubTheme.primaryOnGlassText(context);

    Widget name = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.titilliumWeb(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: primary.withValues(alpha: active ? 1 : 0.55),
      ),
    );
    if (labelMaxWidth != null) {
      name = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: labelMaxWidth!),
        child: name,
      );
    } else {
      name = Expanded(child: name);
    }

    Widget glass = HubVisualLanguage.glassPanel(
      context: context,
      radius: _radius,
      legendChipDense: true,
      accentGlow: teamColor,
      accentGlowOpacity: active ? 0.11 : 0.04,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: _height,
        child: Row(
          mainAxisSize:
              labelMaxWidth != null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            name,
          ],
        ),
      ),
    );

    if (active) {
      glass = Stack(
        fit: StackFit.passthrough,
        children: [
          glass,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: teamColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  // Inner-only tint (no BoxShadow — avoids green halo outside radius).
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      teamColor.withValues(alpha: 0),
                      teamColor.withValues(alpha: 0.14),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return HubInteractiveGlass(
      borderRadius: _radius,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: glass,
      ),
    );
  }
}
