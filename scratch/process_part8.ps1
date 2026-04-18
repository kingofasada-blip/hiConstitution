$lines = Get-Content "scratch/part8_parsed.txt" -Encoding UTF8
$articles = @()
$currentArticle = $null
$emdash = "—"

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
    $matchRes = [regex]::Match($line, '^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰\*]+\[)?<strong>(\d+[A-Z]*)\.\s*(.*?)\]?</strong>' + $emdash + '(.*)$')
    if (-not $matchRes.Success) {
        $matchRes = [regex]::Match($line, '^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰\*]+\[)?<strong>(\d+[A-Z]*)\.\s*(.*?)</strong>' + $emdash + '(.*)$')
    }
    
    if (-not $matchRes.Success) {
        $matchRes = [regex]::Match($line, '^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰\*]+\[)?<strong>(\d+[A-Z]*)\.\s*\[(.*?)\]\.\]?</strong>' + $emdash + '(.*)$')
    }

    if ($matchRes.Success) {
        if ($null -ne $currentArticle) { $articles += $currentArticle }
        
        $id = $matchRes.Groups[1].Value
        $titlePart = $matchRes.Groups[2].Value -replace '\[', '' -replace '\]', ''
        $content = $matchRes.Groups[3].Value
        
        $titleStr = "Article " + $id + ": " + $titlePart
        $textVal = $line -replace '<strong>\d+[A-Z]*\.\s*.*?</strong>' + $emdash, ("<strong>Article " + $id + ". " + $titlePart + ".—</strong>")
        
        $preview = ($content -replace '<.*?>', '').Trim()
        if ($preview.Length -gt 150) { $preview = $preview.Substring(0, 150) + "..." }
        
        $currentArticle = @{ id = $id; title = $titleStr; preview = $preview; text = $textVal }
        $inAmendments = $false
        $amendmentCounter = 1
    } else {
        if ($null -ne $currentArticle) {
            $lineProcessed = $line
            if ($line -match '^<strong>Amendments:</strong>') {
                $lineProcessed = "<strong>Amendments:</strong>"
                $inAmendments = $true
                $amendmentCounter = 1
            } elseif ($inAmendments) {
                if ($lineProcessed -match '^\*') { }
                else {
                    $lineProcessed = "<sup><strong>" + $amendmentCounter + "</strong></sup>" + $lineProcessed
                    $amendmentCounter++
                }
            }
            $currentArticle.text += "`n" + $lineProcessed
        }
    }
}
if ($null -ne $currentArticle) { $articles += $currentArticle }

for ($i=0; $i -lt $articles.Count; $i++) {
    $art = $articles[$i]
    $lines = $art.text -split "`n"
    $newLines = @()
    $amendments = @()
    $inAm = $false
    foreach ($l in $lines) {
        if ($l -eq '<strong>Amendments:</strong>') { $inAm = $true; continue }
        if ($inAm) { $amendments += $l } else { $newLines += $l }
    }
    
    if ($amendments.Count -gt 0) {
        $newLines += "<strong>Amendments:</strong>"
        if ($amendments.Count -gt 2) {
            $newLines += $amendments[0]
            $newLines += $amendments[1]
            $newLines += "<details><summary>Show more... →</summary>"
            for ($k=2; $k -lt $amendments.Count; $k++) { $newLines += $amendments[$k] }
            $newLines += "</details>"
        } elseif ($amendments.Count -eq 2 -and ($amendments[0].Length + $amendments[1].Length) -gt 200) {
            $newLines += $amendments[0]
            $newLines += "<details><summary>Show more... →</summary>"
            $newLines += $amendments[1]
            $newLines += "</details>"
        } elseif ($amendments.Count -eq 1 -and $amendments[0].Length -gt 200) {
            $text = $amendments[0]
            $splitIndex = $text.IndexOf(". ")
            if ($splitIndex -gt 0 -and $splitIndex -lt 150) {
                $newLines += $text.Substring(0, $splitIndex + 1)
                $newLines += "<details><summary>Show more... →</summary>"
                $newLines += $text.Substring($splitIndex + 1).Trim()
                $newLines += "</details>"
            } else { $newLines += $amendments[0] }
        } else { foreach ($am in $amendments) { $newLines += $am } }
    }
    
    $fullText = $newLines -join "`n"
    $fullText = $fullText -replace '¹⁰', '<sup><strong>10</strong></sup>'
    $fullText = $fullText -replace '¹¹', '<sup><strong>11</strong></sup>'
    $fullText = $fullText -replace '¹', '<sup><strong>1</strong></sup>'
    $fullText = $fullText -replace '²', '<sup><strong>2</strong></sup>'
    $fullText = $fullText -replace '³', '<sup><strong>3</strong></sup>'
    $fullText = $fullText -replace '⁴', '<sup><strong>4</strong></sup>'
    $fullText = $fullText -replace '⁵', '<sup><strong>5</strong></sup>'
    $fullText = $fullText -replace '⁶', '<sup><strong>6</strong></sup>'
    $fullText = $fullText -replace '⁷', '<sup><strong>7</strong></sup>'
    $fullText = $fullText -replace '⁸', '<sup><strong>8</strong></sup>'
    $fullText = $fullText -replace '⁹', '<sup><strong>9</strong></sup>'
    
    $articles[$i].text = $fullText
}

$part8 = @{
    partId = "VIII"
    partTitle = "Part VIII - The Union Territories"
    partDesc = "Articles 239 to 242 covering the administration of Union territories."
    articles = $articles
}

$jsonItems = Get-Content 'data\articles.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$pos = -1
for ($i=0; $i -lt $jsonItems.Length; $i++) {
    if ($jsonItems[$i].partId -eq "VII") { $pos = $i; break }
}
if ($pos -eq -1) { 
    for ($i=0; $i -lt $jsonItems.Length; $i++) {
        if ($jsonItems[$i].partId -eq "VI") { $pos = $i; break }
    }
}

$newJsonArr = @()
for ($i=0; $i -lt $jsonItems.Length; $i++) {
    if ($jsonItems[$i].partId -eq "VIII") { continue } # prevent duplicates
    $newJsonArr += $jsonItems[$i]
    if ($i -eq $pos) { $newJsonArr += $part8 }
}

$newJsonArr | ConvertTo-Json -Depth 10 | Set-Content 'data\articles.json' -Encoding UTF8
Write-Host "Processed Part 8 successfully with " $articles.Count " articles."
