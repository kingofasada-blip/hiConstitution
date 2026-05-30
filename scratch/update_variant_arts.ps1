# ============================================================
# update_variant_arts.ps1
# Finds and updates 124A/B/C, 131A, 134A, 139A, 144A
# These appear as: ¹[124क. , ¹[131क. etc in docx
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'
$paragraphs  = [regex]::Matches($xmlContent, $paraPattern)

# Map: Hindi suffix letter => English suffix used in JSON id
# क(U+2325)=A, ख(U+2326)=B... wait let me check
# From debug: 134क = U+49,51,52,2325,46 => "134" + U+2325(क) + "."
# 139क = U+49,51,57,2325 => "139" + क
# 144क = U+49,52,52,2325 => "144" + क
# So: क(U+2325) => A
# Need to check what 124ख and 124ग look like - they weren't found, so maybe only क variants exist

# Hindi suffix map
$suffixMap = @{
    [char]0x2325 = 'A'  # क -> A
    [char]0x2326 = 'B'  # ख -> B  
    [char]0x2327 = 'C'  # ग -> C
}

# Article number + Hindi suffix regex:
# Pattern: starts with optional "¹[" then digits then Hindi-letter then "."
# Use char codes to match: U+185(¹) + U+91([) + digits + ka/kha/ga + dot

$articleBodies = @{}
$currentArt = $null

foreach ($para in $paragraphs) {
    $runs = [regex]::Matches($para.Value, $runPattern)
    $lineSegments = [System.Collections.Generic.List[string]]::new()
    $hasText = $false
    $anyBold = $false
    
    # Get paragraph-level bold
    $pPrMatch = [regex]::Match($para.Value, '(?s)<w:pPr>(.*?)</w:pPr>')
    $paraLevelBold = $pPrMatch.Success -and ($pPrMatch.Value -match '<w:b[/ >]|<w:b>')
    
    foreach ($run in $runs) {
        $runXml = $run.Value
        $rPrMatch = [regex]::Match($runXml, '(?s)<w:rPr>(.*?)</w:rPr>')
        $runBold = $paraLevelBold
        if ($rPrMatch.Success) {
            if ($rPrMatch.Value -match '<w:b[/ >]|<w:b>|<w:bCs[/ >]') { $runBold = $true }
            if ($rPrMatch.Value -match 'w:val="0"') { $runBold = $false }
        }
        $tMatches = [regex]::Matches($runXml, $tPattern)
        $runText = ''
        foreach ($tm in $tMatches) { $runText += $tm.Groups[1].Value }
        $runText = $runText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
        if ($runText -ne '') {
            $hasText = $true
            if ($runBold) { $anyBold = $true; $lineSegments.Add("<strong>$runText</strong>") }
            else { $lineSegments.Add($runText) }
        }
        if ($runXml -match '<w:br[^/]*/>' -and $lineSegments.Count -gt 0) { $lineSegments.Add("`n") }
    }
    
    if (-not $hasText) { continue }
    
    $combined = ([string]::Join('', $lineSegments)).Trim() -replace '</strong><strong>', ''
    $plain = [regex]::Replace($combined, '<[^>]+>', '')
    
    # Try to detect variant article header: digits + ka/kha/ga + dot
    $artNum = $null
    
    # Check: string contains pattern like "134क." or "¹[134क."
    # Use regex matching on Unicode codepoints
    # Match: optional prefix chars + digits(52-151) + (क|ख|ग) + dot
    if ($plain -match '(\d+)([\u2325\u2326\u2327])\.\s') {
        $numPart = $Matches[1]
        $suffixChar = $Matches[2][0]
        $artInt = 0
        if ([int]::TryParse($numPart, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $engSuffix = if ($suffixChar -eq [char]0x2325) { 'A' } elseif ($suffixChar -eq [char]0x2326) { 'B' } elseif ($suffixChar -eq [char]0x2327) { 'C' } else { '' }
            if ($engSuffix -ne '') {
                $artNum = "$numPart$engSuffix"
            }
        }
    }
    
    if ($artNum) {
        $currentArt = $artNum
        if (-not $articleBodies.ContainsKey($currentArt)) {
            $articleBodies[$currentArt] = [System.Collections.Generic.List[string]]::new()
        }
        # Wrap title in <strong>
        $finalText = $combined
        if (-not $combined.TrimStart().StartsWith('<strong>')) {
            $emPos = $plain.IndexOf([char]0x2014)
            $enPos = $plain.IndexOf([char]0x2013)
            $splitPos = if ($emPos -gt 0) { $emPos } elseif ($enPos -gt 0) { $enPos } else { -1 }
            if ($splitPos -gt 0 -and $splitPos -lt 200) {
                $titlePart = $plain.Substring(0, $splitPos + 1)
                $bodyPart  = $plain.Substring($splitPos + 1)
                if ($bodyPart.Trim() -ne '') {
                    $finalText = "<strong>$titlePart</strong>$bodyPart"
                } else {
                    $finalText = "<strong>$($plain.TrimEnd())</strong>"
                }
            } else {
                $finalText = "<strong>$($plain.TrimEnd())</strong>"
            }
        }
        $articleBodies[$currentArt].Add($finalText)
        continue
    }
    
    if ($currentArt) {
        $articleBodies[$currentArt].Add($combined)
    }
}

Write-Host "Variant articles parsed: $($articleBodies.Count)"
Write-Host "Keys: $($articleBodies.Keys -join ', ')"

$hindiData = @{}
foreach ($artNum in $articleBodies.Keys) {
    $lines = $articleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $lines)
}

# Preview
foreach ($id in $articleBodies.Keys) {
    Write-Host ""
    Write-Host "=== Art $id ==="
    Write-Host $hindiData[$id].Substring(0, [Math]::Min(150, $hindiData[$id].Length))
}

# ---- Update articles.json (only these variant articles) ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

$updH = 0
foreach ($id in $articleBodies.Keys) {
    $art = $p5.articles | Where-Object { $_.id -eq $id }
    if ($art -and $hindiData[$id].Trim() -ne '') {
        $art.hindi = $hindiData[$id]
        Write-Host "Updated Art $id"
        $updH++
    }
}
Write-Host "Total updated: $updH"

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# Final missing check
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
Write-Host ""
Write-Host "=== Still missing hindi ==="
$missing = 0
foreach ($art in $p5v.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') {
        Write-Host "  $($art.id)"
        $missing++
    }
}
if ($missing -eq 0) { Write-Host "  NONE! All 107 articles have hindi. COMPLETE!" }
