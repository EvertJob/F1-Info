import 'package:f1/news_feeds_service.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/foundation.dart' show listEquals;
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

  /// Optimistic order while ReorderableListView animates / before the profile stream catches up.
  List<String>? _pendingFeedOrder;

  /// Invalidates delayed reorder upserts when the user drops again before the delay elapses.
  int _reorderSaveGeneration = 0;

  static const Duration _kReorderPersistDelay = Duration(milliseconds: 420);

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
    _reorderSaveGeneration++;
    setState(() => _busy = true);
    try {
      await NewsFeedsService.instance.upsertFeeds([...current, url]);
      if (mounted) {
        _urlController.clear();
        setState(() => _pendingFeedOrder = [...current, url]);
      }
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
    _reorderSaveGeneration++;
    setState(() => _busy = true);
    try {
      final next = List<String>.from(current)..removeAt(index);
      await NewsFeedsService.instance.upsertFeeds(next);
      if (mounted) setState(() => _pendingFeedOrder = next);
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

  void _onReorderFeeds(List<String> current, int oldIndex, int newIndex) {
    if (_busy) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;
    final next = List<String>.from(current);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);

    // Update data this frame so items do not snap back; avoid upsert until the
    // reorder animation finishes (stream refresh mid-drag triggers framework asserts).
    setState(() => _pendingFeedOrder = next);

    final saveGen = ++_reorderSaveGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_kReorderPersistDelay, () async {
        if (!mounted || saveGen != _reorderSaveGeneration) return;
        if (_busy) return;
        setState(() => _busy = true);
        try {
          await NewsFeedsService.instance.upsertFeeds(next);
        } catch (_) {
          if (mounted) {
            setState(() => _pendingFeedOrder = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.news_settings_save_failed)),
            );
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      });
    });
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
          final streamFeeds = NewsFeedsService.parseNewsFeeds(
            rows.first['news_feeds'],
          );
          if (_pendingFeedOrder != null &&
              listEquals(streamFeeds, _pendingFeedOrder)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _pendingFeedOrder = null);
              }
            });
          }
          final feeds = _pendingFeedOrder ?? streamFeeds;

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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                IgnorePointer(
                  ignoring: _busy,
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: feeds.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorderFeeds(feeds, oldIndex, newIndex),
                    itemBuilder: (context, i) {
                      final url = feeds[i];
                      return Padding(
                        key: ValueKey(url),
                        padding: EdgeInsets.only(
                          bottom: i < feeds.length - 1 ? 6 : 0,
                        ),
                        child: Material(
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Avoid [Tooltip] here: it registers overlay/inherited
                                // dependents that break when the row is reparented during drag.
                                Semantics(
                                  label: context
                                      .l10n
                                      .news_settings_drag_to_reorder,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: ReorderableDragStartListener(
                                      index: i,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          size: 22,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).deleteButtonTooltip,
                                  onPressed: _busy
                                      ? null
                                      : () => _removeAt(feeds, i),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
