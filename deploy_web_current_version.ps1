#!/usr/bin/env pwsh
# deploy_web_current_version.ps1
# Zelfde pipeline als build_and_deploy.ps1, maar ZONDER pubspec.yaml te wijzigen:
# leest het huidige version:-veld alleen voor cache-bust (main.dart.js + index.html).

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$pubspec = 'pubspec.yaml'
if (-not (Test-Path $pubspec)) {
  Write-Error "Geen pubspec.yaml in $($PSScriptRoot)"
}

$deployVersion = (Get-Content $pubspec | Where-Object { $_ -match '^version:' }) -replace '^version:\s*', ''
if ([string]::IsNullOrWhiteSpace($deployVersion)) {
  Write-Error 'Kon version: niet uit pubspec.yaml lezen.'
}
Write-Host "Deploy met bestaande versie: $deployVersion (pubspec ongewijzigd)"

# Build — zelfde flags als build_and_deploy.ps1
flutter build web --base-href "/" --pwa-strategy=none

# Cache-bust main.dart.js via flutter_bootstrap.js
$fbWeb = 'build/web/flutter_bootstrap.js'
$fbRaw = Get-Content $fbWeb -Raw -Encoding utf8
$fbRaw = $fbRaw -replace '"mainJsPath":"main\.dart\.js(\?[^"]*)?"', (
  '"mainJsPath":"main.dart.js?v=' + $deployVersion + '"'
)
[System.IO.File]::WriteAllText((Resolve-Path $fbWeb), $fbRaw, [System.Text.UTF8Encoding]::new($false))

# Cache-bust index.html → flutter_bootstrap.js?v=...
$indexWeb = 'build/web/index.html'
$html = Get-Content $indexWeb -Raw -Encoding utf8
if ($html -match 'flutter_bootstrap\.js\?v=') {
  $html = $html -replace 'flutter_bootstrap\.js\?v=[^"]+', "flutter_bootstrap.js?v=$deployVersion"
} else {
  $html = $html -replace 'src="flutter_bootstrap\.js"', "src=`"flutter_bootstrap.js?v=$deployVersion`""
}
[System.IO.File]::WriteAllText((Resolve-Path $indexWeb), $html, [System.Text.UTF8Encoding]::new($false))

if (Test-Path CNAME) {
  Copy-Item CNAME build/web/CNAME -Force
}

Get-ChildItem -Path build\web -Force | ForEach-Object {
  Copy-Item $_.FullName -Destination . -Recurse -Force
}

git add -f build/web
git add pubspec.yaml index.html main.dart.js flutter_bootstrap.js flutter.js manifest.json version.json favicon.png .last_build_id CNAME assets canvaskit icons 2>$null
if (Test-Path flutter_service_worker.js) { git add flutter_service_worker.js }

$commitMsg = "Web deploy: $deployVersion (cache bust, geen versie-bump)"
git commit -m $commitMsg

git push origin gh-pages

Write-Host "Klaar. Controleer Network: main.dart.js?v=$deployVersion"
