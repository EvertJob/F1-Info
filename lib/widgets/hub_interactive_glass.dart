import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/hub_mobile_tuning.dart';

/// Hover / touch feedback for glass-style tappable surfaces.
///
/// **Mouse / trackpad:** 1.02× scale + luminous rim (0.3 white).
/// **Touch:** no scale; [InkWell] splash when [onTap] is set, else opacity dip
/// on press.
///
/// If [onTap] is null, the child should handle taps (e.g. inner [InkWell]).
class HubInteractiveGlass extends StatefulWidget {
  const HubInteractiveGlass({
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  static const Duration _duration = Duration(milliseconds: 140);
  static final Curve _curve = Curves.easeOutCubic;

  @override
  State<HubInteractiveGlass> createState() => _HubInteractiveGlassState();
}

class _HubInteractiveGlassState extends State<HubInteractiveGlass> {
  bool _hover = false;
  bool _pressed = false;
  PointerDeviceKind? _lastKind;

  /// Mouse / pointer dispatch runs inside [MouseTracker] device updates; calling
  /// [setState] synchronously there triggers nested `_deviceUpdatePhase` asserts
  /// (mouse_tracker.dart) and follow-on layout / hit-test failures on web.
  void _postFrameSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _rememberKind(PointerDeviceKind kind) {
    if (kind == _lastKind) return;
    _postFrameSetState(() => _lastKind = kind);
  }

  bool _mouseLikeInteraction(BuildContext context) {
    final k = _lastKind;
    if (k == PointerDeviceKind.mouse || k == PointerDeviceKind.trackpad) {
      return true;
    }
    if (k == PointerDeviceKind.touch || k == PointerDeviceKind.stylus) {
      return false;
    }
    final w = MediaQuery.sizeOf(context).width;
    if (w < HubMobileTuning.narrowLayoutWidth) return false;
    return !HubMobileTuning.isNativeMobilePlatform();
  }

  Widget _rimStack(BuildContext context, Widget child, double rim) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rimColor = rim <= 0
        ? Colors.transparent
        : (isDark
            ? Colors.white.withValues(alpha: rim)
            : Colors.black.withValues(alpha: 0.22));

    return Stack(
      // loose: passthrough can confuse hit-testing with Positioned.fill on web.
      fit: StackFit.loose,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: HubInteractiveGlass._duration,
              curve: HubInteractiveGlass._curve,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: rimColor,
                  width: 0.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mouseLike = _mouseLikeInteraction(context);
    final active = mouseLike ? (_hover || _pressed) : _pressed;
    final scale = (mouseLike && active) ? 1.02 : 1.0;
    final rim = (mouseLike && active) ? 0.3 : 0.0;

    Widget core = _rimStack(context, widget.child, rim);
    core = AnimatedScale(
      scale: mouseLike ? scale : 1.0,
      duration: HubInteractiveGlass._duration,
      curve: HubInteractiveGlass._curve,
      child: core,
    );

    if (!mouseLike && widget.onTap == null) {
      core = AnimatedOpacity(
        opacity: _pressed ? 0.7 : 1.0,
        duration: HubInteractiveGlass._duration,
        curve: HubInteractiveGlass._curve,
        child: core,
      );
    }

    if (widget.onTap == null) {
      return Listener(
        behavior: HitTestBehavior.deferToChild,
        onPointerDown: (e) => _rememberKind(e.kind),
        child: MouseRegion(
          onEnter: (_) {
            if (mouseLike) _postFrameSetState(() => _hover = true);
          },
          onExit: (_) {
            if (mouseLike) _postFrameSetState(() => _hover = false);
          },
          child: Listener(
            behavior: HitTestBehavior.deferToChild,
            onPointerDown: (_) {
              if (!mouseLike) _postFrameSetState(() => _pressed = true);
            },
            onPointerUp: (_) {
              if (!mouseLike) _postFrameSetState(() => _pressed = false);
            },
            onPointerCancel: (_) {
              if (!mouseLike) _postFrameSetState(() => _pressed = false);
            },
            child: core,
          ),
        ),
      );
    }

    if (mouseLike) {
      return Listener(
        onPointerDown: (e) => _rememberKind(e.kind),
        child: MouseRegion(
          onEnter: (_) => _postFrameSetState(() => _hover = true),
          onExit: (_) => _postFrameSetState(() => _hover = false),
          child: GestureDetector(
            onTapDown: (_) => _postFrameSetState(() => _pressed = true),
            onTapUp: (_) => _postFrameSetState(() => _pressed = false),
            onTapCancel: () => _postFrameSetState(() => _pressed = false),
            onTap: widget.onTap,
            child: core,
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (e) => _rememberKind(e.kind),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          highlightColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          onTap: widget.onTap,
          child: core,
        ),
      ),
    );
  }
}
