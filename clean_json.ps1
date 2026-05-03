$jsonPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json"
$j = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$part12 = $j | Where-Object { $_.partId -eq 'XII' }
$art283 = $part12.articles | Where-Object { $_.id -eq '283' }
if ($null -ne $art283) {
    $art283.hindiSimplified = $art283.hindiSimplified -replace "`nजी हाँ, बिल्कुल.*", ""
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json -InputObject $j -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Output "Cleaned up article 283"
