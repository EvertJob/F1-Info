import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/material.dart';

/// Wijzigingen sinds GitHub-snapshot
/// [EvertJob/F1-Info @ 79a7951](https://github.com/EvertJob/F1-Info/tree/79a79512a4854fb587f0fad3ad94b78f513bf1d4)
/// (toen vooral een GitHub Pages web-build met minimaal broncode-overzicht).
class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key, required this.settingsMenu});

  /// Breedte ≥ 600: zelfde drempel als de hoofdnavigatie (rail vs. bottom bar).
  static const double _desktopShellBreakpoint = 600;

  final Widget settingsMenu;

  static const _refUrl =
      'https://github.com/EvertJob/F1-Info/tree/79a79512a4854fb587f0fad3ad94b78f513bf1d4';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final textBody = isDark ? Colors.white70 : Colors.black87;
    final desktopShell =
        MediaQuery.sizeOf(context).width >= _desktopShellBreakpoint;

    return Scaffold(
      backgroundColor: desktopShell ? Colors.transparent : null,
      appBar: AppBar(
        title: Text(context.l10n.changelog),
        backgroundColor: desktopShell ? Colors.transparent : null,
        elevation: desktopShell ? 0 : null,
        scrolledUnderElevation: desktopShell ? 0 : null,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        actions: desktopShell
            ? const <Widget>[]
            : <Widget>[settingsMenu],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              desktopShell ? 8 : 0,
              24,
              32,
            ),
            children: [
              F1Module(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referentie',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _refUrl,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Die commit bevatte vrijwel alleen de gecompileerde web-output en '
                      'in de broncode alleen lib/main.dart — de huidige app is volledig '
                      'heropgezet als modulair Flutter-project (huidige versie zie pubspec.yaml). '
                      'Onderstaande lijst is een samenvatting van de belangrijkste verschillen '
                      'tussen die snapshot en de huidige F1 Hub.',
                      style: TextStyle(color: textBody, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _VersionBlock(
                version: '1.0.1+',
                date: 'Maart 2026',
                textSecondary: textSecondary,
                textBody: textBody,
                scheme: scheme,
                sections: const [
                  _Section(
                    title: 'Project & architectuur',
                    items: [
                      _Item(
                        'Monoliet → modulaire codebase: naast main.dart nu o.a. data layer, theme, widgets, live timing, services.',
                        subs: [
                          'Repositories en lokale cache (Hive) voor race-/sessiedata.',
                          'RaceRepository, SessionDataManager en gebundelde JSON onder data/results.',
                          'Detailpagina’s voor circuits, coureurs en teams met hero-animaties en vergelijkingsmodus.',
                        ],
                      ),
                      _Item(
                        'Routering met go_router: circuits, drivers, teams, profiel (inclusief deze changelog), live timing, login.',
                        subs: [
                          'Geneste routes voor weekend hub, sessieresultaten, fullscreen, vergelijkingen.',
                          'Stateful shell: onderaan (mobiel) of rail (desktop) dezelfde navigatie als op circuits/drivers/teams.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Platform & builds',
                    items: [
                      _Item(
                        'Multi-platform: web (PWA / GitHub Pages), Android en iOS uit dezelfde codebase.',
                        subs: [
                          'Web: base href en assets afgestemd op custom domain (f1hub.app) en projectpad op GitHub Pages.',
                          'Launcher-iconsets en adaptive icons voor mobiel; favicon en manifest voor web.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Authenticatie & cloud',
                    items: [
                      _Item(
                        'Supabase (OAuth o.a. GitHub) voor inloggen; profielvoorkeuren kunnen syncen.',
                        subs: [
                          'Loginpagina met supabase_auth_ui; uitloggen keert terug naar circuits.',
                          'SQL-migraties in supabase/sql voor nieuwe profielkolommen en voorkeuren.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Lokalisatie',
                    items: [
                      _Item(
                        'Vervanging van losse JSON-vertalingen door Flutter gen-l10n (ARB).',
                        subs: [
                          'Talen: en, nl, de, fr; instellingen en dialoog voor taalkeuze.',
                          'UI-strings (kalender, live timing, AI, profiel, …) in lib/l10n/*.arb.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Live timing & real-time',
                    items: [
                      _Item(
                        'Aparte live timing-pagina met live feed (o.a. WebSocket), tabel en statusbanners.',
                        subs: [
                          'Pit/out, sectoren S1–S3, banden, interval/gap; testdata-schakel voor ontwikkeling.',
                          'Grote datatabel met scroll en leesbare typografie op smalle schermen.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Thema & UI',
                    items: [
                      _Item(
                        'FlexColorScheme + F1-team kleurenschema’s; licht/donker/systeem.',
                        subs: [
                          'TitilliumWeb-fonts; consistente typografie op web en mobiel.',
                          'F1Module-component met vervagende rand (primary) op kaarten en lijsten, gelijk aan standings en circuits.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'AI Strategist & voorkeuren',
                    items: [
                      _Item(
                        'AI Strategist-kaart op het startscherm met configureerbare secties (prefs via Supabase).',
                        subs: [
                          'O.a. teammate battle, coach’s corner, team vibe uit te zetten.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Kalender & profiel',
                    items: [
                      _Item(
                        'Kalenderinstellingen (placeholder-races verbergen); laatste podium op circuitkaarten.',
                        subs: [
                          'Profiel: favorieten, detail-uitklap, last podium-aantal races.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Data & offline',
                    items: [
                      _Item(
                        'Bundeldata onder assets/data/results voor standen, weer, race control en vergelijkingsstatistieken.',
                        subs: [
                          'Hive-boxen voor caching; cache legen via instellingenmenu.',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Web & deployment (GitHub Pages)',
                    items: [
                      _Item(
                        'Dynamische base href voor custom domain (f1hub.app) vs. GitHub projectpad (/F1-Info/).',
                        subs: [
                          'CNAME, manifest, favicons; meerdere builds gepubliceerd (commits o.a. “Deploy”, “Fix base href”).',
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Overige technische updates',
                    items: [
                      _Item(
                        'Flutter 3.x-compatibiliteit (ThemeData, CardTheme, DialogTheme).',
                        subs: [
                          'Issue templates op GitHub; .vscode taken; analysis_options.',
                          'Tests en tooling (o.a. launcher-logo) waar relevant toegevoegd.',
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionBlock extends StatelessWidget {
  const _VersionBlock({
    required this.version,
    required this.date,
    required this.textSecondary,
    required this.textBody,
    required this.scheme,
    required this.sections,
  });

  final String version;
  final String date;
  final Color textSecondary;
  final Color textBody;
  final ColorScheme scheme;
  final List<_Section> sections;

  @override
  Widget build(BuildContext context) {
    return F1Module(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Versie $version',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                  fontSize: 18,
                ),
              ),
              Text(date, style: TextStyle(color: textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Samenvatting van wijzigingen ten opzichte van de referentie-commit.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(
              section.title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.3,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in section.items) ...[
              _BulletRow(
                bullet: '•',
                text: item.text,
                textBody: textBody,
                indent: 0,
              ),
              if (item.subs != null)
                for (final sub in item.subs!)
                  _BulletRow(
                    bullet: '◦',
                    text: sub,
                    textBody: textBody,
                    indent: 18,
                  ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_Item> items;
}

class _Item {
  const _Item(this.text, {this.subs});
  final String text;
  final List<String>? subs;
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.bullet,
    required this.text,
    required this.textBody,
    required this.indent,
  });

  final String bullet;
  final String text;
  final Color textBody;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$bullet ',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textBody, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
