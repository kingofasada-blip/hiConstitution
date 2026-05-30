$json = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json' -Raw | ConvertFrom-Json
$part5 = $json | Where-Object { $_.part -eq 5 }
Write-Host "Part 5 count: $($part5.Count)"
$first = $part5[0]
Write-Host "Article number: $($first.article_number)"
$props = $first | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
Write-Host "Keys: $($props -join ', ')"
Write-Host ""
Write-Host "=== First article full ==="
Write-Host ($first | ConvertTo-Json -Depth 3)
