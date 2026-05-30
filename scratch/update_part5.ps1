# ============================================================
# update_part5.ps1 - Updates Part V in articles.json
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- Step 1: Parse Simplified docx ----
$xmlContentSimp = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_simplified_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$paraMatches = [regex]::Matches($xmlContentSimp, $paraPattern)

$simpLines = [System.Collections.Generic.List[string]]::new()
foreach ($para in $paraMatches) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    $lineText = [string]::Join('', ($tMatches | ForEach-Object { $_.Groups[1].Value }))
    $lineText = $lineText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
    $simpLines.Add($lineText)
}

# Parse into article data
$simpEng = @{}
$simpHin = @{}

$currentArt = $null
$collectEng = $false
$collectHin = $false

foreach ($line in $simpLines) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^Article (\d+[A-Za-z]?)$') {
        $currentArt = $Matches[1]
        $simpEng[$currentArt] = ''
        $simpHin[$currentArt] = ''
        $collectEng = $false
        $collectHin = $false
    }
    elseif ($trimmed -match '^Simplified English:\s*(.*)') {
        if ($currentArt) {
            $simpEng[$currentArt] = $Matches[1].Trim()
            $collectEng = $true
            $collectHin = $false
        }
    }
    elseif ($trimmed -match '^Simplified Hindi:\s*(.*)') {
        if ($currentArt) {
            $simpHin[$currentArt] = $Matches[1].Trim()
            $collectEng = $false
            $collectHin = $true
        }
    }
    elseif ($trimmed -ne '' -and $currentArt) {
        if ($collectEng) {
            $simpEng[$currentArt] += ' ' + $trimmed
        } elseif ($collectHin) {
            $simpHin[$currentArt] += ' ' + $trimmed
        }
    }
}

Write-Host "Simplified articles parsed: $($simpEng.Count)"

# ---- Step 2: Parse Hindi Original docx ----
$xmlContentHindi = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_original_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraMatchesH = [regex]::Matches($xmlContentHindi, $paraPattern)

$hindiLines = [System.Collections.Generic.List[string]]::new()
foreach ($para in $paraMatchesH) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    $lineText = [string]::Join('', ($tMatches | ForEach-Object { $_.Groups[1].Value }))
    $lineText = $lineText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
    $hindiLines.Add($lineText)
}

# Parse Hindi article bodies
# Article header pattern (unicode): article number in digits after "अनुच्छेद" or "1[अनुच्छेद"
# We detect by looking for lines containing an article number pattern
$hindiArticleBodies = @{}
$currentArtH = $null

foreach ($line in $hindiLines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '') { continue }
    
    # Check if this line is an article header - it should contain digit(s) after the word for "article"
    # Pattern: optional prefix + article-word + space + number + colon
    # We detect by: contains a number like "52", "124A" in context
    # Use codepoint-agnostic approach: look for lines that end with digit pattern after colon-like structure
    # The simplified doc lines start with "Article 52" - for Hindi original, headers look like:
    # "[whitespace]अनुच्छेद 52 : भारत का राष्ट्रपति"
    # We match by checking if after extracting all digits, the pattern matches
    
    # Try matching article number from Hindi article header
    # Hindi article header always has format containing article number preceded by unicode art word
    if ($trimmed -match '(?:^\d+\[)?[^\d]*(\d+[A-Za-z]?)\s*:') {
        $possibleArtNum = $Matches[1]
        # Validate it's a real article (52-151 for Part V, plus variants like 124A, 131A etc)
        $artNumInt = 0
        $baseNum = [regex]::Match($possibleArtNum, '^\d+').Value
        if ([int]::TryParse($baseNum, [ref]$artNumInt) -and $artNumInt -ge 52 -and $artNumInt -le 151) {
            $currentArtH = $possibleArtNum
            if (-not $hindiArticleBodies.ContainsKey($currentArtH)) {
                $hindiArticleBodies[$currentArtH] = [System.Collections.Generic.List[string]]::new()
            }
            continue  # Don't add header to body
        }
    }
    
    if ($currentArtH) {
        # Skip amendment lines - they start with digits followed by period (footnotes)
        # and lines that are just numbers
        $isAmendmentNote = $trimmed -match '^\d+\.\s+' -or $trimmed -match '^\s*\d+\s*$'
        $isAmendmentHeader = $trimmed -match '^[\u0900-\u097F]*\s*:\s*$'  # "संशोधन :" type lines
        
        if (-not $isAmendmentNote -and -not $isAmendmentHeader) {
            $hindiArticleBodies[$currentArtH].Add($trimmed)
        }
    }
}

$hindiData = @{}
foreach ($artNum in $hindiArticleBodies.Keys) {
    $bodyLines = $hindiArticleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $bodyLines)
}

Write-Host "Hindi original articles parsed: $($hindiData.Count)"
Write-Host "Keys: $($hindiData.Keys | Sort-Object | Select-Object -First 10)"

# ---- Step 3: Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'

# Backup first
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5.json'
Copy-Item $jsonPath $backupPath -Force
Write-Host "Backup saved to: $backupPath"

$jsonRaw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
$json = $jsonRaw | ConvertFrom-Json

$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') {
        $part5idx = $i
        break
    }
}

if ($part5idx -eq -1) {
    Write-Host "ERROR: Part V not found!"
    exit 1
}

Write-Host "Part V at index $part5idx, article count: $($json[$part5idx].articles.Count)"

$updatedHindi = 0
$updatedHindiSimp = 0
$updatedEng = 0

foreach ($article in $json[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    
    # Update hindi original
    if ($hindiData.ContainsKey($artId) -and $hindiData[$artId].Trim() -ne '') {
        $article.hindi = $hindiData[$artId]
        $updatedHindi++
    }
    
    # Update hindiSimplified
    if ($simpHin.ContainsKey($artId) -and $simpHin[$artId].Trim() -ne '') {
        if ($article.PSObject.Properties['hindiSimplified']) {
            $article.hindiSimplified = $simpHin[$artId].Trim()
        } else {
            $article | Add-Member -MemberType NoteProperty -Name 'hindiSimplified' -Value $simpHin[$artId].Trim() -Force
        }
        $updatedHindiSimp++
    }
    
    # Update simplified English (from simplified docx)
    if ($simpEng.ContainsKey($artId) -and $simpEng[$artId].Trim() -ne '') {
        $article.simplified = $simpEng[$artId].Trim()
        $updatedEng++
    }
}

Write-Host "Updated hindi: $updatedHindi"
Write-Host "Updated hindiSimplified: $updatedHindiSimp"
Write-Host "Updated simplified (eng): $updatedEng"

# Save
$jsonSettings = [Newtonsoft.Json.JsonSerializerSettings]::new()
$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, [System.Text.Encoding]::new(65001, $false))  # UTF8 no BOM

Write-Host "SUCCESS: articles.json updated!"

# Quick verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $verify | Where-Object { $_.partId -eq 'V' }
$art52 = $p5.articles | Where-Object { $_.id -eq '52' }
Write-Host ""
Write-Host "=== Verify Art 52 ==="
Write-Host "hindi: $($art52.hindi)"
Write-Host "hindiSimplified: $($art52.hindiSimplified)"
Write-Host "simplified: $($art52.simplified)"
