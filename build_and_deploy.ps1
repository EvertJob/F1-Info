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

# 2. Builden
flutter build web

# 3. Pushen naar gh-pages
# Forceer toevoegen van build/web ondanks .gitignore

git add -f build/web
$commitMsg = "Auto build: versie verhoogd naar $newVersion"
git commit -m $commitMsg

git push origin gh-pages

Write-Host "Build en deploy voltooid."
