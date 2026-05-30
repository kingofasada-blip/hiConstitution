[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'
$paragraphs  = [regex]::Matches($xmlContent, $paraPattern)

# Look for 124, 131, 134, 139, 144 with letter suffix
$targets = @('124क', '124ख', '124ग', '131क', '134क', '139क', '144क', '124A', '131A', '134A', '139A', '144A')

foreach ($para in $paragraphs) {
    $runs = [regex]::Matches($para.Value, $runPattern)
    $fullText = ''
    foreach ($run in $runs) {
        foreach ($tm in ([regex]::Matches($run.Value, $tPattern))) { $fullText += $tm.Groups[1].Value }
    }
    $fullText = $fullText.Trim()
    
    $match = $false
    foreach ($t in $targets) {
        if ($fullText -match [regex]::Escape($t)) { $match = $true; break }
    }
    
    if ($match -and $fullText.Length -gt 5) {
        Write-Host "RAW: [$fullText]"
        Write-Host ""
    }
}
