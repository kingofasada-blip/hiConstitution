# Save fix - run after update_part5 parsed the data correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5.json'

# Load backup as baseline (untouched)
$jsonRaw = [System.IO.File]::ReadAllText($backupPath, [System.Text.Encoding]::UTF8)
$json = $jsonRaw | ConvertFrom-Json

# ---- Re-parse simplified docx ----
$xmlContentSimp = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_simplified_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$simpEng = @{}
$simpHin = @{}
$currentArt = $null
$collectEng = $false
$collectHin = $false

$paraMatches = [regex]::Matches($xmlContentSimp, $paraPattern)
foreach ($para in $paraMatches) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    if ($tMatches.Count -eq 0) { continue }
    $parts = @()
    foreach ($m in $tMatches) { $parts += $m.Groups[1].Value }
    $lineText = [string]::Join('', $parts)
    $lineText = $lineText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
    $trimmed = $lineText.Trim()
    
    if ($trimmed -match '^Article (\d+[A-Za-z]?)$') {
        $currentArt = $Matches[1]
        $simpEng[$currentArt] = ''
        $simpHin[$currentArt] = ''
        $collectEng = $false; $collectHin = $false
    } elseif ($trimmed -match '^Simplified English:\s*(.*)') {
        if ($currentArt) { $simpEng[$currentArt] = $Matches[1].Trim(); $collectEng = $true; $collectHin = $false }
    } elseif ($trimmed -match '^Simplified Hindi:\s*(.*)') {
        if ($currentArt) { $simpHin[$currentArt] = $Matches[1].Trim(); $collectEng = $false; $collectHin = $true }
    } elseif ($trimmed -ne '' -and $currentArt) {
        if ($collectEng) { $simpEng[$currentArt] += ' ' + $trimmed }
        elseif ($collectHin) { $simpHin[$currentArt] += ' ' + $trimmed }
    }
}
Write-Host "Simplified parsed: $($simpEng.Count) articles"

# ---- Re-parse Hindi original docx ----
$xmlContentHindi = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_original_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$hindiArticleBodies = @{}
$currentArtH = $null

$paraMatchesH = [regex]::Matches($xmlContentHindi, $paraPattern)
foreach ($para in $paraMatchesH) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    if ($tMatches.Count -eq 0) { continue }
    $parts = @()
    foreach ($m in $tMatches) { $parts += $m.Groups[1].Value }
    $lineText = [string]::Join('', $parts)
    $lineText = $lineText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
    $trimmed = $lineText.Trim()
    if ($trimmed -eq '') { continue }

    if ($trimmed -match '(?:^\d+\[)?[^\d]*(\d+[A-Za-z]?)\s*:') {
        $possibleArtNum = $Matches[1]
        $baseNum = [regex]::Match($possibleArtNum, '^\d+').Value
        $artNumInt = 0
        if ([int]::TryParse($baseNum, [ref]$artNumInt) -and $artNumInt -ge 52 -and $artNumInt -le 151) {
            $currentArtH = $possibleArtNum
            if (-not $hindiArticleBodies.ContainsKey($currentArtH)) {
                $hindiArticleBodies[$currentArtH] = [System.Collections.Generic.List[string]]::new()
            }
            continue
        }
    }

    if ($currentArtH) {
        $isNote = $trimmed -match '^\d+\.\s+' -or $trimmed -match '^\s*\d+\s*$'
        if (-not $isNote) {
            $hindiArticleBodies[$currentArtH].Add($trimmed)
        }
    }
}

$hindiData = @{}
foreach ($artNum in $hindiArticleBodies.Keys) {
    $bodyLines = $hindiArticleBodies[$artNum] | Where-Object { $_.Trim() -ne '' }
    $hindiData[$artNum] = [string]::Join("`n", $bodyLines)
}
Write-Host "Hindi original parsed: $($hindiData.Count) articles"

# ---- Update Part V in JSON ----
$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') { $part5idx = $i; break }
}

$updH = 0; $updHS = 0; $updE = 0
foreach ($article in $json[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    
    if ($hindiData.ContainsKey($artId) -and $hindiData[$artId].Trim() -ne '') {
        $article.hindi = $hindiData[$artId]; $updH++
    }
    if ($simpHin.ContainsKey($artId) -and $simpHin[$artId].Trim() -ne '') {
        if ($article.PSObject.Properties['hindiSimplified']) {
            $article.hindiSimplified = $simpHin[$artId].Trim()
        } else {
            $article | Add-Member -MemberType NoteProperty -Name 'hindiSimplified' -Value $simpHin[$artId].Trim() -Force
        }
        $updHS++
    }
    if ($simpEng.ContainsKey($artId) -and $simpEng[$artId].Trim() -ne '') {
        $article.simplified = $simpEng[$artId].Trim(); $updE++
    }
}

Write-Host "Updated - hindi: $updH | hindiSimplified: $updHS | simplified: $updE"

# Save with UTF8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved: $jsonPath"

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $verify | Where-Object { $_.partId -eq 'V' }
$art52 = $p5.articles | Where-Object { $_.id -eq '52' }
$art53 = $p5.articles | Where-Object { $_.id -eq '53' }
Write-Host ""
Write-Host "=== Art 52 verify ==="
Write-Host "hindi: $($art52.hindi)"
Write-Host "hindiSimplified: $($art52.hindiSimplified)"
Write-Host "simplified: $($art52.simplified)"
Write-Host ""
Write-Host "=== Art 53 hindi (first 80): ==="
if ($art53.hindi) { Write-Host $art53.hindi.Substring(0,[Math]::Min(80,$art53.hindi.Length)) }
