[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)

$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'

$paragraphs = [regex]::Matches($xmlContent, $paraPattern)

Write-Host "=== Looking for articles 103, 124A-C, 131A, 134A, 139A, 144A, 150 ==="
Write-Host ""

$targetArts = @('103', '124', '131', '134', '139', '144', '150')

foreach ($para in $paragraphs) {
    $runs = [regex]::Matches($para.Value, $runPattern)
    $fullText = ''
    foreach ($run in $runs) {
        $tMatches = [regex]::Matches($run.Value, $tPattern)
        foreach ($tm in $tMatches) { $fullText += $tm.Groups[1].Value }
    }
    $fullText = $fullText.Trim()
    
    foreach ($t in $targetArts) {
        if ($fullText -match $t) {
            Write-Host ">>> [$($fullText.Substring(0, [Math]::Min(200, $fullText.Length)))]"
            break
        }
    }
}
