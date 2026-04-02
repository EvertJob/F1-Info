# download_f1_cars_2026_v2.ps1
$dir = "C:\Users\evert\f1\images\cars"
if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }

$list = @(
    "alpine", "astonmartin", "audi", "cadillac", "ferrari", 
    "haas", "mclaren", "mercedes", "racingbulls", "redbullracing", "williams"
)

$v = "v1740000001"
$y = "2026"
$cl = New-Object System.Net.WebClient
$cl.Headers.Add("User-Agent", "Mozilla/5.0")

Write-Host "--- F1 2026 Car Assets Download ---" -ForegroundColor Cyan

foreach ($t in $list) {
    # URL op één regel zonder onderbrekingen
    $url = "https://media.formula1.com/image/upload/c_lfill,w_3392/q_auto/$v/common/f1/$y/$t/$($y)$($t)carright.webp"
    $file = "$t-$y.png"
    $path = Join-Path $dir $file

    Write-Host "⏳ Downloaden: $file" -ForegroundColor Yellow
    try {
        $cl.DownloadFile($url, $path)
        Write-Host "✅ Succes: $file" -ForegroundColor Green
    } catch {
        Write-Host "❌ Fout bij $t : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "------------------------------------"
Write-Host "🏁 Klaar!" -ForegroundColor Cyan
Read-Host "Druk op Enter om af te sluiten"