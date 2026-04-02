import 'dart:ui' as ui;

import 'package:f1/circuit_detail/circuit_data.dart';
import 'package:f1/circuit_detail/circuit_detail_view.dart';
import 'package:f1/circuit_detail/circuit_embedded_map.dart';
import 'package:f1/circuit_detail/circuit_map_placement.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/hub_glass_chart_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

EdgeInsets _bodyPaddingUnderTransparentAppBar(BuildContext context) {
  return EdgeInsets.only(
    top: MediaQuery.paddingOf(context).top + kToolbarHeight,
  );
}

/// Content insets for [CircuitPage] (`/#/circuits/{slug}`): hub horizontal 16 + vertical rhythm.
const EdgeInsets _kCircuitSlugContentPadding =
    EdgeInsets.fromLTRB(16, 14, 16, 28);

/// “Back to circuits” row — extra top/bottom breathing room per hub parity spec.
const EdgeInsets _kCircuitSlugBackRowPadding =
    EdgeInsets.only(top: 32, bottom: 20, left: 16);

void _popCircuitRoute(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/circuits');
  }
}

class _CircuitBackToCircuitsLink extends StatelessWidget {
  const _CircuitBackToCircuitsLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.arrow_back_rounded, size: 20, color: muted),
        label: Text(
          context.l10n.circuit_back_to_circuits,
          style: GoogleFonts.titilliumWeb(
            color: muted,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.2,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: muted,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// Loads `assets/data/circuits/{circuitAssetId}.json` and shows [CircuitDetailView].
///
/// [circuitAssetId] must match the filename stem (e.g. `miami_autodrome`).
/// Invalid IDs or missing assets show a localized glass error card.
class CircuitPage extends StatefulWidget {
  const CircuitPage({super.key, required this.circuitAssetId});

  final String circuitAssetId;

  static final RegExp kSafeAssetId = RegExp(r'^[a-zA-Z0-9_-]+$');

  static String assetPathForId(String id) => 'assets/data/circuits/$id.json';

  @override
  State<CircuitPage> createState() => _CircuitPageState();
}

class _CircuitPageState extends State<CircuitPage> {
  /// Started from [didChangeDependencies] so [DefaultAssetBundle] matches the widget tree
  /// (important for web and nested shells). [rootBundle] alone can miss assets in some setups.
  Future<CircuitData?>? _loadFuture;

  /// Active pointers on the embedded map (pinch/drag); pauses parent [ListView] scroll.
  int _circuitMapActivePointers = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _load(DefaultAssetBundle.of(context));
  }

  @override
  void didUpdateWidget(covariant CircuitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circuitAssetId != widget.circuitAssetId) {
      _loadFuture = _load(DefaultAssetBundle.of(context));
      _circuitMapActivePointers = 0;
    }
  }

  Future<CircuitData?> _load(AssetBundle bundle) async {
    final id = widget.circuitAssetId.trim();
    if (!CircuitPage.kSafeAssetId.hasMatch(id)) {
      return null;
    }
    final path = CircuitPage.assetPathForId(id);
    try {
      final raw = await bundle.loadString(path);
      return CircuitData.parseJsonString(raw);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('CircuitPage: failed to load or parse "$path": $e\n$st');
      }
      // Last resort: root bundle (e.g. tests / isolates without inherited bundle).
      try {
        final raw = await rootBundle.loadString(path);
        return CircuitData.parseJsonString(raw);
      } on Object catch (e2, st2) {
        if (kDebugMode) {
          debugPrint('CircuitPage: rootBundle retry failed: $e2\n$st2');
        }
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final future = _loadFuture;
    if (future == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _ambientAppBar(context, title: ''),
        body: _CircuitPageSurface(
          child: Padding(
            padding: _bodyPaddingUnderTransparentAppBar(context),
            child: const HubGlassPageLoadingPlaceholder(),
          ),
        ),
      );
    }
    return FutureBuilder<CircuitData?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: _ambientAppBar(context, title: ''),
            body: _CircuitPageSurface(
              child: Padding(
                padding: _bodyPaddingUnderTransparentAppBar(context),
                child: const HubGlassPageLoadingPlaceholder(),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: _ambientAppBar(
              context,
              title: l10n.circuit_not_found_title,
            ),
            body: _CircuitPageSurface(
              child: Padding(
                padding: _bodyPaddingUnderTransparentAppBar(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: _CircuitNotFoundCard(),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final mapPlacement = CircuitMapPlacement.resolve(data);
        if (mapPlacement != null) {
          final bottomPad = MediaQuery.paddingOf(context).bottom;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: _kCircuitSlugBackRowPadding,
                    child: _CircuitBackToCircuitsLink(
                      onPressed: () => _popCircuitRoute(context),
                    ),
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: CircuitDetailView(
                      data: data,
                      circuitAssetId: widget.circuitAssetId,
                      showTitleHeader: false,
                      useAppBarTopInset: false,
                      padding: _kCircuitSlugContentPadding,
                      listPhysics: _circuitMapActivePointers > 0
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      scrollableAppend: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) {
                          setState(() => _circuitMapActivePointers++);
                        },
                        onPointerUp: (_) {
                          setState(() {
                            _circuitMapActivePointers =
                                (_circuitMapActivePointers - 1).clamp(0, 32);
                          });
                        },
                        onPointerCancel: (_) {
                          setState(() {
                            _circuitMapActivePointers =
                                (_circuitMapActivePointers - 1).clamp(0, 32);
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(bottom: bottomPad + 6),
                          child: CircuitEmbeddedMap(
                            placement: mapPlacement,
                            circuitId: data.circuitId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: _kCircuitSlugBackRowPadding,
                  child: _CircuitBackToCircuitsLink(
                    onPressed: () => _popCircuitRoute(context),
                  ),
                ),
              ),
              Expanded(
                child: CircuitDetailView(
                  data: data,
                  circuitAssetId: widget.circuitAssetId,
                  showTitleHeader: true,
                  useAppBarTopInset: false,
                  padding: _kCircuitSlugContentPadding,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _ambientAppBar(
    BuildContext context, {
    required String title,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.primary),
        onPressed: () => _popCircuitRoute(context),
      ),
      title: title.isEmpty
          ? null
          : Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
      centerTitle: false,
    );
  }
}

/// Flat shell so the circuit dashboard matches the rest of the app (no gradient/blur).
class _CircuitPageSurface extends StatelessWidget {
  const _CircuitPageSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(child: child),
    );
  }
}

class _CircuitNotFoundCard extends StatelessWidget {
  const _CircuitNotFoundCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final f1 = Theme.of(context).extension<F1UiTheme>();
    final radius = f1?.cardBorderRadius ?? 22;
    final showOutline = f1?.showFadingBorder ?? true;
    final motionReduced = context.select<DisplaySettingsController, bool>(
      (c) => c.motionReduced,
    );
    final blurSigma = motionReduced ? 0.0 : 10.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (blurSigma > 0)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.14 : 0.52),
                  Colors.white.withValues(alpha: isDark ? 0.07 : 0.32),
                  Color(0xFFE3F2FD).withValues(alpha: isDark ? 0.08 : 0.28),
                ],
              ),
              border: showOutline
                  ? Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.32 : 0.72,
                      ),
                      width: 1.2,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.travel_explore_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.circuit_not_found_title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.circuit_not_found_message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go('/circuits'),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(l10n.circuit_go_home),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                    ),
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
