import 'dart:convert';
// import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

Future<List<Map<String, String>>> fetchWikiHistoricalRecords(String targetDriver) async {
  const String wikiApiUrl = 'https://en.wikipedia.org/w/api.php?action=parse&page=List_of_Formula_One_driver_records&format=json&prop=text';
  
  try {
    print('📚 Verbinding maken met Wikipedia API...');
    final response = await http.get(Uri.parse(wikiApiUrl));
    if (response.statusCode != 200) return [];

    // Wikipedia API stopt de HTML in ['parse']['text']['*']
    final json = jsonDecode(response.body);
    final String htmlContent = json['parse']['text']['*'];
    final doc = parse(htmlContent);

    final List<Map<String, String>> foundRecords = [];
    final tables = doc.querySelectorAll('table.wikitable');

    for (var table in tables) {
      // Zoek de titel van de tabel (staat vaak in de H3/H4 erboven)
      var header = table.previousElementSibling;
      while (header != null && !['H3', 'H4', 'H2'].contains(header.localName?.toUpperCase())) {
        header = header.previousElementSibling;
      }
      String sectionTitle = header?.text.trim().replaceAll('[edit]', '') ?? "Record";

      // Alleen relevante "Youngest" of "Points" secties scannen
      if (!sectionTitle.toLowerCase().contains('youngest') && 
          !sectionTitle.toLowerCase().contains('points')) continue;

      final rows = table.querySelectorAll('tr');
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        // Wikipedia recordtabellen: [0] Rank, [1] Driver, [2] Age/Record, [3] Race/Date
        if (cells.length >= 4) {
          final String driverName = cells[1].text.trim();
          
          if (driverName.toLowerCase().contains(targetDriver.toLowerCase())) {
            foundRecords.add({
              "title": sectionTitle,
              "age": cells[2].text.trim(),
              "achievedAt": cells[3].text.trim(),
              // Optioneel: Zoek de vorige recordhouder (vaak de rij onder de huidige in de historie, 
              // of we mappen dit handmatig)
              "previousRecordHolder": "Lewis Hamilton" // Vereenvoudigd voor nu
            });
          }
        }
      }
    }
    return foundRecords;
  } catch (e) {
    print('❌ Wiki Parse Error: $e');
    return [];
  }
}

void main() async {
  final records = await fetchWikiHistoricalRecords('Antonelli');
  
  if (records.isNotEmpty) {
    print('✅ Records gevonden voor Kimi Antonelli:');
    for (var rec in records) {
      print('- ${rec['title']}: ${rec['age']} bij ${rec['achievedAt']}');
    }
  } else {
    print('⚠️ Geen records gevonden. Wellicht is de Wikipedia pagina nog niet bijgewerkt naar de resultaten van maart 2026.');
  }
}