import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the system maps app with platform-specific URIs.
///
/// iOS: `maps://?q=label&ll=lat,lon`
/// Android / Web / default: `geo:0,0?q=lat,lon(label)`
Future<bool> launchCircuitMaps({
  required double latitude,
  required double longitude,
  required String label,
}) async {
  final uri = circuitMapsUri(
    latitude: latitude,
    longitude: longitude,
    label: label,
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri circuitMapsUri({
  required double latitude,
  required double longitude,
  required String label,
}) {
  final encLabel = Uri.encodeComponent(label);
  final isAppleMobile =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (isAppleMobile) {
    return Uri.parse('maps://?q=$encLabel&ll=$latitude,$longitude');
  }
  return Uri.parse('geo:0,0?q=$latitude,$longitude($encLabel)');
}
