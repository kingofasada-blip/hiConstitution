[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

Write-Host "Total parts: $($json.Count)"
$p5 = $json | Where-Object { $_.partId -eq 'V' }
Write-Host "Part V articles: $($p5.articles.Count)"

# Check a variety of articles
$testIds = @('52', '74', '100', '124A', '131A', '134A', '139A', '144A', '151')
foreach ($id in $testIds) {
    $art = $p5.articles | Where-Object { $_.id -eq $id }
    if ($art) {
        $hindiLen = if ($art.hindi) { $art.hindi.Length } else { 0 }
        $hindiSimpLen = if ($art.hindiSimplified) { $art.hindiSimplified.Length } else { 0 }
        $simpLen = if ($art.simplified) { $art.simplified.Length } else { 0 }
        Write-Host "Art $id - hindi:$hindiLen hindiSimp:$hindiSimpLen engSimp:$simpLen"
    } else {
        Write-Host "Art $id - NOT FOUND"
    }
}

# Check other parts are NOT touched (Part III, IV)
$p3 = $json | Where-Object { $_.partId -eq 'III' }
$art12 = $p3.articles | Where-Object { $_.id -eq '12' }
Write-Host ""
Write-Host "=== Part III Art 12 check (should be unchanged) ==="
Write-Host "hindi length: $(if($art12.hindi){$art12.hindi.Length}else{0})"
Write-Host "hindiSimplified length: $(if($art12.hindiSimplified){$art12.hindiSimplified.Length}else{0})"

$p4 = $json | Where-Object { $_.partId -eq 'IV' }
$art36 = $p4.articles | Where-Object { $_.id -eq '36' }
Write-Host ""
Write-Host "=== Part IV Art 36 check (should be unchanged) ==="
Write-Host "hindi length: $(if($art36.hindi){$art36.hindi.Length}else{0})"
Write-Host "hindiSimplified length: $(if($art36.hindiSimplified){$art36.hindiSimplified.Length}else{0})"

Write-Host ""
Write-Host "JSON file size: $((Get-Item $jsonPath).Length) bytes"
