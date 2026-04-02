import 'dart:ui' as ui;

import 'package:f1/data/f1_asset_resolver.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/constructor_hub_theme.dart';
import 'package:f1/widgets/hub_glass_chart_loading.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _HubResolve {
  const _HubResolve.none() : venue = null, hasData = false;
  const _HubResolve({required this.venue, required this.hasData});

  final String? venue;
  final bool hasData;
}

/// Glass-style pill to open [WeekendHubScreen] via `/weekendhub/{venue}` when
/// bundled session JSON exists for [circuitAssetId] in any recent season.
class CircuitWeekendHubActionPill extends StatefulWidget {
  const CircuitWeekendHubActionPill({
    super.key,
    required this.circuitAssetId,
    required this.venueLabel,
  });

  final String circuitAssetId;
  final String venueLabel;

  @override
  State<CircuitWeekendHubActionPill> createState() =>
      _CircuitWeekendHubActionPillState();
}

class _CircuitWeekendHubActionPillState extends State<CircuitWeekendHubActionPill>
    with SingleTickerProviderStateMixin {
  Future<_HubResolve>? _future;
  bool _hover = false;
  bool _fadeScheduled = false;
  late final AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load(DefaultAssetBundle.of(context));
  }

  @override
  void didUpdateWidget(covariant CircuitWeekendHubActionPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circuitAssetId != widget.circuitAssetId) {
      _future = _load(DefaultAssetBundle.of(context));
      _fadeIn.reset();
    }
  }

  Future<_HubResolve> _load(AssetBundle bundle) async {
    final id = widget.circuitAssetId.trim();
    if (id.isEmpty) return const _HubResolve.none();
    final venue = F1AssetResolver.venueFolderForCircuitAssetId(id);
    if (venue == null) return const _HubResolve.none();
    final hasData = await F1AssetResolver.venueHasAnyBundledSessionResults(
      bundle: bundle,
      venueFolder: venue,
    );
    final hubSlug = F1AssetResolver.weekendHubPathSlug(venue);
    return _HubResolve(venue: hubSlug, hasData: hasData);
  }

  String _displayVenue(String bundleVenue) {
    final v = widget.venueLabel.trim();
    if (v.isNotEmpty) return v;
    return bundleVenue
        .split('_')
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w.substring(0, 1).toUpperCase()}${w.length > 1 ? w.substring(1) : ''}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<_HubResolve>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 10);
        }
        if (snap.hasError) {
          return const SizedBox.shrink();
        }
        final state = snap.data ?? const _HubResolve.none();
        if (state.venue == null) {
          return const SizedBox.shrink();
        }

        if (!_fadeScheduled) {
          _fadeScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fadeIn.forward();
          });
        }

        final enabled = state.hasData;
        final labelVenue = _displayVenue(state.venue!);
        final label = context.l10n.circuit_weekend_hub_go(labelVenue);
        final tooltipMessage = context.l10n.circuit_weekend_hub_no_data_tooltip;

        final baseFill = Color.lerp(
          Colors.white.withValues(alpha: isDark ? 0.11 : 0.28),
          scheme.primary.withValues(alpha: isDark ? 0.14 : 0.10),
          0.35,
        )!;
        final hoverFill = Color.lerp(
          Colors.white.withValues(alpha: isDark ? 0.20 : 0.42),
          scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
          0.4,
        )!;

        Widget pill = Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: MouseRegion(
          onEnter: (_) {
            if (enabled) setState(() => _hover = true);
          },
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
              boxShadow: _hover && enabled
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.42),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  color: enabled && _hover ? hoverFill : baseFill,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: enabled
                          ? () => context.push('/weekendhub/${state.venue}')
                          : null,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hub,
                              size: 19,
                              color: scheme.onSurface.withValues(
                                alpha: enabled ? 0.92 : 0.45,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  fontSize: 12.5,
                                  height: 1.2,
                                  color: scheme.onSurface.withValues(
                                    alpha: enabled ? 0.94 : 0.48,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        );

        if (!enabled) {
          pill = Tooltip(
            message: tooltipMessage,
            waitDuration: const Duration(milliseconds: 350),
            child: pill,
          );
        }

        pill = Opacity(
          opacity: enabled ? 1.0 : 0.52,
          child: pill,
        );

        return FadeTransition(
          opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeOutCubic),
          child: Center(child: pill),
        );
      },
    );
  }
}

/// Compact F1-red pill for the circuit JSON hero (opens `/weekendhub/{slug}` when data exists).
class CircuitWeekendHubHeroPill extends StatefulWidget {
  const CircuitWeekendHubHeroPill({
    super.key,
    required this.circuitAssetId,
  });

  final String circuitAssetId;

  @override
  State<CircuitWeekendHubHeroPill> createState() =>
      _CircuitWeekendHubHeroPillState();
}

class _CircuitWeekendHubHeroPillState extends State<CircuitWeekendHubHeroPill> {
  Future<_HubResolve>? _future;
  bool _hover = false;

  /// Matches [_F1NavTile] selected row radius (hub rail / Kalender).
  static const double _kRailSelectedRadius = 12;

  /// Same glass + gradient language as desktop hub rail selected tile (Kalender, …).
  BoxDecoration _weekendHubHeroPillDecoration(
    BuildContext context, {
    required bool isDark,
    required bool hovered,
  }) {
    final red = ConstructorHubColors.railLogoRed;
    final r = BorderRadius.circular(_kRailSelectedRadius);
    if (isDark) {
      return BoxDecoration(
        borderRadius: r,
        border: Border.all(
          color: Colors.white.withValues(alpha: hovered ? 0.22 : 0.12),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              ConstructorHubColors.surfaceElevated,
              red,
              hovered ? 0.5 : 0.42,
            )!,
            ConstructorHubColors.surfaceElevated.withValues(alpha: 0.94),
          ],
        ),
      );
    }
    return BoxDecoration(
      borderRadius: r,
      border: Border.all(
        color: Colors.black.withValues(alpha: hovered ? 0.10 : 0.06),
        width: HubVisualLanguage.glassBorderWidth,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            Colors.white.withValues(alpha: 0.82),
            red,
            hovered ? 0.20 : 0.14,
          )!,
          Colors.white.withValues(alpha: 0.52),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load(DefaultAssetBundle.of(context));
  }

  @override
  void didUpdateWidget(covariant CircuitWeekendHubHeroPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circuitAssetId != widget.circuitAssetId) {
      _future = _load(DefaultAssetBundle.of(context));
    }
  }

  Future<_HubResolve> _load(AssetBundle bundle) async {
    final id = widget.circuitAssetId.trim();
    if (id.isEmpty) return const _HubResolve.none();
    final venue = F1AssetResolver.venueFolderForCircuitAssetId(id);
    if (venue == null) return const _HubResolve.none();
    final hasData = await F1AssetResolver.venueHasAnyBundledSessionResults(
      bundle: bundle,
      venueFolder: venue,
    );
    final hubSlug = F1AssetResolver.weekendHubPathSlug(venue);
    return _HubResolve(venue: hubSlug, hasData: hasData);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<_HubResolve>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 44,
            height: 38,
            child: Center(
              child: HubGlassInlineLoadingPlaceholder(width: 20, height: 20),
            ),
          );
        }
        if (snap.hasError) {
          return const SizedBox.shrink();
        }
        final state = snap.data ?? const _HubResolve.none();
        if (state.venue == null) {
          return const SizedBox.shrink();
        }

        final enabled = state.hasData;
        final tooltipMessage = l10n.circuit_weekend_hub_no_data_tooltip;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final red = ConstructorHubColors.railLogoRed;

        Widget rowContent(Color fg) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.flag_rounded, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                l10n.weekend_hub,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                  height: 1.0,
                  color: fg,
                ),
              ),
            ],
          );
        }

        Widget pill;
        if (!enabled) {
          final fg = red.withValues(alpha: 0.45);
          pill = Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(_kRailSelectedRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
                color: isDark
                    ? ConstructorHubColors.surface.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: rowContent(fg),
              ),
            ),
          );
          pill = Tooltip(
            message: tooltipMessage,
            waitDuration: const Duration(milliseconds: 350),
            child: pill,
          );
        } else {
          final fg = red;
          pill = MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/weekendhub/${state.venue}'),
                borderRadius:
                    BorderRadius.circular(_kRailSelectedRadius),
                splashColor: red.withValues(alpha: 0.12),
                highlightColor: red.withValues(alpha: 0.06),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(_kRailSelectedRadius),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: HubVisualLanguage.glassBlurSigma,
                      sigmaY: HubVisualLanguage.glassBlurSigma,
                    ),
                    child: DecoratedBox(
                      decoration: _weekendHubHeroPillDecoration(
                        context,
                        isDark: isDark,
                        hovered: _hover,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: rowContent(fg),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return pill;
      },
    );
  }
}
