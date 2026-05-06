$script = Get-Content .\insert_part14A_ascii.ps1 -Raw
$script = $script -replace '(?s)\$json = Get-Content -LiteralPath \$jsonPath -Raw -Encoding UTF8 \| ConvertFrom-Json.*', '
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $partXIVA -Depth 16
[System.IO.File]::WriteAllText(".\scratch\part14A_only.json", $jsonOut, $utf8NoBom)
Write-Output "Part XIVA generated to part14A_only.json"
'
[System.IO.File]::WriteAllText(".\scratch\make_part14A_only.ps1", $script)
