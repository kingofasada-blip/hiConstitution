[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

$hindi134A = @"
प्रत्येक उच्च न्यायालय, जो अनुच्छेद 132 के खंड (1) या अनुच्छेद 133 के खंड (1) या अनुच्छेद 134 के खंड (1) में निर्दिष्ट निर्णय, डिक्री, अंतिम आदेश या दंडादेश पारित करता है या देता है, इस प्रकार पारित किए जाने या दिए जाने के पश्चात् यथाशक्य शीघ्र, इस प्रश्न का अवधारण कि उस मामले के संबंध में, यथास्थिति, अनुच्छेद 132 के खंड (1) या अनुच्छेद 133 के खंड (1) या अनुच्छेद 134 के खंड (1) के उपखंड (ग) में निर्दिष्ट प्रकृति का प्रमाणपत्र दिया जाए या नहीं, —
(क) यदि वह ऐसा करना ठीक समझता है तो स्वप्रेरणा से कर सकेगा; और
(ख) यदि ऐसा निर्णय, डिक्री, अंतिम आदेश या दंडादेश पारित किए जाने या दिए जाने के ठीक पश्चात् व्यथित पक्षकार द्वारा या उसकी ओर से मौखिक आवेदन किया जाता है तो करेगा ।
[संशोधन: संविधान (चवालीसवां संशोधन) अधिनियम, 1978 की धारा 20 द्वारा (1-8-1979 से) अंतःस्थापित।]
"@

$art = $p5.articles | Where-Object { $_.id -eq '134A' }
if ($art) {
    $art.hindi = $hindi134A.Trim()
    Write-Host "Updated Article 134A - hindi length: $($art.hindi.Length)"
} else {
    Write-Host "ERROR: Article 134A not found!"
    exit 1
}

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved successfully."

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
$artV = $p5v.articles | Where-Object { $_.id -eq '134A' }
Write-Host "Verify hindi length: $(if($artV.hindi){$artV.hindi.Length}else{0})"
