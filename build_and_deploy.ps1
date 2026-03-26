#!/usr/bin/env pwsh
# build_and_deploy.ps1
# Automatisch versienummer verhogen, builden en pushen naar gh-pages

# 1. Versienummer verhogen
$pubspec = 'pubspec.yaml'
$lines = Get-Content $pubspec
$versionLine = $lines | Where-Object { $_ -match '^version:' }
if ($versionLine) {
    $currentVersion = $versionLine -replace '^version:\s*', ''
    $parts = $currentVersion -split '\+'
    $base = $parts[0]
    $build = [int]$parts[1] + 1
    $newVersion = "$base+$build"
    $lines = $lines | ForEach-Object {
        if ($_ -match '^version:') { "version: $newVersion" } else { $_ }
    }
    Set-Content $pubspec $lines
    Write-Host "Versie verhoogd naar $newVersion"
}

$deployVersion = (Get-Content $pubspec | Where-Object { $_ -match '^version:' }) -replace '^version:\s*', ''

# 2. Builden — base-href "/" voor custom domain f1hub.app (GitHub Pages root).
# --pwa-strategy=none: geen flutter_service worker (mobiel cachet anders oude bundles dagenlang).
# (Voor username.github.io/F1-Info/ zou je apart met --base-href "/F1-Info/" moeten bouwen.)
flutter build web --base-href "/" --pwa-strategy=none

# 2a. Cache-bust op de echte app-bundle: alleen ?v= op index/bootstrap is niet genoeg —
# de loader injecteert anders plain "main.dart.js" en CDN/browser blijven oude JS serveren.
$fbWeb = 'build/web/flutter_bootstrap.js'
$fbRaw = Get-Content $fbWeb -Raw -Encoding utf8
# Idempotent: ook als er al een oude ?v= in de bundle stond (tweede deploy-run zonder clean).
$fbRaw = $fbRaw -replace '"mainJsPath":"main\.dart\.js(\?[^"]*)?"', (
  '"mainJsPath":"main.dart.js?v=' + $deployVersion + '"'
)
[System.IO.File]::WriteAllText((Resolve-Path $fbWeb), $fbRaw, [System.Text.UTF8Encoding]::new($false))

# 2b. Cache-bust op bootstrap: nieuwe flutter_bootstrap.js ophalen
$indexWeb = 'build/web/index.html'
$html = Get-Content $indexWeb -Raw -Encoding utf8
if ($html -match 'flutter_bootstrap\.js\?v=') {
  $html = $html -replace 'flutter_bootstrap\.js\?v=[^"]+', "flutter_bootstrap.js?v=$deployVersion"
} else {
  $html = $html -replace 'src="flutter_bootstrap\.js"', "src=`"flutter_bootstrap.js?v=$deployVersion`""
}
[System.IO.File]::WriteAllText((Resolve-Path $indexWeb), $html, [System.Text.UTF8Encoding]::new($false))

# 2c. CNAME voor custom domain (f1hub.app) - moet in root van gh-pages staan
if (Test-Path CNAME) {
  Copy-Item CNAME build/web/CNAME
}

# 2d. Zelfde build naar repo-root kopiëren: GitHub Pages serveert de branch-root
# (index.html, main.dart.js, assets/, …), niet de map build/web/.
Get-ChildItem -Path build\web -Force | ForEach-Object {
  Copy-Item $_.FullName -Destination . -Recurse -Force
}

# 3. Committen (build/web + gesynchroniseerde root-bestanden voor GitHub Pages)
# Git LF-waarschuwingen op stderr mogen niet breken bij $ErrorActionPreference = 'Stop'.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
  git add -f build/web
  git add pubspec.yaml index.html main.dart.js flutter_bootstrap.js flutter.js manifest.json version.json favicon.png .last_build_id CNAME assets canvaskit icons 2>$null
  if (Test-Path flutter_service_worker.js) { git add flutter_service_worker.js }
  $commitMsg = "Auto build: web $deployVersion (PWA off, cache bust)"
  git commit -m $commitMsg
  git push origin gh-pages
} finally {
  $ErrorActionPreference = $prevEap
}

Write-Host "Build en deploy voltooid."
