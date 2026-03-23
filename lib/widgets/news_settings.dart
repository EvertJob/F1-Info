import 'package:f1/news_feeds_service.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile settings: manage `profiles.news_feeds` with live updates via Supabase stream.
class NewsSettings extends StatefulWidget {
  const NewsSettings({super.key});

  @override
  State<NewsSettings> createState() => _NewsSettingsState();
}

class _NewsSettingsState extends State<NewsSettings> {
  final TextEditingController _urlController = TextEditingController();
  String? _inlineError;
  bool _busy = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidHttpUrl(String raw) {
    final u = Uri.tryParse(raw.trim());
    if (u == null) return false;
    if (u.scheme != 'http' && u.scheme != 'https') return false;
    if (u.host.isEmpty) return false;
    return true;
  }

  Future<void> _addFeed(List<String> current) async {
    final raw = _urlController.text;
    setState(() => _inlineError = null);
    if (!_isValidHttpUrl(raw)) {
      setState(() => _inlineError = context.l10n.news_settings_invalid_url);
      return;
    }
    final url = normalizeNewsFeedUrl(raw.trim());
    if (current.any((e) => normalizeNewsFeedUrl(e.trim()) == url)) {
      setState(() => _inlineError = context.l10n.news_settings_duplicate_url);
      return;
    }
    setState(() => _busy = true);
    try {
      await NewsFeedsService.instance.upsertFeeds([...current, url]);
      if (mounted) _urlController.clear();
    } catch (_) {
      if (mounted) {
        setState(() => _inlineError = context.l10n.news_settings_save_failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAt(List<String> current, int index) async {
    if (index < 0 || index >= current.length) return;
    setState(() => _busy = true);
    try {
      final next = List<String>.from(current)..removeAt(index);
      await NewsFeedsService.instance.upsertFeeds(next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.news_settings_save_failed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return F1Module(
      fillWidth: true,
      padding: const EdgeInsets.all(20),
      borderRadius: kF1ModuleRadius,
      backgroundColor: scheme.surface,
      showFadingBorder: true,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NewsFeedsService.instance.watchProfileFeeds(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              context.l10n.news_settings_stream_error,
              style: TextStyle(color: scheme.error),
            );
          }
          final rows = snapshot.data;
          if (rows == null || rows.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final feeds = NewsFeedsService.parseNewsFeeds(rows.first['news_feeds']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.news_settings_title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.news_settings_subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: context.l10n.news_settings_url_hint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        errorText: _inlineError,
                      ),
                      onSubmitted: (_) => _addFeed(feeds),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _busy ? null : () => _addFeed(feeds),
                    child: Text(context.l10n.news_settings_add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.news_settings_your_feeds,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (feeds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.l10n.news_settings_no_feeds,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feeds.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final url = feeds[i];
                    return Material(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          onPressed: _busy ? null : () => _removeAt(feeds, i),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
