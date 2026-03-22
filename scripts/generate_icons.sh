#!/usr/bin/env bash
# F1 Hub: rasterize SVG -> PNG (1024), then flutter_launcher_icons
# Run from repo root: bash scripts/generate_icons.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo ">> flutter pub get"
flutter pub get

if command -v magick >/dev/null 2>&1; then
  echo ">> ImageMagick: rasterize SVG -> 1024 PNG"
  magick -background none "$ROOT/assets/images/f1_hub_logo.svg" -resize "1024x1024" "PNG32:$ROOT/assets/images/f1_hub_logo_launcher.png"
elif command -v rsvg-convert >/dev/null 2>&1; then
  echo ">> rsvg-convert: rasterize SVG -> 1024 PNG"
  rsvg-convert -w 1024 -h 1024 -o "$ROOT/assets/images/f1_hub_logo_launcher.png" "$ROOT/assets/images/f1_hub_logo.svg"
else
  echo ">> flutter test (SVG -> PNG via vector_graphics)"
  flutter test test/tool/rasterize_launcher_logo_test.dart --reporter expanded
fi

echo ">> dart run flutter_launcher_icons (flutter_launcher_icons.yaml)"
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

echo "Done. Commit updated PNGs under android/, ios/, web/ if desired."
