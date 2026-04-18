$lines = Get-Content -Path "c:\Users\DeLL\Desktop\hiCONSTITUTION\part9_raw.txt" -Encoding UTF8
$articles = @()
$currentArticle = $null

$artPattern = '^(\d{3}[A-Z]*)\.\s+(.*?)(?:--|-)\s*(.*)$'

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $line = $line.Trim()
    
    # Pre-clean em-dash
    $line = $line -replace '—', '-'
    
    if ($line -match '^PART IX THE PANCHAYATS' -or $line -match '^As per your instructions' -or $line -match '^Ins\. by the') { continue }
    
    $isMatch = $line -match $artPattern
    if ($isMatch) {
        if ($null -ne $currentArticle) { $articles += $currentArticle }
        
        $artId = $matches[1]
        $artTitlePart = ($matches[2] -replace '\[', '') -replace '\]', ''
        $content = $matches[3]
        
        $titleStr = "Article ${artId}: ${artTitlePart}"
        $textVal = "<strong>Article ${artId}. ${artTitlePart}-</strong>"
        
        if (![string]::IsNullOrWhiteSpace($content)) {
            $contentProcessed = [regex]::Replace($content, '(?<=[\.\s])(\(\d+\)|\([a-z]\)|Provided that|Provided further that)', '`n$1')
            $textVal += "``n" + $contentProcessed
        }
        
        $currentArticle = @{
            id = $artId
            title = $titleStr
            preview = $content
            text = $textVal
        }
    } else {
        if ($null -ne $currentArticle) {
            $amendMatch = $line -match '^(Amendments?|संशोधन):'
            
            if ($amendMatch) {
                $m1 = $matches[1]
                $lineProcessed = "<strong>${m1}:</strong>"
            } else {
                $lineProcessed = [regex]::Replace($line, '(?<=[\.\s])(\(\d+\)|\([a-z]\)|Provided that|Provided further that)', '`n$1')
            }
            
            $lineProcessed = [regex]::Replace($lineProcessed, '(\d+)\[', '<sup>$1</sup>[')
            $lineProcessed = [regex]::Replace($lineProcessed, '(\d+)\*\*\*', '<sup>$1</sup>***')
            $lineProcessed = [regex]::Replace($lineProcessed, '¹\[', '<sup>1</sup>[')
            
            $currentArticle.text += "``n" + $lineProcessed
            if ([string]::IsNullOrWhiteSpace($currentArticle.preview)) {
                $currentArticle.preview = $line
            }
        }
    }
}
if ($null -ne $currentArticle) { $articles += $currentArticle }

for ($i = 0; $i -lt $articles.Count; $i++) {
    $preview = $articles[$i].preview
    $preview = $preview -replace '``n', ''
    if ($preview.Length -gt 150) {
        $articles[$i].preview = $preview.Substring(0, 150) + "..."
    } else {
        $articles[$i].preview = $preview
    }
}

$part9 = @{
    partId = "IX"
    partTitle = "Part IX - The Panchayats"
    partDesc = "Articles 243 to 243O detailing the constitution, composition, powers, and duration of Panchayats."
    articles = $articles
}

$jsonText = Get-Content -Path "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json" -Raw -Encoding UTF8
$schema = $jsonText | ConvertFrom-Json

$newSchema = @()
foreach ($p in $schema) {
    if ($p.partId -eq "IX") { continue }
    $newSchema += $p
    if ($p.partId -eq "VIII") {
        $newSchema += $part9
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $False
$jsonOutput = $newSchema | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText("c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", $jsonOutput, $utf8NoBom)

Write-Output "Part IX successfully extracted and merged below Part VIII."
