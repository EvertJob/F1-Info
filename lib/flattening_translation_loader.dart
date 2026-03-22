import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';

/// Loads locale JSON and normalizes nested `t` maps for consistent lookups.
///
/// Decoded JSON maps are sometimes not promoted to [Map<String, dynamic>]
/// (e.g. JS / interop), so nested resolution can fail while top-level keys work.
///
/// We (1) replace `raw['t']` with a real [Map<String, dynamic>] when present,
/// (2) copy each entry to `raw['t.<key>']`, and (3) if strings live at the root
/// (no `t` wrapper), also add `t.<key>` for every top-level scalar.
class FlatteningTranslationLoader {
  const FlatteningTranslationLoader();

  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded as Map);
      _normalizeAndFlattenT(data);
      return data;
    } catch (_) {
      return null;
    }
  }

  static void _normalizeAndFlattenT(Map<String, dynamic> raw) {
    final tNode = raw['t'];
    if (tNode is Map) {
      final normalized = <String, dynamic>{};
      for (final e in tNode.entries) {
        normalized[e.key.toString()] = e.value;
      }
      raw['t'] = normalized;

      for (final e in normalized.entries) {
        raw['t.${e.key}'] = e.value;
      }
    }

    for (final e in raw.entries.toList()) {
      if (e.key == 't') continue;
      final v = e.value;
      if (v is String || v is num || v is bool) {
        raw.putIfAbsent('t.${e.key}', () => v);
      }
    }
  }
}
