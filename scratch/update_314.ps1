$jsonPath = ".\data\articles.json"
$content = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
if ($content.value) { $array = $content.value } else { $array = $content }

foreach ($part in $array) {
    if ($part.partId -eq 'XIV') {
        foreach ($article in $part.articles) {
            if ($article.id -eq '314') {
                $article.hindi = "<strong>अनुच्छेद 314. [कुछ सेवाओं के विद्यमान अधिकारियों के संरक्षण के लिए उपबंध ।]</strong><br>संविधान (अट्ठाईसवां संशोधन) अधिनियम, 1972 की धारा 3 द्वारा (29-8-1972 से) लोप किया गया ।"
                $article.hindiSimplified = "यह अनुच्छेद 28वें संशोधन अधिनियम, 1972 द्वारा हटा दिया गया है।"
            }
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $array -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Output "Updated 314."
