/// Normalizes a dynamic segment to lowercase snake_case for ARB / l10n lookup keys.
String l10nNormalizeLookupKey(String raw) {
  var s = raw.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]}_${m[2]}',
  );
  s = s.toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'_+'), '_');
  if (s.startsWith('_')) s = s.substring(1);
  if (s.endsWith('_')) s = s.substring(0, s.length - 1);
  return s;
}
