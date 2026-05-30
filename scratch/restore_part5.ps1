[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$backupPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_backup_before_part5.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Load current JSON (all parts intact)
$current = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

# Load backup (has original Part V state - empty hindi/hindiSimplified)
$backup = [System.IO.File]::ReadAllText($backupPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

# Get Part V from backup
$backupP5 = $backup | Where-Object { $_.partId -eq 'V' }

# Get Part V index in current
$part5idx = -1
for ($i = 0; $i -lt $current.Count; $i++) {
    if ($current[$i].partId -eq 'V') { $part5idx = $i; break }
}

Write-Host "Part V found at index: $part5idx"
Write-Host "Backup Part V articles: $($backupP5.articles.Count)"
Write-Host "Current Part V articles: $($current[$part5idx].articles.Count)"

# For each article in current Part V, restore hindi and hindiSimplified from backup
$restoredHindi = 0
$restoredHindiSimp = 0
$removedHindiSimp = 0

foreach ($article in $current[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    
    # Find matching article in backup
    $backupArt = $backupP5.articles | Where-Object { $_.id -eq $artId }
    
    if ($backupArt) {
        # Restore hindi field
        $article.hindi = $backupArt.hindi
        $restoredHindi++
        
        # Restore/remove hindiSimplified - backup didn't have it, so remove it
        if ($article.PSObject.Properties['hindiSimplified']) {
            $article.PSObject.Properties.Remove('hindiSimplified')
            $removedHindiSimp++
        }
    }
}

Write-Host "Restored hindi: $restoredHindi articles"
Write-Host "Removed hindiSimplified: $removedHindiSimp articles"

# Also restore simplified (English) to backup values
foreach ($article in $current[$part5idx].articles) {
    $artId = $article.id.ToString().Trim()
    $backupArt = $backupP5.articles | Where-Object { $_.id -eq $artId }
    if ($backupArt -and $backupArt.simplified) {
        $article.simplified = $backupArt.simplified
    }
}

Write-Host "Simplified (english) also restored to backup values."

# Save
$jsonOut = $current | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved: $jsonPath"

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
$art52 = $p5v.articles | Where-Object { $_.id -eq '52' }
$art74 = $p5v.articles | Where-Object { $_.id -eq '74' }
Write-Host ""
Write-Host "=== Verify Art 52 ==="
Write-Host "hindi: '$($art52.hindi)'"
Write-Host "hindiSimplified exists: $($null -ne $art52.PSObject.Properties['hindiSimplified'])"
Write-Host "simplified: $($art52.simplified)"
Write-Host ""
Write-Host "=== Verify Art 74 ==="
Write-Host "hindi length: $(if($art74.hindi){$art74.hindi.Length}else{0})"
Write-Host "hindiSimplified exists: $($null -ne $art74.PSObject.Properties['hindiSimplified'])"

# Check other parts untouched
$p3 = $verify | Where-Object { $_.partId -eq 'III' }
$art12 = $p3.articles | Where-Object { $_.id -eq '12' }
Write-Host ""
Write-Host "=== Part III Art 12 (must be unchanged) ==="
Write-Host "hindi length: $(if($art12.hindi){$art12.hindi.Length}else{0})"
Write-Host "hindiSimplified exists: $($null -ne $art12.PSObject.Properties['hindiSimplified'])"
