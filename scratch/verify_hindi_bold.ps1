[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$json = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

Write-Host "=== Art 52 full hindi ==="
$a52 = $p5.articles | Where-Object { $_.id -eq '52' }
Write-Host $a52.hindi

Write-Host ""
Write-Host "=== Art 58 first 300 chars ==="
$a58 = $p5.articles | Where-Object { $_.id -eq '58' }
Write-Host $a58.hindi.Substring(0, [Math]::Min(300, $a58.hindi.Length))

Write-Host ""
Write-Host "=== Art 74 first 300 chars ==="
$a74 = $p5.articles | Where-Object { $_.id -eq '74' }
Write-Host $a74.hindi.Substring(0, [Math]::Min(300, $a74.hindi.Length))

Write-Host ""
Write-Host "=== Articles with empty hindi ==="
foreach ($art in $p5.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') {
        Write-Host "  Art $($art.id): $($art.title)"
    }
}
