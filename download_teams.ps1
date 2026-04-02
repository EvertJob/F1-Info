# download_f1_team_logos_2026.ps1
$baseDir = "C:\Users\evert\f1\images\constructors"
if (!(Test-Path $baseDir)) { New-Item -ItemType Directory -Path $baseDir -Force }

# De teams op basis van de serverstructuur
$teams = @(
    "alpine", "astonmartin", "audi", "cadillac", "ferrari", 
    "haasf1team", "mclaren", "mercedes", "racingbulls", "redbullracing", "williams"
)

# De slugs voor de bestandsnamen (consistent met je app)
$slugs = @{
    "alpine"          = "alpine"
    "astonmartin"     = "aston-martin"
    "audi"            = "audi"
    "cadillac"        = "cadillac"
    "ferrari"         = "ferrari"
    "haasf1team"      = "haas-f1-team"
    "mclaren"         = "mclaren"
    "mercedes"        = "mercedes"
    "racingbulls"     = "racing-bulls"
    "redbullracing"   = "red-bull-racing"
    "williams"        = "williams"
}

$year = "2026"
$vCode = "v1740000001"
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

Write-Host "🛡️  Starten download van F1 2026 teamlogo's (HQ PNG)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------"

foreach ($team in $teams) {
    # URL opbouw voor MAX kwaliteit: verwijder w_48, voeg q_auto:best toe, forceer PNG
    $url = "https://media.formula1.com/image/upload/w_2000/v1740000001/common/f1/$year/$team/$($year)$($team)logowhite.png"
    
    # Bestandsnaam formaat: {slug}.png
    $slug = $slugs[$team]
    $targetPath = Join-Path $baseDir "$slug.png"

    Write-Host "⏳ Verwerken: $team (Bestand: $slug.png)" -ForegroundColor Yellow
    
    try {
        $webClient.DownloadFile($url, $targetPath)
        Write-Host "✅ Opgeslagen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ FOUT bij $team : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Geprobeerde URL: $url" -ForegroundColor DarkGray
    }
}

Write-Host "--------------------------------------------------------"
Write-Host "🏁 Alle logo's zijn verwerkt!" -ForegroundColor Cyan
Read-Host "Druk op Enter om af te sluiten"