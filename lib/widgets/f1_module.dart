import 'package:flutter/material.dart';

/// Border radius used consistently across all F1 modules.
const double kF1ModuleRadius = 20;

/// Default border width for the fading perimeter.
const double kF1ModuleBorderWidth = 2;

/// CustomPainter that draws a perimeter border fading from [color] at top-left
/// to transparent at 50% of the module's width. Follows [borderRadius] rounded corners.
/// Uses theme.colorScheme.primary for dynamic team color updates via ThemeController.
class FadingBorderPainter extends CustomPainter {
  FadingBorderPainter({
    required this.color,
    this.borderRadius = kF1ModuleRadius,
    this.borderWidth = kF1ModuleBorderWidth,
  });

  final Color color;
  final double borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [color, Colors.transparent],
      stops: const [0.0, 0.5],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Inset path so stroke stays fully inside the module bounds
    final inset = borderWidth / 2;
    final innerRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final innerRadius = (borderRadius - inset).clamp(0.0, double.infinity);
    final rrect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(innerRadius),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(FadingBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius ||
      borderWidth != oldDelegate.borderWidth;
}

/// Universal F1 module wrapper: surfaceContainerLow background, 20px radius,
/// fading perimeter border (primary → transparent at 50% width).
/// Replaces the legacy 3px vertical team stripe across Sidebar, Standings,
/// Race Cards, Dashboard Cards, Weekend Hub, Race Control, and Penalties.
///
/// Theme integrity: Uses [Theme.of(context).colorScheme.primary], which updates
/// dynamically when [ThemeController] changes (e.g. Red Bull → Ferrari).
class F1Module extends StatelessWidget {
  const F1Module({
    required this.child,
    super.key,
    this.padding,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.fillWidth = false,
    this.boxShadow,
    this.showFadingBorder = true,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? borderWidth;
  final Color? backgroundColor;
  final bool fillWidth;
  final List<BoxShadow>? boxShadow;
  /// When false, omits the primary-color fading perimeter (for cards that should
  /// match the calendar grid styling).
  final bool showFadingBorder;
  /// Override for the fading border color (e.g. team color for driver cards).
  /// When null, uses [Theme.colorScheme.primary].
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? kF1ModuleRadius;
    final bg = backgroundColor ?? scheme.surfaceContainerLow;
    final border = borderColor ?? scheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: fillWidth ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
        if (showFadingBorder)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FadingBorderPainter(
                  color: border,
                  borderRadius: radius,
                  borderWidth: borderWidth ?? kF1ModuleBorderWidth,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
