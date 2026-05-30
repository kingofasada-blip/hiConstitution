# ============================================================
# update_variant_arts_final.ps1  
# Uses decimal codepoints for Devanagari: ka=2325, kha=2326, ga=2327
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'
$paragraphs  = [regex]::Matches($xmlContent, $paraPattern)

$ka  = [string][char]2325  # क
$kha = [string][char]2326  # ख
$ga  = [string][char]2327  # ग

$articleBodies = @{}
$currentArt = $null

foreach ($para in $paragraphs) {
    $pPrMatch = [regex]::Match($para.Value, '(?s)<w:pPr>(.*?)</w:pPr>')
    $paraLevelBold = $pPrMatch.Success -and ($pPrMatch.Value -match '<w:b[/ >]|<w:b>')
    
    $runs = [regex]::Matches($para.Value, $runPattern)
    $lineSegments = [System.Collections.Generic.List[string]]::new()
    $hasText = $false
    $anyBold = $false
    
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
    $plain    = [regex]::Replace($combined, '<[^>]+>', '')
    
    # Detect variant article: number + ka/kha/ga + dot
    $artNum = $null
    $artInt = 0
    
    if ($plain -match "(\d+)$ka\." ) {
        $num = $Matches[1]
        if ([int]::TryParse($num, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) { $artNum = "$num`A" }
    } elseif ($plain -match "(\d+)$kha\.") {
        $num = $Matches[1]
        if ([int]::TryParse($num, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) { $artNum = "${num}B" }
    } elseif ($plain -match "(\d+)$ga\.") {
        $num = $Matches[1]
        if ([int]::TryParse($num, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) { $artNum = "${num}C" }
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
                $finalText = if ($bodyPart.Trim() -ne '') { "<strong>$titlePart</strong>$bodyPart" } else { "<strong>$($plain.TrimEnd())</strong>" }
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
foreach ($id in ($articleBodies.Keys | Sort-Object)) {
    Write-Host ""
    Write-Host "=== Art $id (first 150) ==="
    Write-Host $hindiData[$id].Substring(0, [Math]::Min(150, $hindiData[$id].Length))
}

# ---- Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

$updH = 0
foreach ($id in $articleBodies.Keys) {
    $art = $p5.articles | Where-Object { $_.id -eq $id }
    if ($art -and $hindiData[$id].Trim() -ne '') {
        $art.hindi = $hindiData[$id]
        Write-Host "Updated: $id"
        $updH++
    } else {
        Write-Host "NOT FOUND in JSON: $id"
    }
}
Write-Host "Total updated: $updH"

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# Final check
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
Write-Host ""
Write-Host "=== Still missing hindi ==="
$missing = 0
foreach ($art in $p5v.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') { Write-Host "  $($art.id)"; $missing++ }
}
if ($missing -eq 0) { Write-Host "  NONE! All 107 articles complete!" }
