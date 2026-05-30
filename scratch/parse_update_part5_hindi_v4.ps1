# ============================================================
# parse_update_part5_hindi_v4.ps1
# Handles articles starting with superscript+bracket: ¹[103. ...]
# and regular: 58. ...
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)

$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'

$paragraphs = [regex]::Matches($xmlContent, $paraPattern)

# ---- Parse paragraphs with bold info ----
$parsedParas = [System.Collections.Generic.List[hashtable]]::new()

foreach ($para in $paragraphs) {
    $paraXml = $para.Value
    $pPrMatch = [regex]::Match($paraXml, '(?s)<w:pPr>(.*?)</w:pPr>')
    $paraLevelBold = $pPrMatch.Success -and ($pPrMatch.Value -match '<w:b[/ >]|<w:b>')
    
    $runs = [regex]::Matches($paraXml, $runPattern)
    $lineSegments = [System.Collections.Generic.List[string]]::new()
    $hasText = $false
    $anyBold = $false
    
    foreach ($run in $runs) {
        $runXml = $run.Value
        $rPrMatch = [regex]::Match($runXml, '(?s)<w:rPr>(.*?)</w:rPr>')
        $runBold = $paraLevelBold
        if ($rPrMatch.Success) {
            if ($rPrMatch.Value -match '<w:b[/ >]|<w:b>|<w:bCs[/ >]|<w:bCs>') { $runBold = $true }
            if ($rPrMatch.Value -match 'w:val="0"') { $runBold = $false }
        }
        
        $hasBreak = $runXml -match '<w:br[^/]*/>'
        $tMatches = [regex]::Matches($runXml, $tPattern)
        $runText = ''
        foreach ($tm in $tMatches) { $runText += $tm.Groups[1].Value }
        $runText = $runText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
        
        if ($runText -ne '') {
            $hasText = $true
            if ($runBold) {
                $anyBold = $true
                $lineSegments.Add("<strong>$runText</strong>")
            } else {
                $lineSegments.Add($runText)
            }
        }
        if ($hasBreak -and $lineSegments.Count -gt 0) { $lineSegments.Add("`n") }
    }
    
    if ($hasText) {
        $combined = ([string]::Join('', $lineSegments)).Trim()
        # Merge adjacent strong tags
        $combined = $combined -replace '</strong><strong>', ''
        $parsedParas.Add(@{ text = $combined; isBold = $anyBold })
    }
}

Write-Host "Paragraphs: $($parsedParas.Count)"

# ---- Group by article ----
$articleBodies = @{}
$currentArt = $null

foreach ($para in $parsedParas) {
    $text = $para.text
    $plain = [regex]::Replace($text, '<[^>]+>', '')
    
    $artNum = $null
    
    # Pattern 1: "58. Title" — plain number
    if ($plain -match '^(\d+[A-Za-z]?)\.\s+') {
        $candidate = $Matches[1]
        $baseNum = [regex]::Match($candidate, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $artNum = $candidate
        }
    }
    # Pattern 2: "¹[103. Title" or "1[103. Title" — superscript+bracket prefix
    elseif ($plain -match '^.{0,5}\[(\d+[A-Za-z]?)\.\s+') {
        $candidate = $Matches[1]
        $baseNum = [regex]::Match($candidate, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $artNum = $candidate
        }
    }
    # Pattern 3: "¹[131क." or "¹[124क." — Hindi article letters (क=A, ख=B, ग=C)
    # These appear as "131A", "124A" etc in our JSON but as "131क" in Hindi
    # Map: क=A, ख=B, ग=C
    elseif ($plain -match '^.{0,5}\[(\d+)[कखग]\.\s+') {
        $baseNum = $Matches[1]
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            # Find the actual suffix character
            if ($plain -match '^.{0,5}\[(\d+)(क)\.\s+') { $artNum = $Matches[1] + 'A' }
            elseif ($plain -match '^.{0,5}\[(\d+)(ख)\.\s+') { $artNum = $Matches[1] + 'B' }
            elseif ($plain -match '^.{0,5}\[(\d+)(ग)\.\s+') { $artNum = $Matches[1] + 'C' }
        }
    }
    
    if ($artNum) {
        $currentArt = $artNum
        if (-not $articleBodies.ContainsKey($currentArt)) {
            $articleBodies[$currentArt] = [System.Collections.Generic.List[string]]::new()
        }
        
        # Wrap title in <strong> if not already
        $finalText = $text
        if (-not $text.TrimStart().StartsWith('<strong>')) {
            $emDashPos = $plain.IndexOf([char]0x2014)  # em dash —
            $dashPos = $plain.IndexOf('–')  # en dash
            $colonPos = $plain.IndexOf('–')
            $splitPos = if ($emDashPos -gt 0) { $emDashPos } elseif ($dashPos -gt 0) { $dashPos } else { -1 }
            
            if ($splitPos -gt 0 -and $splitPos -lt 150) {
                $titlePart = $plain.Substring(0, $splitPos + 1)
                $bodyPart = $plain.Substring($splitPos + 1)
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
        $articleBodies[$currentArt].Add($text)
    }
}

Write-Host "Articles parsed: $($articleBodies.Count)"
$sorted = $articleBodies.Keys | Sort-Object { 
    $n = [regex]::Match($_, '^\d+').Value
    [int]$n
}
Write-Host "All keys: $($sorted -join ', ')"

$hindiData = @{}
foreach ($artNum in $articleBodies.Keys) {
    $lines = $articleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $lines)
}

# Preview missing ones
foreach ($id in @('103', '124A', '124B', '124C', '131A', '134A', '139A', '144A', '150')) {
    Write-Host ""
    Write-Host "=== Art $id ==="
    if ($hindiData[$id]) { 
        Write-Host $hindiData[$id].Substring(0, [Math]::Min(150, $hindiData[$id].Length))
    } else {
        Write-Host "NOT FOUND"
    }
}

# ---- Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') { $part5idx = $i; break }
}

$updH = 0; $noData = 0
foreach ($article in $json[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    if ($hindiData.ContainsKey($artId) -and $hindiData[$artId].Trim() -ne '') {
        $article.hindi = $hindiData[$artId]
        $updH++
    } else {
        $noData++
        Write-Host "  Still no data: $artId"
    }
}
Write-Host ""
Write-Host "Updated: $updH | No data: $noData"

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# Final verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
Write-Host ""
Write-Host "=== Final missing hindi ==="
$missing = 0
foreach ($art in $p5v.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') {
        Write-Host "  $($art.id)"
        $missing++
    }
}
if ($missing -eq 0) { Write-Host "  None! All articles have hindi." }
