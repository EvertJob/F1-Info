import 'package:flutter/foundation.dart';

/// Web share / OG hints for simulator deep links. Safe no-op on mobile & desktop.
void setSimulatorShareOgMeta({
  required String title,
  required String description,
}) {
  if (!kIsWeb) return;
  // Optional: inject meta tags via dart:html when you need social previews.
}

void resetSimulatorShareOgMeta() {
  if (!kIsWeb) return;
}
