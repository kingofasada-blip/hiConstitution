[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'
$paragraphs  = [regex]::Matches($xmlContent, $paraPattern)

# ka=U+0915, kha=U+0916, ga=U+0917 (standard Devanagari)
# But debug showed U+2325=क, U+2326=ख ?
# Actually U+0915=क, U+0916=ख, U+0917=ग in standard Unicode
# U+2325 is "HELM SYMBOL" - that can't be right
# Let me re-examine... 

# From debug output:
# 134क: CHARS: U+185:¹ U+91:[ U+49:1 U+51:3 U+52:4 U+2325:क
# U+2325 is DEVANAGARI LETTER KA in hex = 0x2325 = decimal 9,013
# But standard Devanagari KA is U+0915 = decimal 2,325
# So decimal 2325 = U+0915 = क !!!
# The debug was showing DECIMAL not HEX!

Write-Host "Decimal 2325 = hex $('{0:X4}' -f 2325) = char $([char]2325)"
Write-Host "Decimal 2326 = hex $('{0:X4}' -f 2326) = char $([char]2326)"
Write-Host "Decimal 2327 = hex $('{0:X4}' -f 2327) = char $([char]2327)"

# So: [char]2325 = क, [char]2326 = ख, [char]2327 = ग
$ka = [char]2325  # क
$kha = [char]2326 # ख
$ga = [char]2327  # ग

Write-Host "ka=$ka kha=$kha ga=$ga"

# Now find articles
foreach ($para in $paragraphs) {
    $runs = [regex]::Matches($para.Value, $runPattern)
    $fullText = ''
    foreach ($run in $runs) {
        foreach ($tm in ([regex]::Matches($run.Value, $tPattern))) { $fullText += $tm.Groups[1].Value }
    }
    $fullText = $fullText.Trim()
    
    # Check for variant article patterns: digits + (ka|kha|ga) + dot
    $hasKa = $fullText -match "(\d+)$ka\."
    $hasKha = $fullText -match "(\d+)$kha\."
    $hasGa = $fullText -match "(\d+)$ga\."
    
    if (($hasKa -or $hasKha -or $hasGa) -and $fullText.Length -gt 10) {
        # Only show if it looks like an article header (number 52-151)
        $num = if ($hasKa) { [regex]::Match($fullText, "(\d+)$ka\.").Groups[1].Value }
               elseif ($hasKha) { [regex]::Match($fullText, "(\d+)$kha\.").Groups[1].Value }
               else { [regex]::Match($fullText, "(\d+)$ga\.").Groups[1].Value }
        
        $artInt = 0
        if ([int]::TryParse($num, [ref]$artInt) -and $artInt -ge 52 -and $artInt -le 151) {
            $suffix = if ($hasKa) { 'A' } elseif ($hasKha) { 'B' } else { 'C' }
            Write-Host "=== Art $num$suffix ==="
            Write-Host $fullText.Substring(0, [Math]::Min(200, $fullText.Length))
            Write-Host ""
        }
    }
}
