$json = Get-Content -Raw -Encoding UTF8 .\data\articles.json | ConvertFrom-Json
$part14 = $json | Where-Object { $_.partId -eq 'XIV' }
$part14.articles | Select-Object -Property id | ConvertTo-Json
