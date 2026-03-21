import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// Defines the 12 F1 2026 team / entity color schemes for both Light and Dark modes.
/// Each scheme matches the 2026 livery colors.
abstract final class F1TeamSchemes {
  F1TeamSchemes._();

  /// Total number of schemes (10 teams + Cadillac + FIA).
  static const int count = 12;

  /// Default scheme index (Red Bull).
  static const int defaultIndex = 0;

  /// All 12 FlexSchemeData pairs (light + dark) for the 2026 F1 grid.
  static const List<FlexSchemeData> schemes = [
    // 0: Red Bull Racing – Navy Blue / Red / Yellow
    FlexSchemeData(
      name: 'Red Bull Racing',
      description: 'Navy Blue, Red & Yellow – 2026 Heritage',
      light: FlexSchemeColor(
        primary: Color(0xFF0600EF),
        primaryContainer: Color(0xFFB3B0FA),
        secondary: Color(0xFFE10600),
        secondaryContainer: Color(0xFFFFCDCC),
        tertiary: Color(0xFFF7B500),
        tertiaryContainer: Color(0xFFFFE566),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF6B68FF),
        primaryContainer: Color(0xFF1A15A8),
        secondary: Color(0xFFFF4D47),
        secondaryContainer: Color(0xFF8B1E1A),
        tertiary: Color(0xFFFFD54F),
        tertiaryContainer: Color(0xFF7A5A00),
      ),
    ),

    // 1: Ferrari – Rosso Corsa / Modena Yellow / Playfair Display
    FlexSchemeData(
      name: 'Ferrari',
      description: 'Rosso Corsa & Modena Yellow – Scuderia',
      light: FlexSchemeColor(
        primary: Color(0xFFEF1A2D),
        primaryContainer: Color(0xFFFFB3BC),
        secondary: Color(0xFF0D0D0D),
        secondaryContainer: Color(0xFF5C5C5C),
        tertiary: Color(0xFFFFEB00),
        tertiaryContainer: Color(0xFFFFF066),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFFF4D6A),
        primaryContainer: Color(0xFF8B0012),
        secondary: Color(0xFFE0E0E0),
        secondaryContainer: Color(0xFF2A2A2A),
        tertiary: Color(0xFFFFE566),
        tertiaryContainer: Color(0xFF7A5A00),
      ),
    ),

    // 2: Mercedes-AMG – Petronas Cyan / Sterling Silver / Inter
    FlexSchemeData(
      name: 'Mercedes-AMG',
      description: 'Petronas Cyan & Sterling Silver',
      light: FlexSchemeColor(
        primary: Color(0xFF00A19B),
        primaryContainer: Color(0xFF99F0E8),
        secondary: Color(0xFF8A8A8A),
        secondaryContainer: Color(0xFFD4D4D4),
        tertiary: Color(0xFF1A1A1A),
        tertiaryContainer: Color(0xFF4D4D4D),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF00E5CC),
        primaryContainer: Color(0xFF00665C),
        secondary: Color(0xFFB0B0B0),
        secondaryContainer: Color(0xFF353535),
        tertiary: Color(0xFFE8E8E8),
        tertiaryContainer: Color(0xFF2A2A2A),
      ),
    ),

    // 3: McLaren – Papaya Orange / Speed Blue / Orbitron (letterSpacing 1.2)
    FlexSchemeData(
      name: 'McLaren',
      description: 'Papaya Orange & Speed Blue',
      light: FlexSchemeColor(
        primary: Color(0xFFFF8000),
        primaryContainer: Color(0xFFFFD199),
        secondary: Color(0xFF383838),
        secondaryContainer: Color(0xFF6B6B6B),
        tertiary: Color(0xFF0066B3),
        tertiaryContainer: Color(0xFF99CCED),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFFFA033),
        primaryContainer: Color(0xFF663300),
        secondary: Color(0xFFA0A0A0),
        secondaryContainer: Color(0xFF2A2A2A),
        tertiary: Color(0xFF4DA6E6),
        tertiaryContainer: Color(0xFF003D66),
      ),
    ),

    // 4: Aston Martin – British Racing Green / Lime Essence
    FlexSchemeData(
      name: 'Aston Martin',
      description: 'British Racing Green & Lime Essence',
      light: FlexSchemeColor(
        primary: Color(0xFF006F62),
        primaryContainer: Color(0xFF99D4CC),
        secondary: Color(0xFF32CD32),
        secondaryContainer: Color(0xFFC8F7C8),
        tertiary: Color(0xFF004D40),
        tertiaryContainer: Color(0xFFB2DFDB),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4DB6AC),
        primaryContainer: Color(0xFF003830),
        secondary: Color(0xFF69F0AE),
        secondaryContainer: Color(0xFF00695C),
        tertiary: Color(0xFF80CBC4),
        tertiaryContainer: Color(0xFF004D40),
      ),
    ),

    // 5: Alpine – Racing Blue / Pink / Black
    FlexSchemeData(
      name: 'Alpine',
      description: 'Racing Blue, Pink & Black',
      light: FlexSchemeColor(
        primary: Color(0xFF0063B3),
        primaryContainer: Color(0xFFB3D6F0),
        secondary: Color(0xFFE6007E),
        secondaryContainer: Color(0xFFFFB3D9),
        tertiary: Color(0xFF1A1A1A),
        tertiaryContainer: Color(0xFF5C5C5C),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4DA6E6),
        primaryContainer: Color(0xFF003D66),
        secondary: Color(0xFFFF4DA6),
        secondaryContainer: Color(0xFF660033),
        tertiary: Color(0xFFE0E0E0),
        tertiaryContainer: Color(0xFF2A2A2A),
      ),
    ),

    // 6: Williams – Multi-tone Blue / Gold accents
    FlexSchemeData(
      name: 'Williams',
      description: 'Multi-tone Blue & Gold accents',
      light: FlexSchemeColor(
        primary: Color(0xFF005AFF),
        primaryContainer: Color(0xFFB3D0FF),
        secondary: Color(0xFF003D99),
        secondaryContainer: Color(0xFF99B8E6),
        tertiary: Color(0xFFD4AF37),
        tertiaryContainer: Color(0xFFFFE566),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4D8AFF),
        primaryContainer: Color(0xFF002966),
        secondary: Color(0xFF6B9EFF),
        secondaryContainer: Color(0xFF001F4D),
        tertiary: Color(0xFFFFD54F),
        tertiaryContainer: Color(0xFF665200),
      ),
    ),

    // 7: Haas – White / Red / Black
    FlexSchemeData(
      name: 'Haas',
      description: 'White, Red & Black',
      light: FlexSchemeColor(
        primary: Color(0xFFE10600),
        primaryContainer: Color(0xFFFFCDCC),
        secondary: Color(0xFF1A1A1A),
        secondaryContainer: Color(0xFF5C5C5C),
        tertiary: Color(0xFFF5F5F5),
        tertiaryContainer: Color(0xFFE0E0E0),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFFF4D47),
        primaryContainer: Color(0xFF8B1E1A),
        secondary: Color(0xFFE0E0E0),
        secondaryContainer: Color(0xFF2A2A2A),
        tertiary: Color(0xFF4D4D4D),
        tertiaryContainer: Color(0xFF1A1A1A),
      ),
    ),

    // 8: RB – Navy Blue / Racing Red / Kanit (matches Red Bull)
    FlexSchemeData(
      name: 'RB',
      description: 'Navy Blue & Racing Red – Visa Cash App RB',
      light: FlexSchemeColor(
        primary: Color(0xFF0600EF),
        primaryContainer: Color(0xFF99CCED),
        secondary: Color(0xFFB0B0B0),
        secondaryContainer: Color(0xFFE8E8E8),
        tertiary: Color(0xFFFAFAFA),
        tertiaryContainer: Color(0xFFF0F0F0),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4DA6E6),
        primaryContainer: Color(0xFF003D66),
        secondary: Color(0xFFB0B0B0),
        secondaryContainer: Color(0xFF353535),
        tertiary: Color(0xFF2A2A2A),
        tertiaryContainer: Color(0xFF1A1A1A),
      ),
    ),

    // 9: Audi – Neon Green / Stealth Black / Syncopate (letterSpacing 1.2)
    FlexSchemeData(
      name: 'Audi',
      description: 'Neon Green & Stealth Black',
      light: FlexSchemeColor(
        primary: Color(0xFFCCFF00),
        primaryContainer: Color(0xFFCCFFC0),
        secondary: Color(0xFF1A1A1A),
        secondaryContainer: Color(0xFF5C5C5C),
        tertiary: Color(0xFFB0B0B0),
        tertiaryContainer: Color(0xFFE0E0E0),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF69FF4D),
        primaryContainer: Color(0xFF226600),
        secondary: Color(0xFFE0E0E0),
        secondaryContainer: Color(0xFF2A2A2A),
        tertiary: Color(0xFFB0B0B0),
        tertiaryContainer: Color(0xFF353535),
      ),
    ),

    // 10: Cadillac – White / Black / V-Series (Red/Blue/Gold) accents
    FlexSchemeData(
      name: 'Cadillac',
      description: 'White, Black & V-Series accents',
      light: FlexSchemeColor(
        primary: Color(0xFFE10600),
        primaryContainer: Color(0xFFFFCDCC),
        secondary: Color(0xFF1A1A1A),
        secondaryContainer: Color(0xFF5C5C5C),
        tertiary: Color(0xFFD4AF37),
        tertiaryContainer: Color(0xFFFFE566),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF2A2A2A),
        primaryContainer: Color(0xFF101010),
        secondary: Color(0xFFFF4D47),
        secondaryContainer: Color(0xFF8B1E1A),
        tertiary: Color(0xFFFFD54F),
        tertiaryContainer: Color(0xFF665200),
      ),
    ),

    // 11: FIA – Deep Blue / Gold / White (Neutral / Official)
    FlexSchemeData(
      name: 'FIA',
      description: 'Deep Blue, Gold & White – Official',
      light: FlexSchemeColor(
        primary: Color(0xFF003366),
        primaryContainer: Color(0xFF99B8E6),
        secondary: Color(0xFFD4AF37),
        secondaryContainer: Color(0xFFFFE566),
        tertiary: Color(0xFFFAFAFA),
        tertiaryContainer: Color(0xFFF0F0F0),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4D8AFF),
        primaryContainer: Color(0xFF001A33),
        secondary: Color(0xFFFFD54F),
        secondaryContainer: Color(0xFF665200),
        tertiary: Color(0xFF2A2A2A),
        tertiaryContainer: Color(0xFF1A1A1A),
      ),
    ),
  ];

  /// Returns the scheme at [index], or the default scheme if out of range.
  static FlexSchemeData schemeAt(int index) {
    if (index >= 0 && index < schemes.length) {
      return schemes[index];
    }
    return schemes[defaultIndex];
  }

  /// Supabase profile brand_theme string → scheme index.
  static const Map<String, int> brandToIndex = {
    'red_bull': 0,
    'ferrari': 1,
    'mercedes': 2,
    'mclaren': 3,
    'aston_martin': 4,
    'alpine': 5,
    'williams': 6,
    'haas': 7,
    'rb': 8,
    'audi': 9,
    'cadillac': 10,
    'fia': 11,
  };

  /// Scheme index → brand string (for Supabase upsert).
  static const List<String> indexToBrand = [
    'red_bull', 'ferrari', 'mercedes', 'mclaren', 'aston_martin',
    'alpine', 'williams', 'haas', 'rb', 'audi', 'cadillac', 'fia',
  ];

  /// Display names for brand buttons.
  static const List<String> brandDisplayNames = [
    'Red Bull', 'Ferrari', 'Mercedes', 'McLaren', 'Aston Martin',
    'Alpine', 'Williams', 'Haas', 'RB', 'Audi', 'Cadillac', 'FIA',
  ];

  /// Converts brand string to scheme index, or [defaultIndex] if unknown.
  static int indexFromBrand(String brand) {
    final key = brand.trim().toLowerCase().replaceAll(' ', '_');
    return brandToIndex[key] ?? defaultIndex;
  }

  /// Converts scheme index to brand string.
  static String brandFromIndex(int index) {
    if (index >= 0 && index < indexToBrand.length) {
      return indexToBrand[index];
    }
    return indexToBrand[defaultIndex];
  }

  /// Team name → brand accent color. Used for team labels, borders, accents.
  /// Fallback uses schemes default secondary.
  static Color getTeamColor(String teamName) {
    final t = teamName.toLowerCase();
    if (t.contains('ferrari')) return const Color(0xFFEF1A2D);
    if (t.contains('red bull')) return const Color(0xFF0600EF);
    if (t.contains('mclaren')) return const Color(0xFFFF8000);
    if (t.contains('mercedes')) return const Color(0xFF00A19B);
    if (t.contains('aston')) return const Color(0xFF006F62);
    if (t.contains('williams')) return const Color(0xFF005AFF);
    if (t.contains('alpine')) return const Color(0xFF0090AD);
    if (t.contains('haas')) return const Color(0xFFB6BABD);
    if (t.contains('audi') || t.contains('sauber')) return const Color(0xFFCCFF00);
    if (t.contains('racing bulls') || t.contains('rb')) return const Color(0xFF0600EF);
    if (t.contains('cadillac')) return const Color(0xFFE10600);
    return schemes[defaultIndex].light.primary; // Neutral fallback from default scheme
  }

  /// F1 tire compound → standard Pirelli/FIA color.
  static Color getTireColor(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return const Color(0xFF2E7D32);
      case 'MEDIUM':
        return const Color(0xFFF9A825);
      case 'HARD':
        return const Color(0xFFF57F17);
      case 'INTERMEDIATE':
      case 'WET':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF757575);
    }
  }
}
