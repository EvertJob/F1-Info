import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<_NewsItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feeds = [
        'https://racingnews365.nl/feed/news.xml',
        'https://www.formula1.com/en/latest/all.xml',
      ];
      final responses = await Future.wait(
        feeds.map((url) => http.get(Uri.parse(url))),
      );
      final items = <_NewsItem>[];
      for (final response in responses) {
        if (response.statusCode == 200) {
          final xml = XmlDocument.parse(response.body);
          final rssItems = xml.findAllElements('item');
          for (final item in rssItems) {
            final title = item.getElement('title')?.text ?? '';
            final link = item.getElement('link')?.text ?? '';
            final pubDate = item.getElement('pubDate')?.text ?? '';
            final description = item.getElement('description')?.text ?? '';
            items.add(
              _NewsItem(
                title: title,
                link: link,
                pubDate: pubDate,
                description: description,
              ),
            );
          }
        }
      }
      items.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.news_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(context.l10n.news_load_error('$_error')))
          : RefreshIndicator(
              onRefresh: _fetchNews,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        item.pubDate,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        // Open link in browser
                        // ...existing code...
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _NewsItem {
  final String title;
  final String link;
  final String pubDate;
  final String description;

  _NewsItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
  });
}
