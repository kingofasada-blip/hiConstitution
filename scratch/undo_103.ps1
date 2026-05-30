[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }
$art = $p5.articles | Where-Object { $_.id -eq '103' }
$art.hindi = ''
$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Art 103 hindi cleared. Done."
