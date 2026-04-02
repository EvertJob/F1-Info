import 'package:flutter/material.dart';

/// Dark “F1Hub / constructors” cockpit palette (aligned with Base44-style hubs).
abstract final class ConstructorHubColors {
  /// Reference cockpit: near-black shell.
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color accentLine = Color(0xFF3D4F6F);
  static const Color railLogoRed = Color(0xFFE10600);
  static const Color heroDeep = Color(0xFF0A1012);
  static const Color heroVoid = Color(0xFF050608);
}

/// Small country/market prefix before team name (e.g. DE MERCEDES).
String constructorCountryPrefix(String teamName) {
  const m = <String, String>{
    'Mercedes': 'DE',
    'Ferrari': 'IT',
    'Red Bull Racing': 'AT',
    'Racing Bulls': 'IT',
    'McLaren': 'GB',
    'Aston Martin': 'GB',
    'Alpine': 'FR',
    'Williams': 'GB',
    'Haas F1 Team': 'US',
    'Audi': 'DE',
    'Cadillac': 'US',
  };
  return m[teamName] ?? '';
}

/// Three-letter / short codes similar to the reference “RB” header.
String constructorShortCodeForName(String teamName) {
  const map = <String, String>{
    'Racing Bulls': 'RB',
    'Red Bull Racing': 'RBR',
    'Mercedes': 'MER',
    'Ferrari': 'FER',
    'McLaren': 'MCL',
    'Aston Martin': 'AMR',
    'Alpine': 'ALP',
    'Williams': 'WIL',
    'Haas F1 Team': 'HAA',
    'Audi': 'AUD',
    'Cadillac': 'CAD',
  };
  return map[teamName] ??
      teamName
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(3)
          .map((w) => w[0].toUpperCase())
          .join();
}
