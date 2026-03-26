import 'package:f1/circuit_detail/circuit_l10n_resolver.dart';
import 'package:f1/l10n/app_localizations.dart';

/// Strips technical unit suffixes (and optional `_l10n`) for the **label** column only.
/// E.g. `top_speed_kmh` → `top_speed`, `length_m` → `length`, `pit_exit_delta_s` → `pit_exit_delta`.
String stripKeyForLabel(String fieldKey) {
  var k = fieldKey.trim();
  if (k.endsWith('_l10n')) {
    k = k.substring(0, k.length - 5);
  }
  const suffixes = <String>[
    '_kmh',
    '_pct',
    '_kj',
    '_ms',
    '_s',
    '_m',
  ];
  for (final s in suffixes) {
    if (k.endsWith(s)) {
      return k.substring(0, k.length - s.length);
    }
  }
  return k;
}

/// Label text: localized / humanized from stripped base key (no raw snake_case).
String labelForDataField(AppLocalizations l10n, String fieldKey) {
  final base = stripKeyForLabel(fieldKey);
  return circuitLocalizedString(l10n, base);
}

bool isRecordDetailMap(dynamic value) {
  if (value is! Map) return false;
  final keys = value.keys.map((e) => e.toString()).toSet();
  final hasTime = keys.contains('time') &&
      value['time'] != null &&
      value['time'].toString().trim().isNotEmpty;
  final hasTimeS = keys.contains('time_s');
  return hasTime || hasTimeS;
}

/// Lap / pitstop style records (time or time_s plus metadata).
bool isRecordRow(String fieldKey, dynamic value) {
  if (!isRecordDetailMap(value)) return false;
  final k = fieldKey.toLowerCase();
  return k.contains('lap_record') ||
      k.contains('pitstop_record') ||
      k.contains('record_detail') ||
      (k.contains('record') && k.endsWith('_detail'));
}

String _formatSecondsNumeric(dynamic v) {
  final n = switch (v) {
    num x => x.toDouble(),
    _ => double.tryParse(v.toString()),
  };
  if (n == null) return v.toString();
  return n.toStringAsFixed(2);
}

(String primary, String subtitle) recordPrimaryAndSubtitle(
  Map<dynamic, dynamic> raw,
) {
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  String primary = '—';

  final timeStr = m['time']?.toString().trim();
  if (timeStr != null && timeStr.isNotEmpty) {
    primary = timeStr;
  } else if (m['time_s'] != null) {
    primary = '${_formatSecondsNumeric(m['time_s'])}s';
  }

  final parts = <String>[];
  void add(String key) {
    final v = m[key];
    if (v == null) return;
    final s = v.toString().trim();
    if (s.isEmpty) return;
    parts.add(s);
  }

  add('driver');
  add('team');
  add('engine');
  if (m['year'] != null) {
    parts.add(m['year'].toString());
  }

  return (primary, parts.join(' · '));
}

/// Formats a leaf value using [originalKey] for unit suffix rules.
String formatValueWithUnits(
  AppLocalizations l10n,
  String originalKey,
  dynamic value, {
  String? unitContextKey,
}) {
  if (value == null) return '—';

  final unitKey = unitContextKey ?? originalKey;

  if (value is String) {
    if (originalKey.endsWith('_l10n')) {
      return circuitLocalizedString(l10n, value);
    }
    final resolved = circuitLocalizedString(l10n, value);
    if (originalKey.endsWith('_s') &&
        !value.contains('_') &&
        !resolved.endsWith('s')) {
      return '${resolved}s';
    }
    return resolved;
  }

  if (value is bool) {
    return value ? 'Yes' : 'No';
  }

  if (value is num) {
    if (unitKey.endsWith('_kmh')) {
      return '${_numToString(value)} km/h';
    }
    if (unitKey.endsWith('_pct')) {
      return '${_numToString(value)}%';
    }
    if (unitKey.endsWith('_kj')) {
      return '${_numToString(value)} kJ';
    }
    if (unitKey.endsWith('_ms')) {
      return '${_numToString(value)} ms';
    }
    if (unitKey.endsWith('_s')) {
      return '${value.toDouble().toStringAsFixed(2)}s';
    }
    if (unitKey.endsWith('_m')) {
      return '${_numToString(value)} m';
    }
    return _numToString(value);
  }

  return value.toString();
}

String _numToString(num n) {
  if (n == n.roundToDouble()) {
    return n.toInt().toString();
  }
  return n.toString();
}

/// Multi-line map: cleaned labels + unit-aware values. [parentKey] used for child unit hints.
String formatMapAsLines(
  AppLocalizations l10n,
  String parentKey,
  Map<dynamic, dynamic> map,
) {
  final inheritMeters = parentKey.endsWith('_m') && !parentKey.endsWith('_ms');
  final lines = <String>[];
  for (final e in map.entries) {
    final childKey = e.key.toString();
    final v = e.value;
    final label = labelForDataField(l10n, childKey);
    if (v is Map) {
      lines.add(
        '$label:\n${formatMapAsLines(l10n, childKey, v)}',
      );
    } else {
      final unitKey =
          inheritMeters && v is num && !childKey.contains('_')
              ? '${childKey}_m'
              : childKey;
      lines.add(
        '$label: ${formatValueWithUnits(l10n, unitKey, v, unitContextKey: unitKey)}',
      );
    }
  }
  return lines.join('\n');
}

/// Top-level value: maps, lists, scalars.
String formatDataPointValue(
  AppLocalizations l10n,
  String fieldKey,
  dynamic value,
) {
  if (value == null) return '—';
  if (value is Map) {
    if (isRecordDetailMap(value)) {
      final (p, s) = recordPrimaryAndSubtitle(value);
      return s.isEmpty ? p : '$p\n$s';
    }
    return formatMapAsLines(l10n, fieldKey, value);
  }
  if (value is List) {
    return value
        .map((e) => formatDataPointValue(l10n, fieldKey, e))
        .join(', ');
  }
  return formatValueWithUnits(l10n, fieldKey, value);
}
