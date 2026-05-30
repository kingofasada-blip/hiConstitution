[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$p5 = $json | Where-Object { $_.partId -eq 'V' }

$hindi131A = @"
[केन्द्रीय विधियों की सांविधानिक वैधता से संबंधित प्रश्नों के बारे में उच्चतम न्यायालय की अनन्य अधिकारिता।]
संविधान (तैंतालीसवां संशोधन) अधिनियम, 1977 की धारा 4 द्वारा (13-4-1978 से) लोप किया गया।
[नोट: यह अनुच्छेद संविधान (बयालीसवां संशोधन) अधिनियम, 1976 की धारा 23 द्वारा (1-2-1977 से) अंतःस्थापित किया गया था, तथा संविधान (तैंतालीसवां संशोधन) अधिनियम, 1977 द्वारा लोप कर दिया गया।]
"@

$art131A = $p5.articles | Where-Object { $_.id -eq '131A' }
if ($art131A) {
    $art131A.hindi = $hindi131A.Trim()
    Write-Host "Updated Article 131A - hindi length: $($art131A.hindi.Length)"
    Write-Host "Preview: $($art131A.hindi.Substring(0, [Math]::Min(100, $art131A.hindi.Length)))"
} else {
    Write-Host "ERROR: Article 131A not found!"
}

# Save
$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved: $jsonPath"

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
$art = $p5v.articles | Where-Object { $_.id -eq '131A' }
Write-Host "Verify - hindi length: $(if($art.hindi){$art.hindi.Length}else{0})"
