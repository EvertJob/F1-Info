import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/f1_team_schemes.dart';
import '../util/share_og_meta.dart';
import '../utils/l10n_extension.dart';
import 'championship_simulator_controller.dart';
import 'simulator_ambient.dart';
import 'simulator_glass.dart';
import 'simulator_grid_config.dart';
import 'simulator_models.dart';
import 'simulator_sync_service.dart';

/// Read-only simulator deep link for [shareHandle], matching web [HashUrlStrategy].
String simulatorReadOnlyShareUrlForHandle(String shareHandle) {
  final h = SimulatorSyncService.normalizeShareHandle(shareHandle);
  final loc = '/s/${Uri.encodeComponent(h)}';
  if (!kIsWeb) {
    return 'https://f1hub.app$loc';
  }
  final u = Uri.base;
  final origin = u.origin;
  var pathPrefix = u.path;
  if (pathPrefix.isEmpty) pathPrefix = '/';
  return '$origin$pathPrefix#$loc';
}

bool _sameSimulatorRoundInputs(
  List<SimulatorRoundInput> a,
  List<SimulatorRoundInput> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.circuitId != y.circuitId) return false;
    if (x.hasActualResults != y.hasActualResults) return false;
    if (x.isCancelled != y.isCancelled) return false;
    if (x.hasSprint != y.hasSprint) return false;
    if (x.actualRows.length != y.actualRows.length) return false;
    if (x.sprintActualRows.length != y.sprintActualRows.length) return false;
  }
  return true;
}

/// 2026 championship simulator — hybrid JSON results + local predictions.
class ChampionshipSimulatorPage extends StatefulWidget {
  const ChampionshipSimulatorPage({
    super.key,
    required this.roundInputs,
    required this.driverRefs,
    this.readOnly = false,
    this.initialRemoteRows,
    this.bannerUsername,
    this.sharedPreviewFromLocalDraft = false,
  });

  final List<SimulatorRoundInput> roundInputs;
  final List<SimulatorDriverRef> driverRefs;
  final bool readOnly;
  /// When set (e.g. shared link), skips local draft and applies these rows only.
  final List<Map<String, dynamic>>? initialRemoteRows;
  /// Shown as read-only banner (e.g. shared profile handle).
  final String? bannerUsername;
  /// Shared `/s/…` view used on-device draft because cloud had no rows yet.
  final bool sharedPreviewFromLocalDraft;

  @override
  State<ChampionshipSimulatorPage> createState() =>
      _ChampionshipSimulatorPageState();
}

class _ChampionshipSimulatorPageState extends State<ChampionshipSimulatorPage> {
  late final ChampionshipSimulatorController _controller;
  final GlobalKey _standingsCaptureKey = GlobalKey();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
    _controller = ChampionshipSimulatorController(
      rounds: widget.roundInputs,
      drivers: widget.driverRefs,
      readOnly: widget.readOnly,
      starterBonusFirstThreeRounds: !widget.readOnly,
    );
    if (widget.readOnly &&
        widget.initialRemoteRows != null &&
        widget.initialRemoteRows!.isNotEmpty) {
      _controller.applySharedRemoteRows(widget.initialRemoteRows!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDraft();
    });
  }

  @override
  void didUpdateWidget(ChampionshipSimulatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSimulatorRoundInputs(oldWidget.roundInputs, widget.roundInputs)) {
      _controller.updateRoundsFromHost(widget.roundInputs);
    }
    if (oldWidget.readOnly != widget.readOnly) {
      _controller.applyHostReadOnly(widget.readOnly);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showFullGridDialog(BuildContext context) {
    if (widget.readOnly) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (ctx) => _FullGridDialog(controller: _controller),
    );
  }

  String _shareHandle() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return 'fan';
    final m = u.userMetadata;
    final n = m?['user_name'] ??
        m?['preferred_username'] ??
        m?['full_name'] ??
        m?['name'] ??
        m?['username'] ??
        m?['nickname'];
    if (n is String && n.trim().isNotEmpty) return n.trim();
    final e = u.email;
    if (e != null && e.contains('@')) {
      return e.split('@').first;
    }
    return 'fan';
  }

  /// Standings snapshot watermark: gedeelde `/s/…` toont [bannerUsername], anders ingelogde gebruiker.
  String _watermarkHandle() {
    final b = widget.bannerUsername?.trim();
    if (b != null && b.isNotEmpty) return b;
    return _shareHandle();
  }

  String? _clinchCaption() {
    final idx = _controller.magicNumberClinchRoundIndex();
    if (idx == null) return null;
    final r = _controller.rounds[idx];
    return '${r.displayName} · ${r.grandPrixName}';
  }

  Future<void> _captureStandingsSnapshot() async {
    final boundary =
        _standingsCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    try {
      final image = await boundary.toImage(pixelRatio: dpr);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || bytes == null) return;
      final uint8List = bytes.buffer.asUint8List();
      await Share.shareXFiles(
        [
          XFile.fromData(
            uint8List,
            name: 'f1hub-standings.png',
            mimeType: 'image/png',
          ),
        ],
        text: 'f1hub.app',
      );
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.simulator_snapshot_copied_hint)),
      );
    } catch (e) {
      debugPrint('[Simulator] capture failed: $e');
    }
  }

  Future<void> _shareReadOnlySimulatorLink() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (Supabase.instance.client.auth.currentUser == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.simulator_share_readonly_need_login)),
      );
      return;
    }
    final url = simulatorReadOnlyShareUrlForHandle(_shareHandle());
    try {
      await Share.share(
        url,
        subject: l10n.simulator_share_readonly_subject,
      );
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.simulator_share_readonly_snackbar)),
      );
    } catch (e) {
      debugPrint('[Simulator] share link failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final acc = _controller.seasonP1AccuracyPercent();
        final accLabel = l10n.simulator_p1_accuracy_percent(acc.round());
        final statsLine = l10n.simulator_stats_line(
          _controller.seasonPredictionPointsTotal(),
          _controller.seasonGridAccuracyPercent().round(),
          acc.round(),
        );
        final signedIn =
            Supabase.instance.client.auth.currentUser != null;
        return SimulatorAmbientBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.simulator_title),
                  Text(
                    accLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                if (!widget.readOnly) ...[
                  if (signedIn)
                    IconButton(
                      tooltip: l10n.simulator_share_readonly_tooltip,
                      onPressed: _shareReadOnlySimulatorLink,
                      icon: const Icon(Icons.link_rounded),
                    ),
                  IconButton(
                    tooltip: l10n.simulator_snapshot_tooltip,
                    onPressed: _captureStandingsSnapshot,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.simulator_sync_official,
                    onPressed: () {
                      _controller.resyncCompletedRoundsFromActual();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.simulator_sync_official_done)),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.simulator_undo,
                    onPressed:
                        _controller.canUndo ? () => _controller.undo() : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _controller.persistDraft();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.simulator_save_draft)),
                        );
                      }
                    },
                    child: Text(l10n.simulator_save_draft),
                  ),
                ],
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.bannerUsername != null &&
                    widget.bannerUsername!.trim().isNotEmpty)
                  Material(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.45),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${l10n.simulator_readonly_banner} · @${widget.bannerUsername}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (widget.sharedPreviewFromLocalDraft) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.simulator_share_local_preview,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 960;
                        final pad = const EdgeInsets.symmetric(horizontal: 16);
                        if (wide) {
                          return Padding(
                            padding: pad,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _TimelinePanel(controller: _controller),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _PodiumSection(
                                          controller: _controller,
                                          readOnly: widget.readOnly,
                                          expandGlass: true,
                                          onOpenFullGrid: widget.readOnly ||
                                                  _controller.selectedRound.isCancelled
                                              ? null
                                              : () => _showFullGridDialog(context),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _StewardStrip(controller: _controller),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: _StandingsPanel(
                                    controller: _controller,
                                    captureKey: _standingsCaptureKey,
                                    watermarkLine:
                                        'f1hub.app · ${l10n.simulator_prediction_by(_watermarkHandle())} · $statsLine',
                                    clinchCaption: _clinchCaption(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: pad.copyWith(bottom: 24),
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            return switch (i) {
                              0 => _TimelinePanel(
                                    controller: _controller,
                                    listHeight: 300,
                                  ),
                              1 => _PodiumSection(
                                    controller: _controller,
                                    readOnly: widget.readOnly,
                                    expandGlass: false,
                                    onOpenFullGrid: widget.readOnly ||
                                            _controller.selectedRound.isCancelled
                                        ? null
                                        : () => _showFullGridDialog(context),
                                  ),
                              2 => _StewardStrip(controller: _controller),
                              _ => _StandingsPanel(
                                    controller: _controller,
                                    listHeight: 340,
                                    captureKey: _standingsCaptureKey,
                                    watermarkLine:
                                        'f1hub.app · ${l10n.simulator_prediction_by(_watermarkHandle())} · $statsLine',
                                    clinchCaption: _clinchCaption(),
                                  ),
                            };
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.controller,
    this.listHeight,
  });

  final ChampionshipSimulatorController controller;
  /// When set (e.g. mobile stack), list is scrollable with fixed height.
  final double? listHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final magicIdx = controller.magicNumberClinchRoundIndex();

    final list = ListView.separated(
      shrinkWrap: listHeight != null,
      physics: listHeight != null
          ? const ClampingScrollPhysics()
          : null,
      itemCount: controller.rounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = controller.rounds[index];
        final sel = controller.selectedRoundIndex == index;
        final magic = magicIdx == index;
        final p1Hit = controller.p1MatchForRound(r);
        Widget? splitBadge;
        if (r.hasActualResults && p1Hit != null) {
          splitBadge = Tooltip(
            message: l10n.simulator_accuracy,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_circle_outlined, size: 15, color: scheme.primary),
                const SizedBox(width: 3),
                Icon(
                  Icons.psychology_outlined,
                  size: 15,
                  color: p1Hit ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                ),
              ],
            ),
          );
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.35),
              width: sel ? 2 : 1,
            ),
            color: magic
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surface.withValues(alpha: 0.2),
          ),
          child: ListTile(
            dense: true,
            leading: splitBadge,
            title: Text(
              r.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${l10n.simulator_round(r.roundIndex)} · ${r.grandPrixName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            trailing: Icon(
              r.isCancelled
                  ? Icons.cancel_outlined
                  : r.hasActualResults
                      ? Icons.verified_rounded
                      : Icons.edit_note_rounded,
              size: 20,
              color: r.isCancelled
                  ? scheme.error
                  : r.hasActualResults
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
            ),
            onTap: () => controller.selectRound(index),
          ),
        );
      },
    );

    return SimulatorGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.simulator_timeline,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.simulator_magic_clinch,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          if (listHeight != null)
            SizedBox(height: listHeight, child: list)
          else
            Expanded(child: list),
        ],
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({
    required this.controller,
    required this.readOnly,
    this.expandGlass = true,
    this.onOpenFullGrid,
  });

  final ChampionshipSimulatorController controller;
  /// Host [ChampionshipSimulatorPage.readOnly] — source of truth for drag/drop UI.
  final bool readOnly;
  final bool expandGlass;
  final VoidCallback? onOpenFullGrid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final round = controller.selectedRound;
    final circuitId = round.circuitId;
    final pod = controller.podiumForCircuit(circuitId);
    final act = controller.actualTopThree(round);
    final podiumInteractive = !readOnly && !round.hasActualResults;

    final podiumCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                round.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _CircuitStatusTrailing(controller: controller, round: round),
            if (onOpenFullGrid != null)
              IconButton(
                tooltip: l10n.simulator_open_full_grid,
                visualDensity: VisualDensity.compact,
                onPressed: onOpenFullGrid,
                icon: const Icon(Icons.open_in_new_rounded, size: 22),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (podiumInteractive) ...[
          Text(
            l10n.simulator_podium_hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
        ],
        _DriverPalette(
          controller: controller,
          circuitId: circuitId,
          readOnly: !podiumInteractive,
        ),
        const SizedBox(height: 16),
        _PodiumRow(
          roster: controller.drivers,
          labels: const ['P1', 'P2', 'P3'],
          drivers: pod,
          readOnly: !podiumInteractive,
          onAssign: (slot, driverName) =>
              controller.assignPodiumSlot(circuitId, slot, driverName),
        ),
      ],
    );

    /// Scroll buiten [SimulatorGlassPanel]: anders vult [Expanded] het paneel over de
    /// hele kolomhoogte en zit de fading border onderaan het scherm i.p.v. onder de kaart.
    final Widget glass = expandGlass
        ? Expanded(
            child: SingleChildScrollView(
              child: SimulatorGlassPanel(child: podiumCard),
            ),
          )
        : SimulatorGlassPanel(child: podiumCard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expandGlass ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (round.hasActualResults)
          _SplitActualPredictionCard(
            actual: act,
            predicted: pod,
            roster: controller.drivers,
            readOnly: readOnly,
            podiumAccuracyPercentOverride:
                controller.starterBonusAppliesToRound(round) ? 100 : null,
          ),
        if (round.hasActualResults) const SizedBox(height: 12),
        glass,
      ],
    );
  }
}

class _SplitActualPredictionCard extends StatelessWidget {
  const _SplitActualPredictionCard({
    required this.actual,
    required this.predicted,
    required this.roster,
    required this.readOnly,
    this.podiumAccuracyPercentOverride,
  });

  final List<String> actual;
  final List<String> predicted;
  final List<SimulatorDriverRef> roster;
  final bool readOnly;
  /// When set (e.g. starter rounds 1–3 for signed-in users), shown instead of real podium match %.
  final double? podiumAccuracyPercentOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SimulatorGlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.simulator_accuracy,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (!readOnly)
                Chip(
                  label: Text(
                    '${(podiumAccuracyPercentOverride ?? _accuracy(actual, predicted, roster)).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniPodiumColumn(
                  title: l10n.simulator_actual,
                  names: [
                    for (final n in actual)
                      canonicalSimulatorDriverName(n, roster),
                  ],
                  icon: Icons.flag_circle_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: scheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _MiniPodiumColumn(
                  title: l10n.simulator_prediction,
                  names: [
                    for (final n in predicted)
                      canonicalSimulatorDriverName(n, roster),
                  ],
                  icon: Icons.psychology_alt_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _accuracy(
    List<String> a,
    List<String> p,
    List<SimulatorDriverRef> roster,
  ) {
    var t = 0;
    var h = 0;
    for (var i = 0; i < 3 && i < a.length && i < p.length; i++) {
      t++;
      if (simulatorDriverNamesMatch(a[i], p[i], roster)) h++;
    }
    if (t == 0) return 100;
    return 100 * h / t;
  }
}

class _MiniPodiumColumn extends StatelessWidget {
  const _MiniPodiumColumn({
    required this.title,
    required this.names,
    required this.icon,
  });

  final String title;
  final List<String> names;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++)
          Text(
            i < names.length ? names[i] : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _DriverPalette extends StatelessWidget {
  const _DriverPalette({
    required this.controller,
    required this.circuitId,
    required this.readOnly,
  });

  final ChampionshipSimulatorController controller;
  final String circuitId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.drivers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = controller.drivers[i];
          final path = simulatorDriverPortraitPath(d.name, controller.drivers);
          final child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  path,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text(
                      d.name.isNotEmpty ? d.name[0] : '?',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                child: Text(
                  d.name.split(' ').last,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          );

          if (readOnly) return child;

          return Draggable<String>(
            data: d.name,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(40),
              child: ClipOval(
                child: Image.asset(
                  path,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 28,
                    child: Text(d.name.isNotEmpty ? d.name[0] : '?'),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: child),
            child: child,
          );
        },
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  const _PodiumRow({
    required this.roster,
    required this.labels,
    required this.drivers,
    required this.readOnly,
    required this.onAssign,
  });

  final List<SimulatorDriverRef> roster;
  final List<String> labels;
  final List<String> drivers;
  final bool readOnly;
  final void Function(int slot, String driverName) onAssign;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var slot = 0; slot < 3; slot++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PodiumSlotTile(
                slot: slot,
                labels: labels,
                rawName: slot < drivers.length ? drivers[slot] : '',
                roster: roster,
                readOnly: readOnly,
                onAssign: onAssign,
              ),
            ),
          ),
      ],
    );
  }
}

class _PodiumSlotTile extends StatelessWidget {
  const _PodiumSlotTile({
    required this.slot,
    required this.labels,
    required this.rawName,
    required this.roster,
    required this.readOnly,
    required this.onAssign,
  });

  final int slot;
  final List<String> labels;
  final String rawName;
  final List<SimulatorDriverRef> roster;
  final bool readOnly;
  final void Function(int slot, String driverName) onAssign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = rawName.isEmpty
        ? ''
        : canonicalSimulatorDriverName(rawName, roster);
    final portraitPath = displayName.isEmpty
        ? ''
        : simulatorDriverPortraitPath(displayName, roster);

    Widget slotBody(bool elevated) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: elevated
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.35),
            width: elevated ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: elevated ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (displayName.isNotEmpty)
              Image.asset(
                portraitPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              ),
            if (displayName.isNotEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.scrim.withValues(alpha: 0.05),
                      scheme.scrim.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withValues(alpha: 0.45),
                      scheme.surface.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[slot],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: displayName.isEmpty
                              ? scheme.primary
                              : Colors.white.withValues(alpha: 0.95),
                          shadows: displayName.isNotEmpty
                              ? const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Color(0x88000000),
                                  ),
                                ]
                              : null,
                        ),
                  ),
                  const SizedBox(height: 6),
                  if (displayName.isEmpty)
                    Icon(
                      readOnly
                          ? Icons.lock_outline_rounded
                          : Icons.drag_indicator_rounded,
                      color: scheme.onSurfaceVariant,
                    )
                  else
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                        color: Colors.white.withValues(alpha: 0.98),
                        shadows: const [
                          Shadow(blurRadius: 10, color: Color(0x99000000)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (readOnly) {
      return slotBody(false);
    }

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAssign(slot, details.data),
      builder: (context, candidate, rejected) {
        return slotBody(candidate.isNotEmpty);
      },
    );
  }
}

class _StewardStrip extends StatelessWidget {
  const _StewardStrip({required this.controller});

  final ChampionshipSimulatorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cid = controller.selectedCircuitId;
    final round = controller.selectedRound;
    if (round.hasActualResults) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final standings = controller.stewardStandingsForCircuit(cid);
        return SimulatorGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.simulator_steward_title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.simulator_steward_hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: standings.length,
                  itemBuilder: (context, i) {
                    final s = standings[i];
                    final path =
                        simulatorDriverPortraitPath(s.driver.name, controller.drivers);
                    final stripe = F1TeamSchemes.getTeamColor(s.driver.team);
                    final initials = s.driver.name.isNotEmpty
                        ? s.driver.name
                            .split(' ')
                            .where((e) => e.isNotEmpty)
                            .map((e) => e[0])
                            .take(2)
                            .join()
                        : '?';
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${s.driver.name}_${s.finishRank}_${s.virtualMillis}'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: Theme.of(context).brightness == Brightness.dark
                                  ? 0.35
                                  : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Text(
                                      '${s.finishRank}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: stripe,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ClipOval(
                                    child: Image.asset(
                                      path,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            scheme.surfaceContainerHighest,
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.driver.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          s.isDnf
                                              ? 'DNF'
                                              : '+${s.penaltySeconds}s · GP ${s.weekendGpPoints}${round.hasSprint ? ' · SP ${s.weekendSprintPoints}' : ''}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!controller.readOnly) ...[
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                        minHeight: 32,
                                      ),
                                      tooltip: '+5s',
                                      onPressed: () => controller.togglePenaltySeconds(
                                            cid,
                                            s.driver.name,
                                            5,
                                          ),
                                      icon: const Icon(Icons.exposure_plus_1, size: 18),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                        minHeight: 32,
                                      ),
                                      tooltip: '+10s',
                                      onPressed: () => controller.togglePenaltySeconds(
                                            cid,
                                            s.driver.name,
                                            10,
                                          ),
                                      icon: const Icon(Icons.add_alarm, size: 18),
                                    ),
                                    FilterChip(
                                      label: const Text('DNF', style: TextStyle(fontSize: 10)),
                                      selected: s.isDnf,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (_) => controller.toggleDnf(
                                            cid,
                                            s.driver.name,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StandingsPanel extends StatelessWidget {
  const _StandingsPanel({
    required this.controller,
    this.listHeight,
    this.captureKey,
    this.watermarkLine,
    this.clinchCaption,
  });

  final ChampionshipSimulatorController controller;
  final double? listHeight;
  final GlobalKey? captureKey;
  final String? watermarkLine;
  final String? clinchCaption;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = controller.seasonStandingsLeaderboard();
    final scheme = Theme.of(context).colorScheme;

    final list = ListView.separated(
      shrinkWrap: listHeight != null,
      physics: listHeight != null
          ? const ClampingScrollPhysics()
          : null,
      itemCount: board.length.clamp(0, 22),
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final e = board[i];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey('${e.key}_${e.value}'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.surface.withValues(alpha: 0.25),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clinchCaption != null && clinchCaption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.simulator_clinch_in(clinchCaption!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (watermarkLine != null && watermarkLine!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            watermarkLine!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
          ),
        ],
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.simulator_standings,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.simulator_consensus_stub,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        if (listHeight != null)
          SizedBox(height: listHeight, child: list)
        else
          Expanded(child: list),
        footer,
      ],
    );

    final wrapped = captureKey != null
        ? RepaintBoundary(key: captureKey, child: column)
        : column;

    return SimulatorGlassPanel(child: wrapped);
  }
}

class _CircuitStatusTrailing extends StatefulWidget {
  const _CircuitStatusTrailing({
    required this.controller,
    required this.round,
  });

  final ChampionshipSimulatorController controller;
  final SimulatorRoundInput round;

  @override
  State<_CircuitStatusTrailing> createState() => _CircuitStatusTrailingState();
}

class _CircuitStatusTrailingState extends State<_CircuitStatusTrailing> {
  bool? _sessionLocked;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _CircuitStatusTrailing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.round.circuitId != widget.round.circuitId) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final r = widget.round;
    if (!mounted) return;
    if (r.hasActualResults || r.isCancelled) {
      setState(() => _sessionLocked = null);
      return;
    }
    final editable = await widget.controller.isGpGridEditable();
    if (mounted) setState(() => _sessionLocked = !editable);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.round;
    if (r.isCancelled) {
      return Tooltip(
        message: context.l10n.simulator_race_cancelled,
        child: Icon(Icons.cancel_outlined, color: scheme.error, size: 22),
      );
    }
    if (r.hasActualResults) return const SizedBox.shrink();
    if (_sessionLocked == true) {
      return Tooltip(
        message: context.l10n.simulator_session_locked,
        child: Icon(Icons.lock_clock_outlined, color: scheme.tertiary, size: 22),
      );
    }
    return const SizedBox.shrink();
  }
}

class _FullGridDialog extends StatefulWidget {
  const _FullGridDialog({required this.controller});

  final ChampionshipSimulatorController controller;

  @override
  State<_FullGridDialog> createState() => _FullGridDialogState();
}

class _FullGridDialogState extends State<_FullGridDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final hasSprint = widget.controller.selectedRound.hasSprint;
    _tabController = TabController(length: hasSprint ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final r = widget.controller.selectedRound;
          final hasSprint = r.hasSprint;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SimulatorGlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              l10n.simulator_full_grid_title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        r.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (r.isCancelled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          l10n.simulator_race_cancelled,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!r.isCancelled && hasSprint)
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(text: l10n.simulator_tab_grand_prix),
                          Tab(text: l10n.simulator_tab_sprint),
                        ],
                      ),
                    Expanded(
                      child: r.isCancelled
                          ? const SizedBox.shrink()
                          : hasSprint
                              ? TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _FullGridReorderList(
                                      controller: widget.controller,
                                      sprint: false,
                                    ),
                                    _FullGridReorderList(
                                      controller: widget.controller,
                                      sprint: true,
                                    ),
                                  ],
                                )
                              : _FullGridReorderList(
                                  controller: widget.controller,
                                  sprint: false,
                                ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FullGridReorderList extends StatefulWidget {
  const _FullGridReorderList({
    required this.controller,
    required this.sprint,
  });

  final ChampionshipSimulatorController controller;
  final bool sprint;

  @override
  State<_FullGridReorderList> createState() => _FullGridReorderListState();
}

class _FullGridReorderListState extends State<_FullGridReorderList> {
  bool? _editable;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ok = widget.sprint
        ? await widget.controller.isSprintGridEditable()
        : await widget.controller.isGpGridEditable();
    if (mounted) setState(() => _editable = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final c = widget.controller;
    final r = c.selectedRound;
    final cid = r.circuitId;
    final readOnly = c.readOnly;
    final names =
        widget.sprint ? c.sprintRaceOrderForCircuit(cid) : c.gpRaceOrderForCircuit(cid);
    final sessionLocked = _editable == false;
    final canReorder =
        !readOnly && !r.isCancelled && _editable == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!readOnly && sessionLocked)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.simulator_session_locked,
              style: TextStyle(
                color: scheme.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: kSimulatorGridSize,
            buildDefaultDragHandles: canReorder,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (ctx, w) => Material(
                  elevation: 6 * animation.value,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: w,
                ),
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (!canReorder) return;
              var ni = newIndex;
              if (ni > oldIndex) ni--;
              if (widget.sprint) {
                c.reorderSprintRaceOrder(cid, oldIndex, ni);
              } else {
                c.reorderGpRaceOrder(cid, oldIndex, ni);
              }
            },
            itemBuilder: (context, index) {
              final name = index < names.length ? names[index] : '';
              final display = name.trim().isEmpty
                  ? ''
                  : canonicalSimulatorDriverName(name, c.drivers);
              final path =
                  display.isEmpty ? '' : simulatorDriverPortraitPath(display, c.drivers);

              return Padding(
                key: ValueKey('${widget.sprint}_${index}_$display'),
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            'P${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (path.isNotEmpty)
                          ClipOval(
                            child: Image.asset(
                              path,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 20,
                                backgroundColor: scheme.surfaceContainerHighest,
                                child: Text(
                                  display.isNotEmpty ? display[0] : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Icon(
                                Icons.person_outline,
                                color: scheme.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            display.isEmpty ? '—' : display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!readOnly && !r.isCancelled && display.isNotEmpty)
                          _FullGridStatusChips(
                            sprint: widget.sprint,
                            controller: c,
                            circuitId: cid,
                            driverName: display,
                            enabled: canReorder,
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
  }
}

class _FullGridStatusChips extends StatelessWidget {
  const _FullGridStatusChips({
    required this.sprint,
    required this.controller,
    required this.circuitId,
    required this.driverName,
    required this.enabled,
  });

  final bool sprint;
  final ChampionshipSimulatorController controller;
  final String circuitId;
  final String driverName;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (sprint) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            label: Text(l10n.simulator_dnf, style: const TextStyle(fontSize: 10)),
            selected: controller.isSprintDnf(circuitId, driverName),
            visualDensity: VisualDensity.compact,
            onSelected: enabled
                ? (_) => controller.toggleSprintDnf(circuitId, driverName)
                : null,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text(l10n.simulator_dns, style: const TextStyle(fontSize: 10)),
            selected: controller.isSprintDns(circuitId, driverName),
            visualDensity: VisualDensity.compact,
            onSelected: enabled
                ? (_) => controller.toggleSprintDns(circuitId, driverName)
                : null,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text(l10n.simulator_dsq, style: const TextStyle(fontSize: 10)),
            selected: controller.isSprintDsq(circuitId, driverName),
            visualDensity: VisualDensity.compact,
            onSelected: enabled
                ? (_) => controller.toggleSprintDsq(circuitId, driverName)
                : null,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterChip(
          label: Text(l10n.simulator_dnf, style: const TextStyle(fontSize: 10)),
          selected: controller.isGpDnf(circuitId, driverName),
          visualDensity: VisualDensity.compact,
          onSelected:
              enabled ? (_) => controller.toggleDnf(circuitId, driverName) : null,
        ),
        const SizedBox(width: 4),
        FilterChip(
          label: Text(l10n.simulator_dns, style: const TextStyle(fontSize: 10)),
          selected: controller.isGpDns(circuitId, driverName),
          visualDensity: VisualDensity.compact,
          onSelected:
              enabled ? (_) => controller.toggleGpDns(circuitId, driverName) : null,
        ),
        const SizedBox(width: 4),
        FilterChip(
          label: Text(l10n.simulator_dsq, style: const TextStyle(fontSize: 10)),
          selected: controller.isGpDsq(circuitId, driverName),
          visualDensity: VisualDensity.compact,
          onSelected:
              enabled ? (_) => controller.toggleGpDsq(circuitId, driverName) : null,
        ),
      ],
    );
  }
}

/// Loads public predictions via [get_shared_predictions] and opens the simulator read-only.
class SharedChampionshipPredictionsPage extends StatefulWidget {
  const SharedChampionshipPredictionsPage({
    super.key,
    required this.username,
    required this.roundInputs,
    required this.driverRefs,
  });

  final String username;
  final List<SimulatorRoundInput> roundInputs;
  final List<SimulatorDriverRef> driverRefs;

  @override
  State<SharedChampionshipPredictionsPage> createState() =>
      _SharedChampionshipPredictionsPageState();
}

class _SharedChampionshipPredictionsPageState
    extends State<SharedChampionshipPredictionsPage> {
  late final Future<SharedPredictionsLoadResult> _future;

  @override
  void initState() {
    super.initState();
    _future = SimulatorSyncService.instance.pullPredictionsByUsername(widget.username);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setSimulatorShareOgMeta(
        title: 'F1 Hub — ${widget.username}',
        description:
            'Bekijk de 2026 F1-voorspelling van ${widget.username} op F1 Hub.',
      );
    });
  }

  @override
  void dispose() {
    resetSimulatorShareOgMeta();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<SharedPredictionsLoadResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.simulator_share_stub_title),
                ],
              ),
            ),
          );
        }
        final result = snap.data;
        final rows = result?.rows ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          final body = result?.backendError != null
              ? l10n.simulator_share_error_load
              : l10n.simulator_share_empty(widget.username);
          final scheme = Theme.of(context).colorScheme;
          final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                height: 1.45,
              );
          return Scaffold(
            appBar: AppBar(title: Text(l10n.simulator_share_stub_title)),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 48,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 20),
                              Text(body, textAlign: TextAlign.center, style: textStyle),
                              if (kDebugMode && result?.backendError != null) ...[
                                const SizedBox(height: 16),
                                SelectableText(
                                  result!.backendError!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.error,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
        return ChampionshipSimulatorPage(
          roundInputs: widget.roundInputs,
          driverRefs: widget.driverRefs,
          readOnly: true,
          initialRemoteRows: rows,
          bannerUsername: widget.username,
          sharedPreviewFromLocalDraft: result?.fromLocalDraft ?? false,
        );
      },
    );
  }
}
