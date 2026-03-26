import 'dart:ui' as ui;

import 'package:f1/circuit_detail/circuit_data.dart';
import 'package:f1/circuit_detail/circuit_detail_formatting.dart';
import 'package:f1/circuit_detail/circuit_icon_mapper.dart';
import 'package:f1/circuit_detail/circuit_l10n_resolver.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/l10n/app_localizations.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

/// Scrollable glassmorphism dashboard for [CircuitData] category cards.
///
/// Expects an ancestor [Provider] / `Provider.value` for [DisplaySettingsController]
/// (same as the rest of the app) so blur can respect reduced motion.
class CircuitDetailView extends StatelessWidget {
  const CircuitDetailView({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
    this.showTitleHeader = true,
    this.onOpenInMaps,
  });

  final CircuitData data;
  final EdgeInsets padding;

  /// When false, only [data.location] context in cards is shown (e.g. [AppBar] shows [CircuitData.name]).
  final bool showTitleHeader;

  /// When non-null, shows a localized **Open in Maps** action (expects lat/lon on [CircuitData]).
  final VoidCallback? onOpenInMaps;

  static int columnCountForWidth(double width) {
    if (width >= 1100) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final columns = columnCountForWidth(width);
    final f1 = Theme.of(context).extension<F1UiTheme>();
    final radius = f1?.cardBorderRadius ?? 20;
    final motionReduced = context.select<DisplaySettingsController, bool>(
      (c) => c.motionReduced,
    );
    final blurSigma = motionReduced ? 0.0 : 10.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child:
                showTitleHeader
                    ? _CircuitHeader(name: data.name, location: data.location)
                    : _CircuitSubheader(location: data.location),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            0,
            padding.right,
            8,
          ),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: data.categories.length,
            itemBuilder: (context, index) {
              final cat = data.categories[index];
              return _GlassCategoryCard(
                title: circuitLocalizedString(l10n, cat.labelL10n),
                iconData: circuitCategoryIcon(cat.icon),
                dataPoints: cat.dataPoints,
                borderRadius: radius,
                blurSigma: blurSigma,
              );
            },
          ),
        ),
        if (data.characteristics != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              8,
              padding.right,
              padding.bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: _CharacteristicsGlassCard(
                l10n: l10n,
                ch: data.characteristics!,
                borderRadius: radius,
                blurSigma: blurSigma,
              ),
            ),
          ),
        if (onOpenInMaps != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              4,
              padding.right,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: FilledButton.icon(
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
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: padding.bottom),
        ),
      ],
    );
  }
}

class _CircuitSubheader extends StatelessWidget {
  const _CircuitSubheader({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    if (location.isEmpty) {
      return const SizedBox(height: 4);
    }
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.25,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        location,
        textScaler: scale,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CircuitHeader extends StatelessWidget {
  const _CircuitHeader({required this.name, required this.location});

  final String name;
  final String location;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.25,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            textScaler: scale,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            textScaler: scale,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCategoryCard extends StatelessWidget {
  const _GlassCategoryCard({
    required this.title,
    required this.iconData,
    required this.dataPoints,
    required this.borderRadius,
    required this.blurSigma,
  });

  final String title;
  final IconData iconData;
  final Map<String, dynamic> dataPoints;
  final double borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final scale = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.88,
      maxScaleFactor: 1.3,
    );

    final entries = dataPoints.entries.toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (blurSigma > 0)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.14 : 0.52),
                  Colors.white.withValues(alpha: isDark ? 0.07 : 0.32),
                  Color(0xFFE3F2FD).withValues(alpha: isDark ? 0.08 : 0.28),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.72),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        iconData,
                        size: 22,
                        color: const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          textScaler: scale,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _DataPointRow(
                      fieldKey: entries[i].key,
                      value: entries[i].value,
                      l10n: l10n,
                      scale: scale,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

class _CharacteristicsGlassCard extends StatelessWidget {
  const _CharacteristicsGlassCard({
    required this.l10n,
    required this.ch,
    required this.borderRadius,
    required this.blurSigma,
  });

  final AppLocalizations l10n;
  final CircuitCharacteristics ch;
  final double borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final scale = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.88,
      maxScaleFactor: 1.3,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (blurSigma > 0)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.14 : 0.52),
                  Colors.white.withValues(alpha: isDark ? 0.07 : 0.32),
                  Color(0xFFE3F2FD).withValues(alpha: isDark ? 0.08 : 0.28),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.72),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_circle_outlined,
                        size: 22,
                        color: const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.characteristics,
                          textScaler: scale,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final key in ch.keyFeaturesL10n)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: const Color(0xFF1565C0).withValues(
                              alpha: 0.85,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              circuitLocalizedString(l10n, key),
                              textScaler: scale,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.92,
                                    ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.95,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
