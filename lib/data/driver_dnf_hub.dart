import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/hub_visual_language.dart';

/// Asset path per [Driver.name] for bundled DNF JSON payloads.
const Map<String, String> kBundledDriverDnfAssetPaths = {
  'Max Verstappen': 'assets/data/dnf/max_verstappen_dnfs.json',
};

bool driverHasBundledDnfJson(String driverName) =>
    kBundledDriverDnfAssetPaths.containsKey(driverName);

/// Loads bundled JSON for [driverName], or completes with `null` when none.
Future<DnfHubPayload?> loadBundledDriverDnfPayload(String driverName) {
  final path = kBundledDriverDnfAssetPaths[driverName];
  if (path == null) {
    return Future<DnfHubPayload?>.value(null);
  }
  return rootBundle.loadString(path).then(DnfHubPayload.parse);
}

/// Canonical accent for the category string from JSON (no enums — unknown → default).
Color dnfCategoryAccentColor(
  BuildContext context,
  String category,
  Color teamAccent,
) {
  if (category == 'Team/Technical Error') {
    return teamAccent;
  }
  if (category == 'Driver Error') {
    return HubVisualLanguage.f1DefaultAccent;
  }
  if (category == 'Racing Incident') {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
  }
  return HubVisualLanguage.f1DefaultAccent;
}

/// Unified row for hub retirements (JSON-backed or legacy `dnfMap` rows).
class DnfUiEntry {
  const DnfUiEntry({
    required this.year,
    required this.grandPrix,
    required this.lapRaw,
    required this.reason,
    required this.detail,
    required this.category,
  });

  final int year;
  final String grandPrix;
  final String lapRaw;
  final String reason;
  final String detail;
  /// Raw JSON string; empty for legacy rows.
  final String category;

  factory DnfUiEntry.fromJsonMap(Map<String, dynamic> m) {
    final year = (m['year'] as num?)?.toInt() ?? 0;
    final gp = m['grand_prix']?.toString() ?? '';
    final lap = m['lap'];
    final lapRaw = lap is num ? lap.toString() : (lap?.toString() ?? '');
    return DnfUiEntry(
      year: year,
      grandPrix: gp,
      lapRaw: lapRaw,
      reason: m['reason']?.toString() ?? '',
      detail: m['detail']?.toString() ?? '',
      category: m['category']?.toString() ?? '',
    );
  }

  /// Legacy `_getDnfEntries` row: [year, gpName, description, lap].
  factory DnfUiEntry.fromLegacyRow(List<String> row) {
    if (row.length < 4) {
      return const DnfUiEntry(
        year: 0,
        grandPrix: '',
        lapRaw: '',
        reason: '',
        detail: '',
        category: '',
      );
    }
    final y = int.tryParse(row[0].trim()) ?? 0;
    return DnfUiEntry(
      year: y,
      grandPrix: row[1].trim(),
      lapRaw: row[3].trim(),
      reason: '',
      detail: row[2].trim(),
      category: '',
    );
  }

  static List<DnfUiEntry> fromLegacyRows(List<List<String>> rows) =>
      rows.map(DnfUiEntry.fromLegacyRow).toList();
}

class DnfHubPayload {
  const DnfHubPayload({
    required this.driver,
    required this.totalDnfs,
    required this.lastUpdated,
    required this.dnfList,
  });

  final String driver;
  final int totalDnfs;
  final String lastUpdated;
  final List<DnfUiEntry> dnfList;

  static DnfHubPayload parse(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('DNF JSON root must be an object');
    }
    return DnfHubPayload.fromJson(decoded);
  }

  factory DnfHubPayload.fromJson(Map<String, dynamic> j) {
    final listRaw = j['dnf_list'];
    final entries = <DnfUiEntry>[];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map) {
          entries.add(DnfUiEntry.fromJsonMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    return DnfHubPayload(
      driver: j['driver']?.toString() ?? '',
      totalDnfs: (j['total_dnfs'] as num?)?.toInt() ?? entries.length,
      lastUpdated: j['last_updated']?.toString() ?? '',
      dnfList: entries,
    );
  }

  /// Newest seasons first (JSON file is chronological ascending).
  List<DnfUiEntry> orderedNewestFirst() {
    final out = List<DnfUiEntry>.from(dnfList);
    out.sort((a, b) {
      final y = b.year.compareTo(a.year);
      if (y != 0) {
        return y;
      }
      return 0;
    });
    return out;
  }
}
