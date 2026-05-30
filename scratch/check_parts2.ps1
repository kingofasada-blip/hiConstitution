$json = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json' -Raw | ConvertFrom-Json
Write-Host "Total articles: $($json.Count)"
# Check partId values
$partIds = $json | Select-Object -ExpandProperty partId -Unique | Sort-Object
Write-Host "PartIds available: $($partIds -join ', ')"
# Get Part V (5)
$part5 = $json | Where-Object { $_.partId -eq 'V' }
Write-Host "Part V count: $($part5.Count)"
# Show sample part 3 article structure
$sample = $json | Where-Object { $_.partId -eq 'III' } | Select-Object -First 1
Write-Host ""
Write-Host "=== Sample Part III Article Structure ==="
Write-Host ($sample | ConvertTo-Json -Depth 5)
