/// ISO 3166-1 alpha-2 from circuit [location] tail (`"City, Country"`).
String circuitIso2FromLocation(String location) {
  final t = location.trim();
  if (t.isEmpty) return '—';
  final comma = t.lastIndexOf(',');
  final country = comma > 0 && comma < t.length - 1
      ? t.substring(comma + 1).trim()
      : t;
  return _iso2ForHostCountry(country);
}

String _iso2ForHostCountry(String country) {
  switch (country.trim()) {
    case 'Australia':
      return 'AU';
    case 'China':
      return 'CN';
    case 'Japan':
      return 'JP';
    case 'Bahrain':
      return 'BH';
    case 'Saudi Arabia':
      return 'SA';
    case 'USA':
      return 'US';
    case 'Canada':
      return 'CA';
    case 'Monaco':
      return 'MC';
    case 'Spain':
      return 'ES';
    case 'Austria':
      return 'AT';
    case 'UK':
      return 'GB';
    case 'Belgium':
      return 'BE';
    case 'Hungary':
      return 'HU';
    case 'Netherlands':
      return 'NL';
    case 'Italy':
      return 'IT';
    case 'Azerbaijan':
      return 'AZ';
    case 'Singapore':
      return 'SG';
    case 'Mexico':
      return 'MX';
    case 'Brazil':
      return 'BR';
    case 'Qatar':
      return 'QA';
    case 'UAE':
      return 'AE';
    default:
      final c = country.trim();
      if (c.length >= 2) {
        return c.substring(0, 2).toUpperCase();
      }
      return '—';
  }
}
