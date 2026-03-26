import 'package:f1/orbit/orbit_models.dart';

/// Must match the shell [GoRoute] path in `main.dart`.
const String kOrbitGoPath = '/orbit';

/// Stable URL segment from [F1CircuitLocation.location], e.g. "Zandvoort" → "zandvoort".
String orbitUrlSlugForCircuit(F1CircuitLocation c) {
  final s = c.location.trim().toLowerCase();
  final sb = StringBuffer();
  var pendingHyphen = false;
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    final isLower = unit >= 0x61 && unit <= 0x7A;
    final isDigit = unit >= 0x30 && unit <= 0x39;
    if (isLower || isDigit) {
      if (pendingHyphen) {
        sb.write('-');
        pendingHyphen = false;
      }
      sb.writeCharCode(unit);
    } else if (unit == 0x20 || unit == 0x2D || unit == 0x5F) {
      if (sb.isNotEmpty) pendingHyphen = true;
    }
  }
  var out = sb.toString();
  while (out.contains('--')) {
    out = out.replaceAll('--', '-');
  }
  out = out.replaceAll(RegExp(r'^-+|-+$'), '');
  if (out.isEmpty) return c.id.toLowerCase();
  return out;
}

F1CircuitLocation? findOrbitCircuitByUrlSlug(
  Iterable<F1CircuitLocation> locations,
  String slug,
) {
  final s = slug.trim().toLowerCase();
  if (s.isEmpty) return null;
  for (final c in locations) {
    if (c.id.toLowerCase() == s) return c;
    if (orbitUrlSlugForCircuit(c) == s) return c;
  }
  return null;
}

String orbitGoLocationForCircuit(
  F1CircuitLocation c, {
  bool technical = false,
}) {
  final slug = orbitUrlSlugForCircuit(c);
  if (technical) return '$kOrbitGoPath/$slug/technical';
  return '$kOrbitGoPath/$slug';
}
