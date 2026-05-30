# ============================================================
# parse_update_part5_hindi_final.ps1
# Correctly detects article headers with bold formatting
# Article header pattern: "NN. Title—" where NN is 52-151
# Post-processes to ensure title part gets <strong> wrapping
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)

$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'

$paragraphs = [regex]::Matches($xmlContent, $paraPattern)

# ---- Parse paragraphs with bold-per-run info ----
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
    
    # Article header: starts with NUMBER. (52-151)
    $artNum = $null
    if ($plain -match '^(\d+[A-Za-z]?)\.\s+') {
        $candidate = $Matches[1]
        $baseNum = [regex]::Match($candidate, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $artNum = $candidate
        }
    }
    # Also: "1[58. " type amended articles  
    elseif ($plain -match '^\d+\[(\d+[A-Za-z]?)\.\s+') {
        $candidate = $Matches[1]
        $baseNum = [regex]::Match($candidate, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $artNum = $candidate
        }
    }
    
    if ($artNum) {
        $currentArt = $artNum
        if (-not $articleBodies.ContainsKey($currentArt)) {
            $articleBodies[$currentArt] = [System.Collections.Generic.List[string]]::new()
        }
        
        # Ensure title part is bold: wrap "NNN. Title—" in <strong> if not already
        # The title ends at em-dash (—) or colon (:) in the title portion
        # If text does not already start with <strong>, add it
        $finalText = $text
        if (-not $text.TrimStart().StartsWith('<strong>')) {
            # Wrap the whole line as strong if it's a header
            # Find the em-dash or end of title
            $emDashPos = $plain.IndexOf('—')
            if ($emDashPos -gt 0) {
                $titlePart = $plain.Substring(0, $emDashPos + 1)
                $bodyPart = $plain.Substring($emDashPos + 1)
                if ($bodyPart.Trim() -ne '') {
                    $finalText = "<strong>$titlePart</strong>$bodyPart"
                } else {
                    $finalText = "<strong>$($plain)</strong>"
                }
            } else {
                $finalText = "<strong>$($plain)</strong>"
            }
        } else {
            # Already has strong, but ensure the em-dash title part separation
            # Merge consecutive <strong>...</strong> tags into one
            $finalText = $text -replace '</strong><strong>', ''
        }
        
        $articleBodies[$currentArt].Add($finalText)
        continue
    }
    
    if ($currentArt) {
        $isAmendNote = ($plain -match '^\d+\.\s+' -and $plain.Length -lt 250 -and $plain -match '^\d+\.')
        if (-not $isAmendNote) {
            # Merge consecutive <strong> tags in body text too
            $cleanText = $text -replace '</strong><strong>', ''
            $articleBodies[$currentArt].Add($cleanText)
        }
    }
}

Write-Host "Articles parsed: $($articleBodies.Count)"
$sorted = $articleBodies.Keys | Sort-Object { [int]([regex]::Match($_, '^\d+').Value) }
Write-Host "First 10: $($sorted | Select-Object -First 10)"
Write-Host "Last 5: $($sorted | Select-Object -Last 5)"

$hindiData = @{}
foreach ($artNum in $articleBodies.Keys) {
    $lines = $articleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $lines)
}

# Preview with HTML visible
Write-Host ""
Write-Host "=== Art 52 ==="
if ($hindiData['52']) { Write-Host $hindiData['52'] }
Write-Host ""
Write-Host "=== Art 58 first 300 ==="
if ($hindiData['58']) { Write-Host $hindiData['58'].Substring(0, [Math]::Min(300, $hindiData['58'].Length)) }
Write-Host ""
Write-Host "=== Art 74 first 200 ==="
if ($hindiData['74']) { Write-Host $hindiData['74'].Substring(0, [Math]::Min(200, $hindiData['74'].Length)) }

# ---- Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Backup
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5_v2.json'
if (-not (Test-Path $backupPath)) { Copy-Item $jsonPath $backupPath -Force; Write-Host "Backup saved." }

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
    }
}
Write-Host "Updated: $updH | No data: $noData"

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
foreach ($id in @('52','58','74','100','151')) {
    $art = $p5v.articles | Where-Object { $_.id -eq $id }
    Write-Host "Art $id hindi: $(if($art.hindi -and $art.hindi.Length -gt 0){'OK - ' + $art.hindi.Length + ' chars'}else{'EMPTY'})"
}
Write-Host ""
Write-Host "=== Missing hindi ==="
foreach ($art in $p5v.articles) {
    if (-not $art.hindi -or $art.hindi.Trim() -eq '') {
        Write-Host "  $($art.id)"
    }
}
