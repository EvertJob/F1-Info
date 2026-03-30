# f1_download_2026_v8_final_grid.ps1
$dir = "C:\Users\evert\f1\assets\images\drivers"
if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }

# slug | server_mapnaam | driver_id | team_prefix_voor_bestand
$drivers = @(
    "george-russell|mercedes|georus01|mercedes",
    "kimi-antonelli|mercedes|andant01|mercedes",
    "charles-leclerc|ferrari|chalec01|ferrari",
    "lewis-hamilton|ferrari|lewham01|ferrari",
    "lando-norris|mclaren|lannor01|mclaren",
    "oscar-piastri|mclaren|oscpia01|mclaren",
    "oliver-bearman|haas|olibea01|haas",
    "esteban-ocon|haas|estoco01|haas",
    "pierre-gasly|alpine|piegas01|alpine",
    "franco-colapinto|alpine|fracol01|alpine",
    "max-verstappen|redbullracing|maxver01|redbullracing",
    "isack-hadjar|redbullracing|ISAHAD01|redbullracing", # GEFIXTE ID
    "liam-lawson|racingbulls|lialaw01|racingbulls",
    "arvid-lindblad|racingbulls|arvlin01|racingbulls",
    "nico-hulkenberg|audi|nichul01|audi",
    "gabriel-bortoleto|audi|gabbor01|audi",
    "carlos-sainz|williams|carsai01|williams",
    "alexander-albon|williams|alealb01|williams",
    "sergio-perez|cadillac|serper01|cadillac",
    "valtteri-bottas|cadillac|valbot01|cadillac",
    "fernando-alonso|astonmartin|feralo01|astonmartin",
    "lance-stroll|astonmartin|lanstr01|astonmartin"
)

$v = "v1740000001"
$cl = New-Object System.Net.WebClient
$cl.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

Write-Host "--- F1 2026 OFFICIAL GRID SYNC (V8.0) ---" -ForegroundColor Cyan

foreach ($line in $drivers) {
    $p = $line.Split("|")
    $slug = $p[0]; $team = $p[1]; $dID = $p[2]; $tID = $p[3]

    # De URL met de gecorrigeerde ID's en 720x720 crop
    $url = "https://media.formula1.com/image/upload/c_fill,g_face,w_720,h_720,q_auto/d_common:f1:2026:fallback:driver:2026fallbackdriverright.webp/$v/common/f1/2026/$team/$dID/2026$($tID)$($dID)right.webp"
    $dest = Join-Path $dir "$slug.png"

    Write-Host "⏳ Verwerken: $slug" -ForegroundColor Yellow
    try {
        $cl.DownloadFile($url, $dest)
        Write-Host "✅ OK!" -ForegroundColor Green
    } catch {
        Write-Host "❌ FOUT bij $slug" -ForegroundColor Red
        Write-Host "   Geprobeerde URL: $url" -ForegroundColor DarkGray
    }
}

Write-Host "----------------------------"
Write-Host "🏁 Alle 22 rijders staan nu in: $dir" -ForegroundColor Cyan
Read-Host "Druk op Enter om af te sluiten..."