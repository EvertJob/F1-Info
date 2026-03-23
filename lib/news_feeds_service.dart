import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// F1 documented a `results.xml` URL in some setups; that path 404s — use the working latest-news RSS.
const String kF1LatestNewsRssUrl =
    'https://www.formula1.com/en/latest/all.xml';
const String _legacyBrokenF1ResultsUrl =
    'https://www.formula1.com/en/results.xml';

/// 404 — browsers may still show a cached 200 with HTML, so the news list stayed empty.
const String _legacyBrokenF1AllXmlPath = '/en/all.xml';

/// Default when `news_feeds` is null / wrong type (align with DB default after migration fix).
const List<String> kDefaultNewsFeedUrls = [kF1LatestNewsRssUrl];

/// Maps known-broken URLs saved in older profiles to a working feed.
String normalizeNewsFeedUrl(String url) {
  var t = url.trim();
  if (t == _legacyBrokenF1ResultsUrl) return kF1LatestNewsRssUrl;
  final u = Uri.tryParse(t);
  if (u != null &&
      u.hasAbsolutePath &&
      (u.host == 'www.formula1.com' || u.host == 'formula1.com') &&
      u.path.replaceAll(RegExp(r'/+'), '/') == _legacyBrokenF1AllXmlPath) {
    return kF1LatestNewsRssUrl;
  }
  return t;
}

class NewsFeedsService {
  NewsFeedsService._();
  static final NewsFeedsService instance = NewsFeedsService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Parses `profiles.news_feeds` JSONB. Null → defaults; empty list stays empty.
  static List<String> parseNewsFeeds(dynamic value) {
    if (value == null) {
      return List<String>.from(kDefaultNewsFeedUrls);
    }
    if (value is! List) {
      return List<String>.from(kDefaultNewsFeedUrls);
    }
    final out = <String>[];
    for (final e in value) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) out.add(normalizeNewsFeedUrl(s));
    }
    return out;
  }

  /// Reactive row updates for the signed-in user's profile (requires Realtime on `profiles`).
  Stream<List<Map<String, dynamic>>> watchProfileFeeds(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId);
  }

  Future<void> upsertFeeds(List<String> feeds) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').upsert(
        {
          'id': user.id,
          'news_feeds': feeds,
        },
        onConflict: 'id',
      );
    } catch (e) {
      debugPrint('[NewsFeeds] upsertFeeds failed: $e');
      rethrow;
    }
  }
}
