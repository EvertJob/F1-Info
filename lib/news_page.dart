import 'dart:async' show TimeoutException, unawaited;
import 'dart:convert' show utf8;
import 'dart:ui' as ui;

import 'package:f1/browser_bridge.dart';
import 'package:f1/news_feeds_service.dart';
import 'package:f1/theme/f1_theme_tokens.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rss_dart/domain/atom_feed.dart';
import 'package:rss_dart/domain/atom_item.dart';
import 'package:rss_dart/domain/rss1_feed.dart';
import 'package:rss_dart/domain/rss1_item.dart';
import 'package:rss_dart/domain/rss_feed.dart';
import 'package:rss_dart/domain/rss_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RSS/Atom parsing uses [rss_dart] (webfeed fork). `webfeed_plus` conflicts with
/// this app package stack (`intl ^0.20`).
bool _isDesktopShellLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 600;

/// Many RSS hosts block non-browser user agents; proxies also behave better with this.
const String _kRssBrowserUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

const Duration _kFeedFetchTimeout = Duration(seconds: 28);

String _stripHtml(String raw) {
  return raw
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

DateTime? _parseFeedDate(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  try {
    return parseHttpDate(t);
  } catch (_) {
    return DateTime.tryParse(t);
  }
}

Uri _allOriginsUri(String feedUrl) {
  final enc = Uri.encodeComponent(feedUrl);
  // Avoid stale disk-cache 200s (e.g. old HTML/404 bodies) breaking the parser.
  final cb = DateTime.now().millisecondsSinceEpoch;
  return Uri.parse('https://api.allorigins.win/raw?url=$enc&nocache=$cb');
}

Uri _corsProxyIoUri(String feedUrl) {
  return Uri.parse(
    'https://corsproxy.io/?${Uri.encodeComponent(feedUrl)}',
  );
}

bool _looksLikeFeedMarkup(String body) {
  if (body.isEmpty) return false;
  var s = body.trimLeft();
  if (s.startsWith('\uFEFF')) s = s.substring(1).trimLeft();
  final headLen = s.length > 800 ? 800 : s.length;
  final head = s.substring(0, headLen).toLowerCase();
  return head.contains('<rss') || head.contains('<feed');
}

bool _looksLikeHtmlDocument(String body) {
  final lower = body.toLowerCase();
  return lower.contains('<!doctype') ||
      lower.contains('<html') ||
      lower.contains('<head>');
}

String? _atomItemLink(AtomItem item) {
  for (final l in item.links) {
    final rel = l.rel;
    if (rel == null || rel == 'alternate') {
      final h = l.href?.trim();
      if (h != null && h.isNotEmpty) return h;
    }
  }
  for (final l in item.links) {
    final h = l.href?.trim();
    if (h != null && h.isNotEmpty) return h;
  }
  final id = item.id?.trim();
  if (id != null && id.isNotEmpty && id.startsWith('http')) return id;
  return null;
}

String? _atomItemAuthor(AtomItem item) {
  if (item.authors.isEmpty) return null;
  return item.authors.first.name?.trim();
}

List<NewsArticle> _articlesFromRssXml(String xml, {required String sourceUrl}) {
  try {
    final feed = RssFeed.parse(xml);
    final host = Uri.tryParse(sourceUrl)?.host ?? '';
    final out = <NewsArticle>[];
    for (final RssItem item in feed.items) {
      final title = item.title?.trim() ?? '';
      var link = item.link?.trim() ?? '';
      if (link.isEmpty) {
        final g = item.guid?.trim() ?? '';
        if (g.startsWith('http')) link = g;
      }
      if (title.isEmpty || link.isEmpty) continue;
      final desc = _stripHtml(item.description ?? '');
      final author = item.author?.trim().isNotEmpty == true
          ? item.author!.trim()
          : item.dc?.creator?.trim();
      out.add(
        NewsArticle(
          title: title,
          link: link,
          description: desc,
          author: author,
          published: _parseFeedDate(item.pubDate),
          sourceLabel: host,
        ),
      );
    }
    return out;
  } catch (_) {
    return _articlesFromAtomXml(xml, sourceUrl: sourceUrl);
  }
}

List<NewsArticle> _articlesFromAtomXml(String xml, {required String sourceUrl}) {
  try {
    final feed = AtomFeed.parse(xml);
    final host = Uri.tryParse(sourceUrl)?.host ?? '';
    final out = <NewsArticle>[];
    for (final AtomItem item in feed.items) {
      final link = _atomItemLink(item);
      final title = item.title?.trim() ?? '';
      if (link == null || title.isEmpty) continue;
      final desc = _stripHtml(
        (item.summary ?? item.content ?? '').trim(),
      );
      final dateRaw = item.published ?? item.updated;
      out.add(
        NewsArticle(
          title: title,
          link: link,
          description: desc,
          author: _atomItemAuthor(item),
          published: _parseFeedDate(dateRaw),
          sourceLabel: host,
        ),
      );
    }
    return out;
  } catch (_) {
    return _articlesFromRss1Xml(xml, sourceUrl: sourceUrl);
  }
}

List<NewsArticle> _articlesFromRss1Xml(String xml, {required String sourceUrl}) {
  try {
    final feed = Rss1Feed.parse(xml);
    final host = Uri.tryParse(sourceUrl)?.host ?? '';
    final out = <NewsArticle>[];
    for (final Rss1Item item in feed.items) {
      final title = item.title?.trim() ?? '';
      var link = item.link?.trim() ?? '';
      if (title.isEmpty || link.isEmpty) continue;
      final desc = _stripHtml(item.description ?? '');
      final author = item.dc?.creator?.trim();
      out.add(
        NewsArticle(
          title: title,
          link: link,
          description: desc,
          author: author,
          published: _parseFeedDate(item.dc?.date),
          sourceLabel: host,
        ),
      );
    }
    return out;
  } catch (_) {
    return [];
  }
}

Future<http.Response?> _httpGetFeed(Uri uri, Map<String, String> headers) async {
  try {
    return await http
        .get(uri, headers: headers)
        .timeout(
          _kFeedFetchTimeout,
          onTimeout: () => throw TimeoutException('RSS fetch', _kFeedFetchTimeout),
        );
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<FeedResult> _fetchSingleFeed(String feedUrl) async {
  final headers = {
    'User-Agent': _kRssBrowserUserAgent,
    'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
  };

  List<NewsArticle> parseBodyBytes(List<int> bytes) {
    return _articlesFromRssXml(utf8.decode(bytes), sourceUrl: feedUrl);
  }

  try {
    if (kIsWeb) {
      // At most two HTTP calls per feed: corsproxy first, allorigins only if the first
      // response is missing, non-200, or clearly not feed XML (HTML error page, etc.).
      List<NewsArticle> tryParse(http.Response? r) {
        if (r == null || r.statusCode != 200) return [];
        return parseBodyBytes(r.bodyBytes);
      }

      bool bodySuggestsRetryOtherProxy(List<int> bytes) {
        final s = utf8.decode(bytes);
        return !_looksLikeFeedMarkup(s) || _looksLikeHtmlDocument(s);
      }

      final rCors = await _httpGetFeed(_corsProxyIoUri(feedUrl), headers);
      var articles = tryParse(rCors);
      if (articles.isNotEmpty) {
        return FeedResult(feedUrl: feedUrl, articles: articles);
      }

      final tryAllOrigins = rCors == null ||
          rCors.statusCode != 200 ||
          bodySuggestsRetryOtherProxy(rCors.bodyBytes);
      if (!tryAllOrigins) {
        return FeedResult(feedUrl: feedUrl, articles: articles);
      }

      final rAo = await _httpGetFeed(_allOriginsUri(feedUrl), headers);
      articles = tryParse(rAo);
      return FeedResult(feedUrl: feedUrl, articles: articles);
    }

    final r = await _httpGetFeed(Uri.parse(feedUrl), headers);
    if (r == null || r.statusCode != 200) {
      return FeedResult(feedUrl: feedUrl, articles: const []);
    }
    return FeedResult(
      feedUrl: feedUrl,
      articles: parseBodyBytes(r.bodyBytes),
    );
  } catch (_) {
    return FeedResult(feedUrl: feedUrl, articles: const []);
  }
}

String _feedSectionHeading(String feedUrl) {
  final u = Uri.tryParse(feedUrl);
  if (u != null && u.hasAuthority) {
    var host = u.host;
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    if (host.isNotEmpty) return host;
  }
  return feedUrl;
}

int _compareArticlesByDateDesc(NewsArticle a, NewsArticle b) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final da = a.published ?? epoch;
  final db = b.published ?? epoch;
  final c = db.compareTo(da);
  if (c != 0) return c;
  return a.title.compareTo(b.title);
}

Future<List<FeedResult>> _fetchAllFeedsOrdered(List<String> urls) async {
  if (urls.isEmpty) return [];
  final results = await Future.wait(urls.map(_fetchSingleFeed));
  return results
      .map((fr) {
        final sorted = List<NewsArticle>.from(fr.articles)
          ..sort(_compareArticlesByDateDesc);
        return FeedResult(feedUrl: fr.feedUrl, articles: sorted);
      })
      .toList(growable: false);
}

/// Public model for tests / reuse.
@immutable
class FeedResult {
  const FeedResult({
    required this.feedUrl,
    required this.articles,
  });

  final String feedUrl;
  final List<NewsArticle> articles;
}

@immutable
class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.link,
    required this.description,
    this.author,
    this.published,
    this.sourceLabel = '',
  });

  final String title;
  final String link;
  final String description;
  final String? author;
  final DateTime? published;
  final String sourceLabel;
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return NewsFeedView(
        feedUrls: List<String>.from(kDefaultNewsFeedUrls),
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NewsFeedsService.instance.watchProfileFeeds(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _NewsLoadingShell();
        }
        if (snapshot.hasError) {
          return NewsFeedView(
            feedUrls: List<String>.from(kDefaultNewsFeedUrls),
            streamError: snapshot.error,
          );
        }
        final rows = snapshot.data;
        List<String> urls = List<String>.from(kDefaultNewsFeedUrls);
        if (rows != null && rows.isNotEmpty) {
          urls = NewsFeedsService.parseNewsFeeds(rows.first['news_feeds']);
        }
        return NewsFeedView(
          key: ValueKey<String>(urls.join('|')),
          feedUrls: urls,
        );
      },
    );
  }
}

class _NewsLoadingShell extends StatelessWidget {
  const _NewsLoadingShell();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    return Scaffold(
      backgroundColor: desktopShell ? Colors.transparent : null,
      appBar: AppBar(
        title: Text(context.l10n.news_title),
        backgroundColor: desktopShell ? Colors.transparent : null,
        elevation: desktopShell ? 0 : null,
        scrolledUnderElevation: desktopShell ? 0 : null,
        foregroundColor: desktopShell ? scheme.onSurface : null,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class NewsFeedView extends StatefulWidget {
  const NewsFeedView({
    super.key,
    required this.feedUrls,
    this.streamError,
  });

  final List<String> feedUrls;
  final Object? streamError;

  @override
  State<NewsFeedView> createState() => _NewsFeedViewState();
}

class _NewsFeedViewState extends State<NewsFeedView> {
  List<FeedResult> _sections = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NewsFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameUrlLists(oldWidget.feedUrls, widget.feedUrls)) {
      unawaited(_load());
    }
  }

  bool _sameUrlLists(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sections = await _fetchAllFeedsOrdered(widget.feedUrls);
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openArticle(String url) => openExternalUrl(url);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final f1Ui = theme.extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final tokens = theme.extension<F1ThemeTokens>();
    final panelStrong =
        tokens?.panelStrong ?? scheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: desktopShell ? Colors.transparent : null,
      appBar: AppBar(
        title: Text(context.l10n.news_title),
        backgroundColor: desktopShell ? Colors.transparent : null,
        elevation: desktopShell ? 0 : null,
        scrolledUnderElevation: desktopShell ? 0 : null,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip:
                MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.streamError != null)
            Material(
              color: scheme.errorContainer.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  context.l10n.news_load_error('${widget.streamError}'),
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.news_load_error(_error!),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: widget.feedUrls.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.2,
                              ),
                              Text(
                                context.l10n.news_empty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              for (final section in _sections) ...[
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _feedSectionHeading(section.feedUrl),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 0.8,
                                            color: scheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          section.feedUrl,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (section.articles.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        20,
                                      ),
                                      child: Text(
                                        context.l10n.news_feed_section_empty,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      8,
                                    ),
                                    sliver: SliverList(
                                      delegate:
                                          SliverChildBuilderDelegate(
                                        (context, index) {
                                          final item =
                                              section.articles[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: _NewsGlassArticleTile(
                                              article: item,
                                              f1Ui: f1Ui,
                                              panelStrong: panelStrong,
                                              isDark: theme.brightness ==
                                                  Brightness.dark,
                                              onTap: () =>
                                                  _openArticle(item.link),
                                            ),
                                          );
                                        },
                                        childCount: section.articles.length,
                                      ),
                                    ),
                                  ),
                              ],
                              const SliverPadding(
                                padding: EdgeInsets.only(bottom: 16),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NewsGlassArticleTile extends StatelessWidget {
  const _NewsGlassArticleTile({
    required this.article,
    required this.f1Ui,
    required this.panelStrong,
    required this.isDark,
    required this.onTap,
  });

  final NewsArticle article;
  final F1UiTheme f1Ui;
  final Color panelStrong;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = f1Ui.cardBorderRadius.clamp(12.0, 24.0);

    final metaBits = <String>[
      if (article.author != null && article.author!.isNotEmpty)
        article.author!,
      if (article.published != null)
        MaterialLocalizations.of(context).formatShortDate(article.published!),
      if (article.sourceLabel.isNotEmpty) article.sourceLabel,
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.4,
            height: 1.25,
            color: scheme.onSurface,
          ),
        ),
        if (metaBits.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            metaBits.join(' · '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (article.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            article.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    Widget tile({
      required Color bg,
      required List<BoxShadow>? shadow,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: F1Module(
            fillWidth: true,
            borderRadius: radius,
            backgroundColor: bg,
            showFadingBorder: true,
            boxShadow: shadow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: content,
            ),
          ),
        ),
      );
    }

    if (f1Ui.glassBlur <= 0) {
      return tile(
        bg: scheme.surface,
        shadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      );
    }

    final glassFill = panelStrong.withValues(
      alpha: isDark ? 0.42 : 0.55,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: f1Ui.glassBlur * 0.45,
          sigmaY: f1Ui.glassBlur * 0.45,
        ),
        child: tile(
          bg: glassFill,
          shadow: f1Ui.moduleShadow,
        ),
      ),
    );
  }
}
