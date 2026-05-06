$jsonPath = ".\data\articles.json"
$content = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
if ($content.value) { $array = $content.value } else { $array = $content }

$targetArticles14 = @('308', '309', '310', '311', '312', '312A', '315', '316', '317', '318', '320', '323')
$targetArticles14A = @('323A', '323B')

foreach ($part in $array) {
    if ($part.partId -eq 'XIV') {
        foreach ($article in $part.articles) {
            if ($article.id -in $targetArticles14) {
                $article.text = [regex]::Replace($article.text, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
            }
            if ($article.id -eq '313') {
                $article.hindi = "<strong>अनुच्छेद 313. संक्रमणकालीन उपबंध.-</strong>`nजब तक इस संविधान के अधीन इस निमित्त अन्य उपबंध नहीं किया जाता है तब तक ऐसी सभी विधियां जो इस संविधान के प्रारंभ से ठीक पहले प्रवृत्त हैं और किसी ऐसी लोक सेवा या किसी ऐसे पद को, जो इस संविधान के प्रारंभ के पश्चात् अखिल भारतीय सेवा के अथवा संघ या किसी राज्य के अधीन सेवा या पद के रूप में बना रहता है, लागू हैं वहां तक प्रवृत्त बनी रहेंगी जहां तक वे इस संविधान के उपबंधों से संगत हैं ।"
            }
            if ($article.id -eq '314') {
                $article.hindi = "<strong>अनुच्छेद 314. [कुछ सेवाओं के विद्यमान अधिकारियों के संरक्षण के लिए उपबंध ।]</strong><br>संविधान (अट्ठाईसवां संशोधन) अधिनियम, 1972 की धारा 3 द्वारा (29-8-1972 से) लोप किया गया ।"
                $article.hindiSimplified = "यह अनुच्छेद 28वें संशोधन अधिनियम, 1972 द्वारा हटा दिया गया है।"
            }
        }
    }
    if ($part.partId -eq 'XIVA') {
        foreach ($article in $part.articles) {
            if ($article.id -in $targetArticles14A) {
                $article.text = [regex]::Replace($article.text, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
            }
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $array -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Output "Fixed."
