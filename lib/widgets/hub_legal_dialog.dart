import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../browser_bridge.dart' as browser_bridge;
import '../theme/hub_theme.dart';
import '../utils/l10n_extension.dart';
import 'constructor_hub_theme.dart';
import 'hub_fullscreen_glass_dialog.dart';

/// Markdown body for the legal overlay (link opens in browser).
const String kF1HubLegalMarkdown = '''
# Legal Disclaimer & Notice

### **Unofficial Fan Application**
This application is **unofficial** and is not associated in any way with the Formula 1 companies. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX and related marks are trade marks of **Formula One Licensing B.V.**

### **Non-Commercial & Educational Use**
This app is developed strictly for personal, non-commercial, and educational purposes. No copyright infringement is intended. All copyrighted materials, including but not limited to team names, driver identities, and circuit layouts, are used under **Fair Use** guidelines for transformative, informational, and statistical purposes.

### **Data Transparency**
This application does not perform unauthorized scraping of official Formula 1 digital properties. All racing data, telemetry, and historical statistics are retrieved via authorized public and open-source endpoints, including:
* **OpenF1 API** (Real-time telemetry and data)
* **Ergast Developer API** (Historical statistics and race results)
* **Wikipedia / Wikimedia Commons** (Public domain imagery and descriptions)

### **Intellectual Property**
All rights, titles, and interests in the intellectual property of the Formula 1 brand remain the sole property of their respective owners. This application does not claim any ownership over the data or branding displayed.

---

*Last updated: April 2026*

[Official Formula 1 legal notices](https://www.formula1.com/en/information/legal-notices.7egvZU48hzrypubGBNcQKt)
''';

Future<void> showHubLegalGlassDialog(BuildContext context) {
  return showHubFullscreenGlassDialog<void>(
    context: context,
    body: const _HubLegalMarkdownScrollView(),
  );
}

class _HubLegalMarkdownScrollView extends StatelessWidget {
  const _HubLegalMarkdownScrollView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : HubTheme.f1DeepCharcoal.withValues(alpha: 0.88);
    final linkColor = isDark
        ? const Color(0xFF8EC5FF)
        : Theme.of(context).colorScheme.primary;

    final base = GoogleFonts.inter(color: fg);
    final sheet = MarkdownStyleSheet(
      h1: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      h2: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      h3: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      p: base.copyWith(fontSize: 13, height: 1.5),
      listBullet: base.copyWith(fontSize: 13, height: 1.5),
      strong: base.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
      em: base.copyWith(fontSize: 13, fontStyle: FontStyle.italic),
      a: base.copyWith(
        fontSize: 13,
        color: linkColor,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w600,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: fg.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
      ),
      blockSpacing: 12,
      listIndent: 22,
    );

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.only(bottom: 8),
        child: MarkdownBody(
          data: kF1HubLegalMarkdown,
          styleSheet: sheet,
          selectable: true,
          onTapLink: (text, href, title) {
            if (href != null && href.isNotEmpty) {
              browser_bridge.openExternalUrl(href);
            }
          },
        ),
      ),
    );
  }
}

/// Plain text link (or compact icon when [compact]) opening [showHubLegalGlassDialog].
class HubLegalNavLink extends StatelessWidget {
  const HubLegalNavLink({
    required this.hubCockpit,
    this.compact = false,
    super.key,
  });

  final bool hubCockpit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final inactive = hubCockpit
        ? ConstructorHubColors.textSecondary
        : HubTheme.f1DeepCharcoal.withValues(alpha: 0.72);

    void open() => showHubLegalGlassDialog(context);

    if (compact) {
      return Tooltip(
        message: context.l10n.nav_legal,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Icon(
              Icons.gavel_outlined,
              size: 20,
              color: inactive,
            ),
          ),
        ),
      );
    }

    final textStyle = GoogleFonts.titilliumWeb(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: inactive,
      decoration: TextDecoration.underline,
      decorationColor: inactive.withValues(alpha: 0.55),
    );

    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          context.l10n.nav_legal.toUpperCase(),
          style: textStyle,
        ),
      ),
    );
  }
}
