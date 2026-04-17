$lines = Get-Content -Path "part6_extracted.txt" -Encoding UTF8
$articles = @()
$currentArticle = $null
$emdash = [char]0x2014

foreach ($line in $lines) {
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
    $pattern = '^(?:1\[)?(\d+[A-Z]*)\.\s*(.*?)' + $emdash + '(.*)$'
    if ($line -match $pattern) {
        if ($null -ne $currentArticle) { $articles += $currentArticle }
        
        $id = $matches[1]
        $titlePart = $matches[2]
        $content = $matches[3]
        
        $titleStr = "Article " + $id + ": " + ($titlePart -replace '\[', '') -replace '\]', ''
        
        $replacePattern = '^(?:1\[)?(\d+[A-Z]*\.\s*.*?)' + $emdash
        $replaceString = "<strong>Article `$1." + $emdash + "</strong>"
        $textVal = $line -replace $replacePattern, $replaceString
        
        $preview = $content
        if ($preview.Length -gt 150) {
            $preview = $preview.Substring(0, 150) + "..."
        }
        
        $currentArticle = @{
            id = $id
            title = $titleStr
            preview = $preview
            text = $textVal
        }
    } else {
        if ($null -ne $currentArticle) {
            $lineProcessed = $line
            if ($line -match '^Amendments:') {
                $lineProcessed = "<strong>Amendments:</strong>"
            }
            $currentArticle.text += "\n" + $lineProcessed
        }
    }
}
if ($null -ne $currentArticle) { $articles += $currentArticle }

for ($i=0; $i -lt $articles.Count; $i++) {
    $txt = $articles[$i].text
    $txt = [regex]::Replace($txt, '(\d+)\[', '<sup>$1</sup>[')
    $txt = [regex]::Replace($txt, '(\d+)\*\*\*', '<sup>$1</sup>***')
    $articles[$i].text = $txt
}

$part6 = @{
    partId = "VI"
    partTitle = "Part VI - The States"
    partDesc = "Articles 152 to 237 covering the executive, legislature, and judiciary of the States."
    articles = $articles
}

$jsonContent = Get-Content -Path "data\articles.json" -Raw -Encoding UTF8
$jsonObj = $jsonContent | ConvertFrom-Json

$newArray = @()
foreach ($p in $jsonObj) {
    if ($p.partId -ne "VI") {
        $newArray += $p
    }
}
$newArray += $part6

$newJson = $newArray | ConvertTo-Json -Depth 10
$newJson | Set-Content -Path "data\articles.json" -Encoding UTF8
Write-Output "Successfully updated articles.json"
