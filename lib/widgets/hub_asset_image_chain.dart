import 'package:flutter/material.dart';

import 'f1_hub_image_fallback.dart';

/// Tries [paths] in order; last resort is [fallback] or [F1HubImageGlassFallback].
class HubAssetImageChain extends StatelessWidget {
  const HubAssetImageChain({
    super.key,
    required this.paths,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
    this.gaplessPlayback = true,
    this.clipOval = false,
    this.borderRadius,
    this.bundle,
    this.fallback,
    this.glassFallbackAccent,
  });

  final List<String> paths;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final bool clipOval;
  final double? borderRadius;
  final AssetBundle? bundle;
  final Widget? fallback;
  /// Tint for [F1HubImageGlassFallback] when no custom [fallback] is set.
  final Color? glassFallbackAccent;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return fallback ?? _defaultFallback(context);
    }
    return _HubAssetImageChainLayer(
      paths: paths,
      index: 0,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      clipOval: clipOval,
      borderRadius: borderRadius,
      bundle: bundle,
      fallback: fallback,
      glassFallbackAccent: glassFallbackAccent,
    );
  }

  Widget _defaultFallback(BuildContext context) {
    final w = width;
    final h = height;
    final child = F1HubImageGlassFallback(
      borderRadius: clipOval ? 999 : (borderRadius ?? 14),
      padding: EdgeInsets.all((w != null && w < 56) ? 6 : 12),
      accentGradient: glassFallbackAccent,
    );
    if (w != null || h != null) {
      return SizedBox(width: w, height: h, child: child);
    }
    return child;
  }
}

class _HubAssetImageChainLayer extends StatelessWidget {
  const _HubAssetImageChainLayer({
    required this.paths,
    required this.index,
    this.width,
    this.height,
    required this.fit,
    required this.alignment,
    required this.filterQuality,
    required this.gaplessPlayback,
    required this.clipOval,
    this.borderRadius,
    this.bundle,
    this.fallback,
    this.glassFallbackAccent,
  });

  final List<String> paths;
  final int index;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final bool clipOval;
  final double? borderRadius;
  final AssetBundle? bundle;
  final Widget? fallback;
  final Color? glassFallbackAccent;

  @override
  Widget build(BuildContext context) {
    final path = paths[index];
    Widget img = Image.asset(
      path,
      bundle: bundle,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (_, _, _) {
        if (index + 1 < paths.length) {
          return _HubAssetImageChainLayer(
            paths: paths,
            index: index + 1,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            filterQuality: filterQuality,
            gaplessPlayback: gaplessPlayback,
            clipOval: clipOval,
            borderRadius: borderRadius,
            bundle: bundle,
            fallback: fallback,
            glassFallbackAccent: glassFallbackAccent,
          );
        }
        if (fallback != null) return fallback!;
        final child = F1HubImageGlassFallback(
          borderRadius: clipOval ? 999 : (borderRadius ?? 14),
          padding: EdgeInsets.all(
            (width != null && width! < 56) ? 6 : 12,
          ),
          accentGradient: glassFallbackAccent,
        );
        if (width != null || height != null) {
          return SizedBox(width: width, height: height, child: child);
        }
        return child;
      },
    );
    if (clipOval) {
      img = ClipOval(child: img);
    } else if (borderRadius != null) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: img,
      );
    }
    return img;
  }
}
