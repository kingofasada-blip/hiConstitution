$json = Get-Content -Raw -Encoding UTF8 .\data\articles.json | ConvertFrom-Json
$json | Where-Object { $_.partId -eq 'XIV' } | Select-Object -ExpandProperty articles | Where-Object { $_.id -eq '308' } | Select-Object -ExpandProperty text
