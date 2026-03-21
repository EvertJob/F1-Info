/// Utilities for filtering and grouping driver names with case- and
/// diacritic-insensitive comparison, while preserving originals for display.

/// Comprehensive map of accented/Latin characters to ASCII equivalents.
const _diacriticMap = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a', 'Æ': 'ae',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
  'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o', 'Ø': 'o', 'Œ': 'oe',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
  'ý': 'y', 'ÿ': 'y', 'Ý': 'y', 'Ÿ': 'y',
  'ñ': 'n', 'Ñ': 'n',
  'ç': 'c', 'Ç': 'c',
  'ß': 'ss',
  'ř': 'r', 'Ř': 'r',
  'š': 's', 'Š': 's',
  'č': 'c', 'Č': 'c',
  'ž': 'z', 'Ž': 'z',
  'ń': 'n', 'Ń': 'n',
  'ł': 'l', 'Ł': 'l',
};

/// Normalizes a string for case- and diacritic-insensitive comparison.
/// Returns a lowercase ASCII-only string suitable for matching.
///
/// Example: "Sergio Pérez" → "sergio perez", "Müller" → "muller"
String normalizeForComparison(String value) {
  if (value.isEmpty) return value;
  var normalized = value.trim().toLowerCase();
  for (final entry in _diacriticMap.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  // Fallback: strip remaining non-ASCII via regex
  normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
  return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Filters [names] by [query].
/// Comparison is case- and diacritic-insensitive; returned names
/// preserve original formatting (e.g. "Sergio Pérez").
///
/// [query] can match any part of the normalized name (e.g. "perez" or " Perez ").
List<String> filterDriverNames(List<String> names, String query) {
  if (query.trim().isEmpty) return List<String>.from(names);
  final normalizedQuery = normalizeForComparison(query);
  if (normalizedQuery.isEmpty) return List<String>.from(names);

  return names.where((name) {
    final normalizedName = normalizeForComparison(name);
    return normalizedName.contains(normalizedQuery) ||
        normalizedQuery.split(' ').every((part) => normalizedName.contains(part));
  }).toList();
}

/// Groups [names] into those that match [query] and those that don't.
/// Returns a record: `(matched: [...], unmatched: [...])`.
/// Both lists preserve original name strings (e.g. "Sergio Pérez").
({List<String> matched, List<String> unmatched}) groupDriverNamesByMatch(
  List<String> names,
  String query,
) {
  if (query.trim().isEmpty) {
    return (matched: List<String>.from(names), unmatched: <String>[]);
  }
  final normalizedQuery = normalizeForComparison(query);
  if (normalizedQuery.isEmpty) {
    return (matched: List<String>.from(names), unmatched: <String>[]);
  }

  final matched = <String>[];
  final unmatched = <String>[];

  for (final name in names) {
    final normalizedName = normalizeForComparison(name);
    final fits = normalizedName.contains(normalizedQuery) ||
        normalizedQuery.split(' ').every((part) => normalizedName.contains(part));
    if (fits) {
      matched.add(name);
    } else {
      unmatched.add(name);
    }
  }
  return (matched: matched, unmatched: unmatched);
}

/// Groups [names] by the first letter of the normalized name (a–z).
/// Keys are lowercase letters; names preserve original formatting.
Map<String, List<String>> groupDriverNamesByInitial(List<String> names) {
  final groups = <String, List<String>>{};
  for (final name in names) {
    final normalized = normalizeForComparison(name);
    final initial = normalized.isEmpty ? '#' : normalized[0];
    if (!RegExp(r'[a-z0-9]').hasMatch(initial)) continue; // skip non-alphanumeric
    groups.putIfAbsent(initial, () => []).add(name);
  }
  return groups;
}
