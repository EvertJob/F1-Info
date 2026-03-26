import 'dart:convert';

/// Parsed F1 circuit JSON with five dashboard categories plus optional characteristics.
class CircuitData {
  const CircuitData({
    required this.circuitId,
    required this.name,
    required this.location,
    required this.categories,
    this.characteristics,
    this.latitude,
    this.longitude,
  });

  final String circuitId;
  final String name;
  final String location;
  final List<CircuitCategorySection> categories;
  final CircuitCharacteristics? characteristics;

  /// Optional WGS84 coordinates for maps deep links (root JSON `latitude` / `longitude`).
  final double? latitude;
  final double? longitude;

  factory CircuitData.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final cats =
        rawCats is List
            ? rawCats
                .whereType<Map>()
                .map(
                  (m) => CircuitCategorySection.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                .toList(growable: false)
            : <CircuitCategorySection>[];

    CircuitCharacteristics? ch;
    final rawCh = json['characteristics'];
    if (rawCh is Map) {
      ch = CircuitCharacteristics.fromJson(
        rawCh.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    double? lat = _readDouble(json['latitude']) ?? _readDouble(json['lat']);
    double? lon = _readDouble(json['longitude']) ?? _readDouble(json['lng']);
    final coords = json['coordinates'];
    if (coords is Map) {
      lat ??= _readDouble(coords['latitude']) ?? _readDouble(coords['lat']);
      lon ??= _readDouble(coords['longitude']) ?? _readDouble(coords['lng']);
    }

    return CircuitData(
      circuitId: json['circuit_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      categories: cats,
      characteristics: ch,
      latitude: lat,
      longitude: lon,
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static CircuitData parseJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw FormatException('Circuit JSON root must be an object');
    }
    // jsonDecode returns Map<String, dynamic> on VM but not always typed; normalize.
    return CircuitData.fromJson(Map<String, dynamic>.from(decoded));
  }
}

class CircuitCategorySection {
  const CircuitCategorySection({
    required this.categoryId,
    required this.labelL10n,
    required this.icon,
    required this.dataPoints,
  });

  final String categoryId;
  final String labelL10n;
  final String icon;
  final Map<String, dynamic> dataPoints;

  factory CircuitCategorySection.fromJson(Map<String, dynamic> json) {
    final dp = json['data_points'];
    final map =
        dp is Map
            ? dp.map((k, v) => MapEntry(k.toString(), v))
            : <String, dynamic>{};

    return CircuitCategorySection(
      categoryId: json['category_id']?.toString() ?? '',
      labelL10n: json['label_l10n']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'circle',
      dataPoints: map,
    );
  }
}

class CircuitCharacteristics {
  const CircuitCharacteristics({
    required this.keyFeaturesL10n,
    this.fullThrottlePct,
  });

  final List<String> keyFeaturesL10n;
  final int? fullThrottlePct;

  factory CircuitCharacteristics.fromJson(Map<String, dynamic> json) {
    final kf = json['key_features_l10n'];
    final keys =
        kf is List
            ? kf.map((e) => e.toString()).toList(growable: false)
            : <String>[];

    final ftp = json['full_throttle_pct'];
    int? pct;
    if (ftp is int) {
      pct = ftp;
    } else {
      pct = int.tryParse(ftp?.toString() ?? '');
    }

    return CircuitCharacteristics(
      keyFeaturesL10n: keys,
      fullThrottlePct: pct,
    );
  }
}
