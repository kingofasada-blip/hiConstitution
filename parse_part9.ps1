$lines = Get-Content -Path "part9.txt" -Encoding UTF8
$articles = @()
$currentArticle = $null

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
    # Remove leading/trailing spaces
    $line = $line.Trim()
    
    # Match Article Number, Title, and text after dash
    # Matches formats like "243. Definitions.—" or "243A. Gram Sabha.-" or "243B. Title --"
    $pattern = '^(\d{3}[A-Z]*)\.\s*(.*?)(?:—|--|-)\s*(.*)$'
    
    if ($line -match $pattern) {
        if ($null -ne $currentArticle) { $articles += $currentArticle }
        
        $id = $matches[1]
        $titlePart = $matches[2]
        $content = $matches[3]
        
        $titleStr = "Article " + $id + ": " + ($titlePart -replace '\[', '') -replace '\]', ''
        
        $textVal = "<strong>Article " + $id + ". " + $titlePart + "—</strong>"
        if (![string]::IsNullOrWhiteSpace($content)) {
            $textVal += "`n" + $content
        }
        
        $preview = $content
        
        $currentArticle = @{
            id = $id
            title = $titleStr
            preview = $preview
            text = $textVal
        }
    } else {
        if ($null -ne $currentArticle) {
            $lineProcessed = $line
            # Automatically Highlight Amendments Header
            if ($line -match '^(Amendments?|संशोधन):') {
                $lineProcessed = "<strong>" + $matches[1] + ":</strong>"
            }
            
            $currentArticle.text += "`n" + $lineProcessed
            
            # Generate preview from the first body line if preview is empty
            if ([string]::IsNullOrWhiteSpace($currentArticle.preview)) {
                $currentArticle.preview = $line
            }
        }
    }
}
if ($null -ne $currentArticle) { $articles += $currentArticle }

# Post processing for superscripts and trimming previews
for ($i=0; $i -lt $articles.Count; $i++) {
    $txt = $articles[$i].text
    # Convert '1[' to superscript
    $txt = [regex]::Replace($txt, '(\d+)\[', '<sup>$1</sup>[')
    $txt = [regex]::Replace($txt, '(\d+)\*\*\*', '<sup>$1</sup>***')
    $articles[$i].text = $txt
    
    if ($articles[$i].preview.Length -gt 150) {
        $articles[$i].preview = $articles[$i].preview.Substring(0, 150) + "..."
    }
}

$part9 = @{
    partId = "IX"
    partTitle = "Part IX - The Panchayats"
    partDesc = "Articles 243 to 243O detailing the constitution, composition, and powers of Panchayats."
    articles = $articles
}

# Read existing JSON
$jsonContent = Get-Content -Path "data\articles.json" -Raw -Encoding UTF8
$jsonObj = $jsonContent | ConvertFrom-Json

# Insert Part 9 logic (replaces if exists, otherwise appends)
$newArray = @()
foreach ($p in $jsonObj) {
    if ($p.partId -ne "IX") {
        $newArray += $p
    }
}
$newArray += $part9

# Sort the array logically? Right now we just append it. Your frontend usually handles the order, or we can leave it appended.
# Actually, Part 9 should come after Part 8. But appending is fine as long as part.html finds it by ID.

# Write back to JSON
$newArray | ConvertTo-Json -Depth 10 | Set-Content -Path "data\articles.json" -Encoding UTF8

Write-Output "✅ Successfully generated and added Part 9 to articles.json!"
