[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

$titlePart = @"
<strong>103. सदस्यों की निरर्हताओं से संबंधित प्रश्नों पर विनिश्चय—</strong>
"@

$bodyPart = @"
(1) यदि यह प्रश्न उठता है कि संसद् के किसी सदन का कोई सदस्य अनुच्छेद 102 के खंड (1) में वर्णित किसी निरर्हता से ग्रस्त हो गया है या नहीं तो वह प्रश्न राष्ट्रपति को विनिश्चय के लिए निर्देशित किया जाएगा और उसका विनिश्चय अंतिम होगा ।
(2) ऐसे किसी प्रश्न पर विनिश्चय करने के पहले राष्ट्रपति निर्वाचन आयोग की राय लेगा और ऐसी राय के अनुसार कार्य करेगा ।
[संशोधन: संविधान (बयालीसवां संशोधन) अधिनियम, 1976 की धारा 20 द्वारा (3-1-1977 से) अनुच्छेद 103 के स्थान पर प्रतिस्थापित और तत्पश्चात् संविधान (चवालीसवां संशोधन) अधिनियम, 1978 की धारा 14 द्वारा (20-6-1979 से) अनुच्छेद 103 के स्थान पर प्रतिस्थापित।]
"@

$hindi103 = $titlePart.Trim() + "`n" + $bodyPart.Trim()

$art = $p5.articles | Where-Object { $_.id -eq '103' }
if ($art) {
    $art.hindi = $hindi103
    Write-Host "Updated Art 103 - length: $($art.hindi.Length)"
} else {
    Write-Host "ERROR: Art 103 not found!"
    exit 1
}

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved."

$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
$artV = $p5v.articles | Where-Object { $_.id -eq '103' }
Write-Host "Verify length: $(if($artV.hindi){$artV.hindi.Length}else{'EMPTY'})"
