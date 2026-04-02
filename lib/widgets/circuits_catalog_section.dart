import 'package:f1/circuit_detail/circuit_card_metrics.dart';
import 'package:f1/theme/hub_theme.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/constructor_hub_theme.dart';
import 'package:f1/widgets/hub_glass_chart_loading.dart';
import 'package:f1/widgets/hub_interactive_glass.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Circuits grid (length, laps, top speed from JSON, type, lap record) like the web hub.
class CircuitsCatalogSection extends StatefulWidget {
  const CircuitsCatalogSection({
    super.key,
    required this.races,
    this.desktopBreakpoint = 700,
    this.searchField,
    this.emptyFilterMessage,
    this.catalogSeasonYear,
  });

  final List<CircuitCatalogRaceInput> races;
  final double desktopBreakpoint;

  /// Hub glass field or light [TextField]; placed under the season subtitle.
  final Widget? searchField;

  /// When [races] is empty (filtered), show this under the search bar.
  final String? emptyFilterMessage;

  /// Season year for the subtitle when [races] is empty (e.g. active filter).
  final int? catalogSeasonYear;

  @override
  State<CircuitsCatalogSection> createState() => _CircuitsCatalogSectionState();
}

class _CircuitsCatalogSectionState extends State<CircuitsCatalogSection> {
  List<CircuitCardMetrics>? _rows;
  Object? _loadError;
  bool _loadInFlight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startLoadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CircuitsCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.races != widget.races) {
      _rows = null;
      _loadError = null;
      _loadInFlight = false;
      _startLoadIfNeeded();
    }
  }

  void _startLoadIfNeeded() {
    if (_loadInFlight || _rows != null || _loadError != null) return;
    final races = widget.races;
    if (races.isEmpty) {
      setState(() => _rows = []);
      return;
    }

    final bundle = DefaultAssetBundle.of(context);
    _loadInFlight = true;
    Future(() async {
      try {
        final out = <CircuitCardMetrics>[];
        for (final race in races) {
          final id = race.circuitAssetId.trim();
          if (id.isEmpty) {
            out.add(CircuitCardMetrics.fromRaceInput(race));
            continue;
          }
          try {
            final raw = await bundle.loadString('assets/data/circuits/$id.json');
            out.add(CircuitCardMetrics.fromJsonString(raw, race));
          } catch (_) {
            out.add(CircuitCardMetrics.fromRaceInput(race));
          }
        }
        if (!mounted) return;
        setState(() {
          _rows = out;
          _loadInFlight = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loadError = e;
          _loadInFlight = false;
        });
      }
    });
  }

  String _trackTypeLabel(BuildContext context, String? key) {
    if (key == null || key.isEmpty) return '';
    final l10n = context.l10n;
    switch (key) {
      case 'type_street_circuit':
        return l10n.type_street_circuit;
      case 'type_permanent_circuit':
        return l10n.type_permanent_circuit;
      default:
        return key;
    }
  }

  void _openCircuit(CircuitCatalogRaceInput race) {
    final id = race.circuitAssetId.trim();
    if (id.isNotEmpty) {
      context.push('/circuits/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final races = widget.races;
    final seasonYear = races.isNotEmpty
        ? races.first.calendarYear
        : (widget.catalogSeasonYear ?? DateTime.now().year);

    List<Widget> buildHeader(int count) => [
          Text(
            context.l10n.circuits,
            style: HubVisualLanguage.f1Wide(
              context,
              fontSize: 26,
              color: HubTheme.primaryOnGlassText(context),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.circuits_catalog_season_subtitle(
              count,
              seasonYear,
            ),
            style: HubVisualLanguage.titilliumSecondary(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: HubTheme.primaryOnGlassText(context),
              opacity: 0.62,
            ),
          ),
          if (widget.searchField != null) ...[
            const SizedBox(height: 12),
            widget.searchField!,
          ],
          const SizedBox(height: 18),
        ];

    if (races.isEmpty) {
      if (widget.emptyFilterMessage == null) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...buildHeader(0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                widget.emptyFilterMessage!,
                textAlign: TextAlign.center,
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...buildHeader(races.length),
        if (_loadError != null)
          Text(
            context.l10n.circuits_catalog_load_error,
            style: TextStyle(color: scheme.error),
          )
        else if (_rows == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: HubGlassPageLoadingPlaceholder(fixedHeight: 88),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final maxW = constraints.maxWidth;
              final rows = _rows!;
              final int columnCount = maxW >= widget.desktopBreakpoint ? 2 : 1;

              if (columnCount == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < races.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < races.length - 1 ? gap : 0,
                        ),
                        child: _CircuitCatalogCard(
                          race: races[i],
                          metrics: rows[i],
                          trackTypeLabel: _trackTypeLabel(
                            context,
                            rows[i].trackTypeL10nKey,
                          ),
                          onTap: () => _openCircuit(races[i]),
                        ),
                      ),
                  ],
                );
              }

              final inner =
                  (maxW - gap * (columnCount - 1)) / columnCount;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < races.length; i++)
                    SizedBox(
                      width: inner,
                      child: _CircuitCatalogCard(
                        race: races[i],
                        metrics: rows[i],
                        trackTypeLabel: _trackTypeLabel(
                          context,
                          rows[i].trackTypeL10nKey,
                        ),
                        onTap: () => _openCircuit(races[i]),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

String _iso2ForF1HostCountry(String country) {
  switch (country.trim()) {
    case 'Australia':
      return 'AU';
    case 'China':
      return 'CN';
    case 'Japan':
      return 'JP';
    case 'Bahrain':
      return 'BH';
    case 'Saudi Arabia':
      return 'SA';
    case 'USA':
      return 'US';
    case 'Canada':
      return 'CA';
    case 'Monaco':
      return 'MC';
    case 'Spain':
      return 'ES';
    case 'Austria':
      return 'AT';
    case 'UK':
      return 'GB';
    case 'Belgium':
      return 'BE';
    case 'Hungary':
      return 'HU';
    case 'Netherlands':
      return 'NL';
    case 'Italy':
      return 'IT';
    case 'Azerbaijan':
      return 'AZ';
    case 'Singapore':
      return 'SG';
    case 'Mexico':
      return 'MX';
    case 'Brazil':
      return 'BR';
    case 'Qatar':
      return 'QA';
    case 'UAE':
      return 'AE';
    default:
      final t = country.trim();
      if (t.length >= 2) {
        return t.substring(0, 2).toUpperCase();
      }
      return '—';
  }
}

/// Circuit catalog tile — glass-style shell, F1 Wide values, Titillium labels.
class _CircuitCatalogCard extends StatelessWidget {
  const _CircuitCatalogCard({
    required this.race,
    required this.metrics,
    required this.trackTypeLabel,
    required this.onTap,
  });

  final CircuitCatalogRaceInput race;
  final CircuitCardMetrics metrics;
  final String trackTypeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final len = metrics.lengthKm.toStringAsFixed(3);
    final speed = metrics.topSpeedKmh > 0 ? '${metrics.topSpeedKmh}' : '—';
    final iso = _iso2ForF1HostCountry(race.country);

    final statBoxBg = isDark
        ? ConstructorHubColors.surfaceElevated
        : Colors.black.withValues(alpha: 0.05);
    final primaryText = HubTheme.primaryOnGlassText(context);
    final mutedText = HubTheme.secondaryOnGlassText(context);
    const lapRecordRed = Color(0xFFE10600);
    const cardRadius = 18.0;

    return HubInteractiveGlass(
      borderRadius: cardRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cardRadius),
          child: HubVisualLanguage.glassPanel(
            context: context,
            radius: cardRadius,
            topAccent: HubVisualLanguage.f1DefaultAccent,
            accentGlow: HubVisualLanguage.f1DefaultAccent,
            accentGlowOpacity: isDark ? 0.085 : 0.06,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        iso,
                        textAlign: TextAlign.left,
                        style: HubVisualLanguage.f1Wide(
                          context,
                          fontSize: 22,
                          color: primaryText,
                          height: 1.05,
                        ),
                      ),
                    ),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HubVisualLanguage.f1Wide(
                            context,
                            fontSize: 17,
                            color: primaryText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: mutedText.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                metrics.location,
                                style: HubVisualLanguage.titilliumSecondary(
                                  context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 26,
                      color: mutedText.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _statBox(
                      context,
                      statBoxBg: statBoxBg,
                      primaryText: primaryText,
                      mutedText: mutedText,
                      isDark: isDark,
                      icon: Icons.straighten_rounded,
                      value: len,
                      unit: l10n.circuits_stat_km,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statBox(
                      context,
                      statBoxBg: statBoxBg,
                      primaryText: primaryText,
                      mutedText: mutedText,
                      isDark: isDark,
                      icon: Icons.autorenew_rounded,
                      value: '${metrics.laps}',
                      unit: l10n.circuits_stat_laps,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statBox(
                      context,
                      statBoxBg: statBoxBg,
                      primaryText: primaryText,
                      mutedText: mutedText,
                      isDark: isDark,
                      icon: Icons.speed_rounded,
                      value: speed,
                      unit: l10n.circuits_stat_kmh,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      trackTypeLabel.isNotEmpty ? trackTypeLabel : ' ',
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HubTheme.primaryOnGlassText(context),
                        opacity: 0.85,
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HubTheme.primaryOnGlassText(context),
                        opacity: 0.85,
                      ),
                      children: [
                        TextSpan(text: '${l10n.cfield_lap_record_detail}: '),
                        TextSpan(
                          text: metrics.lapRecordTime,
                          style: TextStyle(
                            color: lapRecordRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _statBox(
    BuildContext context, {
    required Color statBoxBg,
    required Color primaryText,
    required Color mutedText,
    required bool isDark,
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: statBoxBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: primaryText.withValues(alpha: 0.92)),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: HubVisualLanguage.f1Wide(
              context,
              fontSize: 19,
              color: primaryText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit.toUpperCase(),
            textAlign: TextAlign.center,
            style: HubVisualLanguage.titilliumSecondary(
              context,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: HubTheme.primaryOnGlassText(context),
              opacity: 0.6,
              letterSpacing: 1.15,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
