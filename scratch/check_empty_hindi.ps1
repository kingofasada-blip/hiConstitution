[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$json = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }
Write-Host "=== Part V articles with empty hindi field ==="
$emptyCount = 0
foreach ($art in $p5.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') {
        Write-Host "Art $($art.id): $($art.title)"
        $emptyCount++
    }
}
Write-Host ""
Write-Host "Total with empty hindi: $emptyCount"
Write-Host "Total articles: $($p5.articles.Count)"
