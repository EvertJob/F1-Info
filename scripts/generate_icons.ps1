#Requires -Version 5.1
<#
  F1 Hub: rasterize SVG -> PNG (1024), then flutter_launcher_icons from flutter_launcher_icons.yaml
  Run from repo root:  .\scripts\generate_icons.ps1
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host ">> flutter pub get"
flutter pub get

$pngPath = Join-Path $Root "assets/images/f1_hub_logo_launcher.png"
$svgPath = Join-Path $Root "assets/images/f1_hub_logo.svg"

if (Get-Command magick -ErrorAction SilentlyContinue) {
  Write-Host ">> ImageMagick: rasterize SVG -> 1024 PNG"
  & magick -background none $svgPath -resize "1024x1024" "PNG32:$pngPath"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} elseif (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
  Write-Host ">> rsvg-convert: rasterize SVG -> 1024 PNG"
  & rsvg-convert -w 1024 -h 1024 -o $pngPath $svgPath
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host ">> flutter test (SVG -> PNG via vector_graphics)"
  flutter test test/tool/rasterize_launcher_logo_test.dart --reporter expanded
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ">> dart run flutter_launcher_icons (flutter_launcher_icons.yaml)"
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Done. Commit updated PNGs under android/, ios/, web/ if desired."
