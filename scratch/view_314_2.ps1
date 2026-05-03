$json = Get-Content -Raw -Encoding UTF8 .\data\articles.json | ConvertFrom-Json
$part14 = $json | Where-Object { $_.partId -eq 'XIV' }
$part14.articles | Where-Object { $_.id -eq '314' } | ConvertTo-Json -Depth 3 | Out-File .\scratch\view_314.json -Encoding utf8
