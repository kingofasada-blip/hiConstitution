[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)

$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'

$paragraphs = [regex]::Matches($xmlContent, $paraPattern)

Write-Host "Total paragraphs: $($paragraphs.Count)"
Write-Host ""
Write-Host "=== First 60 non-empty paragraphs with bold info ==="

$count = 0
foreach ($para in $paragraphs) {
    $paraXml = $para.Value
    $runs = [regex]::Matches($paraXml, $runPattern)
    
    $fullText = ''
    $hasBold = $false
    
    foreach ($run in $runs) {
        $rPrMatch = [regex]::Match($run.Value, '(?s)<w:rPr>(.*?)</w:rPr>')
        if ($rPrMatch.Success -and ($rPrMatch.Value -match '<w:b[/ >]|<w:b>')) { $hasBold = $true }
        
        $tMatches = [regex]::Matches($run.Value, $tPattern)
        foreach ($tm in $tMatches) { $fullText += $tm.Groups[1].Value }
    }
    
    $fullText = $fullText.Trim()
    if ($fullText -ne '') {
        $boldMark = if ($hasBold) { '[B]' } else { '   ' }
        Write-Host "$boldMark $($fullText.Substring(0, [Math]::Min(120, $fullText.Length)))"
        $count++
        if ($count -ge 60) { break }
    }
}
