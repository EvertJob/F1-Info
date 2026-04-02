import 'package:f1/theme/hub_theme.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact “next race” summary for hub rail and mobile nav overlay.
class NextRaceHubMiniCard extends StatelessWidget {
  const NextRaceHubMiniCard({
    super.key,
    this.raceName,
    this.raceDate,
    this.lightForegroundOnDarkPanel = false,
  });

  final String? raceName;
  final DateTime? raceDate;

  /// When true (e.g. dark hub nav overlay), use white copy on the glass panel
  /// instead of [HubTheme] (avoids white-on-light when Theme brightness mismatches).
  final bool lightForegroundOnDarkPanel;

  @override
  Widget build(BuildContext context) {
    final name = raceName?.trim() ?? '';
    final date = raceDate;
    if (name.isEmpty || date == null) {
      return const SizedBox.shrink();
    }
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMMd(locale).format(date);
    final Color primaryInk = lightForegroundOnDarkPanel
        ? Colors.white
        : HubTheme.primaryOnGlassText(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: HubVisualLanguage.glassPanel(
          context: context,
          radius: HubVisualLanguage.cardRadius,
          topAccent: HubVisualLanguage.f1DefaultAccent,
          accentGlow: HubVisualLanguage.f1DefaultAccent,
          accentGlowOpacity: 0.09,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              context.l10n.next_race.toUpperCase(),
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primaryInk,
                opacity: 0.65,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 14,
                color: primaryInk,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 13,
                color: primaryInk,
                opacity: 0.7,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
