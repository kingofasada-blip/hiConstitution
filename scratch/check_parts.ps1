$json = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json' -Raw | ConvertFrom-Json
Write-Host "Total articles: $($json.Count)"
# Check part values available
$parts = $json | Select-Object -ExpandProperty part -Unique | Sort-Object
Write-Host "Parts available: $($parts -join ', ')"
# Show a sample article (part 3 or 4)
$sample = $json | Where-Object { $_.part -eq 3 } | Select-Object -First 1
Write-Host ""
Write-Host "=== Sample Part 3 Article ==="
Write-Host ($sample | ConvertTo-Json -Depth 5)
