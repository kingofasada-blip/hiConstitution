# ============================================================
# parse_update_part5_hindi_new_v2.ps1
# Article headers: "58. Title—" format (bold, no "anucched" word)
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
        $parsedParas.Add(@{ text = $combined; isBold = $anyBold })
    }
}

Write-Host "Total paragraphs: $($parsedParas.Count)"

# ---- Group by article ----
# Pattern: starts with "NN." or "NNA." where N is digit 52-151
# Bold paragraphs that match: "58. Title— body" or "58. Title—"
$articleBodies = @{}
$currentArt = $null

# Regex: line starting with NUMBER followed by DOT then space (article header)
$artHeaderRegex = '^(\d+[A-Za-z]?)\.\s+'
# Also match "1[58. ..." type amended articles
$artHeaderRegex2 = '^\d+\[(\d+[A-Za-z]?)\.\s+'

foreach ($para in $parsedParas) {
    $text = $para.text
    $plain = [regex]::Replace($text, '<[^>]+>', '')  # strip tags
    $isBold = $para.isBold
    
    # Try to detect article header
    $artNum = $null
    if ($plain -match $artHeaderRegex) {
        $artNum = $Matches[1]
    } elseif ($plain -match $artHeaderRegex2) {
        $artNum = $Matches[1]
    }
    
    if ($artNum) {
        $baseNum = [regex]::Match($artNum, '^\d+').Value
        $artInt = 0
        if ([int]::TryParse($baseNum, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $currentArt = $artNum
            if (-not $articleBodies.ContainsKey($currentArt)) {
                $articleBodies[$currentArt] = [System.Collections.Generic.List[string]]::new()
            }
            $articleBodies[$currentArt].Add($text)
            continue
        }
    }
    
    if ($currentArt) {
        # Skip amendment section headers (bold lines that just say "संशोधन :")
        $plainStripped = $plain.Trim()
        # Check if it's an amendment footnote line: starts with digit+dot then short content
        $isAmendHeader = ($isBold -and $plainStripped -match '^\d+\[' -and $plainStripped.Length -lt 30)
        
        if (-not $isAmendHeader) {
            $articleBodies[$currentArt].Add($text)
        }
    }
}

Write-Host "Articles parsed: $($articleBodies.Count)"
$sortedKeys = $articleBodies.Keys | Sort-Object { [int]([regex]::Match($_, '^\d+').Value) }
Write-Host "First 10: $($sortedKeys | Select-Object -First 10)"
Write-Host "Last 5:  $($sortedKeys | Select-Object -Last 5)"

$hindiData = @{}
foreach ($artNum in $articleBodies.Keys) {
    $lines = $articleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $lines)
}

# Preview
Write-Host ""
Write-Host "=== Art 52 ==="
if ($hindiData['52']) { Write-Host $hindiData['52'].Substring(0, [Math]::Min(200, $hindiData['52'].Length)) }
Write-Host ""
Write-Host "=== Art 58 (first 200) ==="
if ($hindiData['58']) { Write-Host $hindiData['58'].Substring(0, [Math]::Min(200, $hindiData['58'].Length)) }

# ---- Update articles.json ----
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Backup
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5_v2.json'
Copy-Item $jsonPath $backupPath -Force
Write-Host "`nBackup: $backupPath"

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') { $part5idx = $i; break }
}
Write-Host "Part V at index: $part5idx, articles: $($json[$part5idx].articles.Count)"

$updH = 0; $noData = 0
foreach ($article in $json[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    if ($hindiData.ContainsKey($artId) -and $hindiData[$artId].Trim() -ne '') {
        $article.hindi = $hindiData[$artId]
        $updH++
    } else {
        Write-Host "  No data: $artId"
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
    Write-Host "Art $id hindi length: $(if($art -and $art.hindi){$art.hindi.Length}else{'EMPTY'})"
}

$p3 = $verify | Where-Object { $_.partId -eq 'III' }
$a12 = $p3.articles | Where-Object { $_.id -eq '12' }
Write-Host "Part III Art 12 (unchanged): $(if($a12.hindi){$a12.hindi.Length}else{0})"
