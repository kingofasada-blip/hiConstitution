# ============================================================
# parse_update_part5_hindi_new.ps1
# Parses new Part 5 Hindi original docx (with bold title support)
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml'
$xmlContent = [System.IO.File]::ReadAllText($xmlPath, [System.Text.Encoding]::UTF8)

$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'

$paragraphs = [regex]::Matches($xmlContent, $paraPattern)

$parsedParas = [System.Collections.Generic.List[hashtable]]::new()

foreach ($para in $paragraphs) {
    $paraXml = $para.Value
    
    # Check paragraph-level bold
    $pPrMatch = [regex]::Match($paraXml, '(?s)<w:pPr>(.*?)</w:pPr>')
    $paraLevelBold = $pPrMatch.Success -and ($pPrMatch.Value -match '<w:b[ /]|<w:bCs[ /]')
    
    $runs = [regex]::Matches($paraXml, $runPattern)
    
    $lineSegments = [System.Collections.Generic.List[string]]::new()
    $hasText = $false
    
    foreach ($run in $runs) {
        $runXml = $run.Value
        
        # Check run bold
        $rPrMatch = [regex]::Match($runXml, '(?s)<w:rPr>(.*?)</w:rPr>')
        $runBold = $paraLevelBold
        if ($rPrMatch.Success) {
            if ($rPrMatch.Value -match '<w:b[/ ]|<w:b>|<w:bCs[/ ]|<w:bCs>') { $runBold = $true }
            if ($rPrMatch.Value -match 'w:val="0"') { $runBold = $false }
        }
        
        # Line break
        $hasBreak = $runXml -match '<w:br[^/]*/>'
        
        # Extract text
        $tMatches = [regex]::Matches($runXml, $tPattern)
        $runText = ''
        foreach ($tm in $tMatches) { $runText += $tm.Groups[1].Value }
        $runText = $runText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
        
        if ($runText -ne '') {
            $hasText = $true
            if ($runBold) {
                $lineSegments.Add("<strong>$runText</strong>")
            } else {
                $lineSegments.Add($runText)
            }
        }
        
        if ($hasBreak) { $lineSegments.Add("`n") }
    }
    
    if ($hasText) {
        $combined = ([string]::Join('', $lineSegments)).Trim()
        $parsedParas.Add(@{ text = $combined })
    }
}

Write-Host "Total paragraphs: $($parsedParas.Count)"

# ---- Group by article using number detection ----
$articleBodies = @{}
$currentArt = $null

foreach ($para in $parsedParas) {
    $text = $para.text
    # Strip HTML tags for matching
    $plain = [regex]::Replace($text, '<[^>]+>', '')
    
    # Detect article header: number 52-151 followed by colon
    if ($plain -match '(\d+[A-Za-z]?)\s*:') {
        $possibleNum = $Matches[1]
        $baseNum = [regex]::Match($possibleNum, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $currentArt = $possibleNum
            if (-not $articleBodies.ContainsKey($currentArt)) {
                $articleBodies[$currentArt] = [System.Collections.Generic.List[string]]::new()
            }
            $articleBodies[$currentArt].Add($text)
            continue
        }
    }
    
    if ($currentArt) {
        # Skip amendment footnote lines - they start with digit+dot pattern and are short
        $isNote = ($plain -match '^\d+\.\s+.{5,}') -and ($plain.Length -lt 400) -and ($plain -match '^\d+\.')
        if (-not $isNote) {
            $articleBodies[$currentArt].Add($text)
        }
    }
}

Write-Host "Articles parsed: $($articleBodies.Count)"

$hindiData = @{}
foreach ($artNum in $articleBodies.Keys) {
    $lines = $articleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $lines)
}

# Show some previews
Write-Host ""
Write-Host "=== Art 52 ==="
if ($hindiData['52']) { Write-Host $hindiData['52'].Substring(0, [Math]::Min(250, $hindiData['52'].Length)) }
Write-Host ""
Write-Host "=== Art 53 (first 250) ==="
if ($hindiData['53']) { Write-Host $hindiData['53'].Substring(0, [Math]::Min(250, $hindiData['53'].Length)) }
Write-Host ""
Write-Host "=== Art 74 (first 250) ==="
if ($hindiData['74']) { Write-Host $hindiData['74'].Substring(0, [Math]::Min(250, $hindiData['74'].Length)) }

# ---- Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Save backup
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5_v2.json'
Copy-Item $jsonPath $backupPath -Force
Write-Host "`nBackup saved: $backupPath"

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') { $part5idx = $i; break }
}
Write-Host "Part V at index: $part5idx"

$updH = 0; $noData = 0
foreach ($article in $json[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    if ($hindiData.ContainsKey($artId) -and $hindiData[$artId].Trim() -ne '') {
        $article.hindi = $hindiData[$artId]
        $updH++
    } else {
        Write-Host "  No data for: $artId"
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
$a52 = $p5v.articles | Where-Object { $_.id -eq '52' }
Write-Host "Art 52 hindi length: $(if($a52.hindi){$a52.hindi.Length}else{'EMPTY'})"

# Check other parts unchanged
$p3 = $verify | Where-Object { $_.partId -eq 'III' }
$a12 = $p3.articles | Where-Object { $_.id -eq '12' }
Write-Host "Part III Art 12 hindi length (unchanged check): $(if($a12.hindi){$a12.hindi.Length}else{0})"
