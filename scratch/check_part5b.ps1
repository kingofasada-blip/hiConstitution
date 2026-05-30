$json = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json' -Raw | ConvertFrom-Json
# Get Part V
$part5 = $json | Where-Object { $_.partId -eq 'V' }
Write-Host "Part V object count: $($part5.Count)"
if ($part5) {
    Write-Host "Article count in Part V: $($part5.articles.Count)"
    $part5.articles | ForEach-Object { Write-Host "  Art $($_.id): $($_.title.Substring(0, [Math]::Min(60, $_.title.Length)))" }
    Write-Host ""
    Write-Host "=== First article ==="
    Write-Host ($part5.articles[0] | ConvertTo-Json -Depth 3)
} else {
    Write-Host "Part V not found! Listing all partIds:"
    $json | Select-Object -ExpandProperty partId | ForEach-Object { Write-Host "  $_" }
}
