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

# 2. Builden — base-href "/" voor custom domain f1hub.app (GitHub Pages root).
# Voor de oude project-URL username.github.io/F1-Info/ zou je apart met --base-href "/F1-Info/" moeten bouwen.
flutter build web --base-href "/"

# 2b. CNAME voor custom domain (f1hub.app) - moet in root van gh-pages staan
if (Test-Path CNAME) {
  Copy-Item CNAME build/web/CNAME
}

# 2c. Zelfde build naar repo-root kopiëren: GitHub Pages serveert de branch-root
# (index.html, main.dart.js, assets/, …), niet de map build/web/.
Get-ChildItem -Path build\web -Force | ForEach-Object {
  Copy-Item $_.FullName -Destination . -Recurse -Force
}

# 3. Pushen naar gh-pages (build/web inhoud naar root voor GitHub Pages)
git add -f build/web
$commitMsg = "Auto build: versie verhoogd naar $newVersion"
git commit -m $commitMsg

# Subtree push: build/web inhoud komt in root van gh-pages branch
$subtreeRef = (git subtree split --prefix build/web).ToString().Trim()
git push origin "${subtreeRef}:gh-pages" --force

Write-Host "Build en deploy voltooid."
