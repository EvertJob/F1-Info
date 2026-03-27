import 'package:f1/circuit_detail/circuit_dashboard_layout.dart';
import 'package:f1/circuit_detail/circuit_data.dart';
import 'package:f1/circuit_detail/circuit_detail_formatting.dart';
import 'package:f1/circuit_detail/circuit_icon_mapper.dart';
import 'package:f1/circuit_detail/circuit_l10n_resolver.dart';
import 'package:f1/detail_expansion_prefs_service.dart';
import 'package:f1/l10n/app_localizations.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Circuit JSON hub: same visual language as driver/team detail (ambient shell,
/// three-column accordion sections, white [F1Module] cards).
class CircuitDetailView extends StatelessWidget {
  const CircuitDetailView({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 28),
    this.showTitleHeader = true,
    this.onOpenInMaps,
    /// When [false], top padding skips app-bar inset (e.g. below [CircuitEmbeddedMap]).
    this.useAppBarTopInset = true,
    /// Centered under the location line (e.g. weekend hub action pill).
    this.belowLocationAction,
  });

  final CircuitData data;
  final EdgeInsets padding;
  final bool showTitleHeader;
  final VoidCallback? onOpenInMaps;

  /// When a transparent [AppBar] sits above this body (full-page JSON circuit).
  final bool useAppBarTopInset;

  final Widget? belowLocationAction;

  static int columnCountForWidth(double width) {
    if (width >= 1100) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  double _listTopPadding(BuildContext context) {
    final desktopShell =
        MediaQuery.sizeOf(context).width >= kCircuitDashboardDesktopShellBreakpoint;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    if (!useAppBarTopInset) {
      return padding.top;
    }
    return desktopShell ? padding.top : topInset + padding.top;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final expPrefs = context.watch<DetailExpansionPrefsNotifier>();
    final desktopShell =
        MediaQuery.sizeOf(context).width >= kCircuitDashboardDesktopShellBreakpoint;
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;

    final scale = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.88,
      maxScaleFactor: 1.3,
    );

    const characteristicsSectionId = 'circuit_json_characteristics';

    final sectionWidgets = <Widget>[];

    for (var i = 0; i < data.categories.length; i++) {
      final cat = data.categories[i];
      final sectionId = cat.categoryId.isNotEmpty ? cat.categoryId : 'category_$i';
      final titleText = circuitLocalizedString(l10n, cat.labelL10n);
      final entries = cat.dataPoints.entries.toList(growable: false);

      sectionWidgets.add(
        circuitDashboardSectionCard(
          context,
          child: ExpansionTile(
            initiallyExpanded: expPrefs.initiallyExpanded(
              DetailExpansionCat.circuitJson,
              sectionId,
              i < 2,
            ),
            onExpansionChanged: (v) => expPrefs.setExpanded(
              DetailExpansionCat.circuitJson,
              sectionId,
              v,
            ),
            title: Row(
              children: [
                Icon(
                  circuitCategoryIcon(cat.icon),
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              for (var j = 0; j < entries.length; j++) ...[
                if (j > 0) const SizedBox(height: 8),
                _DataPointRow(
                  fieldKey: entries[j].key,
                  value: entries[j].value,
                  l10n: l10n,
                  scale: scale,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (data.characteristics != null) {
      final ch = data.characteristics!;
      sectionWidgets.add(
        circuitDashboardSectionCard(
          context,
          child: ExpansionTile(
            initiallyExpanded: expPrefs.initiallyExpanded(
              DetailExpansionCat.circuitJson,
              characteristicsSectionId,
              false,
            ),
            onExpansionChanged: (v) => expPrefs.setExpanded(
              DetailExpansionCat.circuitJson,
              characteristicsSectionId,
              v,
            ),
            title: Row(
              children: [
                Icon(Icons.flag_circle_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.characteristics,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              for (final key in ch.keyFeaturesL10n)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.primary.withValues(alpha: 0.85),
                      ),
                      Expanded(
                        child: Text(
                          circuitLocalizedString(l10n, key),
                          textScaler: scale,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.92),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (ch.fullThrottlePct != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        l10n.circuit_stat_full_throttle,
                        textScaler: scale,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${ch.fullThrottlePct}%',
                        textAlign: TextAlign.end,
                        textScaler: scale,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    final displayName =
        data.name.isNotEmpty ? data.name : data.circuitId;
    final titleFontSize = showTitleHeader ? 32.0 : 26.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!desktopShell)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: shellBase),
              child: CustomPaint(
                painter: CircuitAmbientGlowPainter(
                  topLeftGlow: ambientGlow,
                  bottomRightGlow: ambientGlow,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              _listTopPadding(context),
              padding.right,
              padding.bottom,
            ),
            children: [
              Text(
                displayName,
                textAlign: TextAlign.center,
                textScaler: scale,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  letterSpacing: -0.5,
                  fontSize: titleFontSize,
                ),
              ),
              if (data.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.location,
                  textAlign: TextAlign.center,
                  textScaler: scale,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (belowLocationAction != null) ...[
                SizedBox(height: data.location.isNotEmpty ? 14 : 10),
                belowLocationAction!,
              ],
              const SizedBox(height: 20),
              KeyedSubtree(
                key: ValueKey('circuit-json-sections-${expPrefs.loadedRevision}'),
                child: buildCircuitDashboardColumns(sections: sectionWidgets),
              ),
              if (onOpenInMaps != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onOpenInMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.circuit_open_in_maps),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DataPointRow extends StatelessWidget {
  const _DataPointRow({
    required this.fieldKey,
    required this.value,
    required this.l10n,
    required this.scale,
  });

  final String fieldKey;
  final dynamic value;
  final AppLocalizations l10n;
  final TextScaler scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = labelForDataField(l10n, fieldKey);
    final isNested =
        (value is Map && !isRecordRow(fieldKey, value)) || value is List;

    if (value is Map && isRecordRow(fieldKey, value)) {
      final m = value;
      final (primary, subtitle) = recordPrimaryAndSubtitle(m);
      final subColor = scheme.onSurface.withValues(alpha: 0.62);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              textScaler: scale,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  primary,
                  textAlign: TextAlign.end,
                  textScaler: scale,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.98),
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.end,
                    textScaler: scale,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subColor,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final text = formatDataPointValue(l10n, fieldKey, value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            textScaler: scale,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              height: isNested ? 1.35 : 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 3,
          child: Text(
            text,
            textAlign: TextAlign.end,
            textScaler: scale,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
              height: isNested ? 1.4 : 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
