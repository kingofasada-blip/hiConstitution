$jsonPath = ".\data\articles.json"
$content = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
if ($content.value) { $array = $content.value } else { $array = $content }

$targetArticles = @('308', '309', '310', '311', '312', '312A', '315', '316', '317', '318', '320', '323')
foreach ($part in $array) {
    if ($part.partId -eq 'XIV') {
        foreach ($article in $part.articles) {
            if ($article.id -in $targetArticles) {
                $article.text = [regex]::Replace($article.text, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
            }
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
# passing array directly without -InputObject
$jsonOut = ConvertTo-Json $array -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Output "Fixed."
