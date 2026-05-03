$json = Get-Content -Raw -Encoding UTF8 .\data\articles.json | ConvertFrom-Json
$part14 = $json | Where-Object { $_.partId -eq 'XIV' }
$articles = $part14.articles | Where-Object { $_.id -in @('308', '309', '310', '311', '312', '312A', '315', '316', '317', '318', '320', '323') }
$articles | Select-Object id, text | ConvertTo-Json -Depth 3 | Out-File -FilePath .\scratch\part14_superscripts.json -Encoding utf8
