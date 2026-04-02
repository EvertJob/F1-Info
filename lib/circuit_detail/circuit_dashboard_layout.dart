import 'package:f1/theme/hub_theme.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/material.dart';

/// Same breakpoint as [MainNavigation] shell (see `main.dart`).
const double kCircuitDashboardDesktopShellBreakpoint = 600;

/// Paints subtle radial blooms at top-left and bottom-right (matches driver/team detail).
class CircuitAmbientGlowPainter extends CustomPainter {
  CircuitAmbientGlowPainter({
    required this.topLeftGlow,
    required this.bottomRightGlow,
  });

  final Color topLeftGlow;
  final Color bottomRightGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.45,
      colors: [topLeftGlow, Colors.transparent],
    );
    final bottomRight = RadialGradient(
      center: Alignment.bottomRight,
      radius: 1.45,
      colors: [bottomRightGlow, Colors.transparent],
    );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = topLeft.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = bottomRight.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CircuitAmbientGlowPainter old) =>
      topLeftGlow != old.topLeftGlow || bottomRightGlow != old.bottomRightGlow;
}

/// F1 red for category icons on the circuit JSON hub (reference: dark cards + red accents).
const Color kCircuitHubHeaderIconRed = Color(0xFFE10600);

/// [F1Module] + themed [ExpansionTile] shell (flat card: same fill + hairline border as hub detail).
Widget circuitDashboardSectionCard(
  BuildContext context, {
  required Widget child,
  bool hubAccordionStyle = false,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final hubDark = hubAccordionStyle && theme.brightness == Brightness.dark;
  final isLight = theme.brightness == Brightness.light;
  final accentColor = scheme.primary;
  final titleColor = hubDark
      ? scheme.onSurface.withValues(alpha: 0.98)
      : (isLight ? HubTheme.f1DeepCharcoal : scheme.primary);
  final moduleBg = hubDark
      ? const Color(0xFF121212)
      : (isLight ? Colors.white : scheme.surface);
  final chevronHub = scheme.onSurface.withValues(alpha: 0.92);

  final module = F1Module(
    fillWidth: true,
    padding: EdgeInsets.zero,
    borderRadius: kF1ModuleRadius,
    backgroundColor: moduleBg,
    showFadingBorder: !hubDark && !isLight,
    child: Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          textColor: titleColor,
          collapsedTextColor: titleColor,
          iconColor: hubDark ? chevronHub : accentColor,
          collapsedIconColor: hubDark
              ? chevronHub.withValues(alpha: 0.72)
              : accentColor.withValues(alpha: 0.9),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide.none,
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide.none,
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        ),
      ),
      child: child,
    ),
  );

  if (hubDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kF1ModuleRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: module,
    );
  }
  if (isLight) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kF1ModuleRadius),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: module,
    );
  }
  return module;
}

/// Distributes [sections] across up to three columns (matches `_buildResponsiveSections`).
Widget buildCircuitDashboardColumns({
  required List<Widget> sections,
  double breakpoint = 601,
  double spacing = 16,
  double minColumnWidth = 320,
  int maxColumns = 3,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      Widget buildSectionColumn(List<Widget> columnSections) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int index = 0; index < columnSections.length; index++) ...[
              columnSections[index],
              if (index != columnSections.length - 1) SizedBox(height: spacing),
            ],
          ],
        );
      }

      if (constraints.maxWidth > breakpoint) {
        final availableWidth = constraints.maxWidth;
        final estimatedColumns =
            ((availableWidth + spacing) / (minColumnWidth + spacing)).floor();
        final columnCount = estimatedColumns.clamp(2, maxColumns);
        final distributedSections = List.generate(columnCount, (_) => <Widget>[]);

        for (int index = 0; index < sections.length; index++) {
          distributedSections[index % columnCount].add(sections[index]);
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (
                int index = 0;
                index < distributedSections.length;
                index++
              ) ...[
                Expanded(child: buildSectionColumn(distributedSections[index])),
                if (index != distributedSections.length - 1)
                  SizedBox(width: spacing),
              ],
            ],
          ),
        );
      }

      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: buildSectionColumn(sections),
      );
    },
  );
}
