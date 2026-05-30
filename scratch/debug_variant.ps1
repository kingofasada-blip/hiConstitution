[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$xmlContent = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_new_unzipped\word\document.xml', [System.Text.Encoding]::UTF8)
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$runPattern  = '(?s)<w:r[ >].*?</w:r>'
$tPattern    = '<w:t[^>]*>([^<]*)</w:t>'
$paragraphs  = [regex]::Matches($xmlContent, $paraPattern)

# Print all paragraphs that contain digits 124, 131, 134, 139, 144 followed by non-digit
foreach ($para in $paragraphs) {
    $runs = [regex]::Matches($para.Value, $runPattern)
    $fullText = ''
    foreach ($run in $runs) {
        foreach ($tm in ([regex]::Matches($run.Value, $tPattern))) { $fullText += $tm.Groups[1].Value }
    }
    $fullText = $fullText.Trim()
    
    if ($fullText -match '(124|131|134|139|144)[^\d\s\.]' -and $fullText.Length -gt 5) {
        Write-Host "FOUND: [$fullText]"
        # Print char codes of first 15 chars
        $chars = @()
        for ($i = 0; $i -lt [Math]::Min(20, $fullText.Length); $i++) {
            $chars += "U+$([int][char]$fullText[$i]):$($fullText[$i])"
        }
        Write-Host "CHARS: $($chars -join ' ')"
        Write-Host ""
    }
}
