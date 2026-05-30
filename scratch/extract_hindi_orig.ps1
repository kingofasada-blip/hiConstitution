# Extract text from Hindi original docx
$xmlContent = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_hindi_original_unzipped\word\document.xml' -Encoding UTF8 -Raw

# Get paragraphs - split by </w:p>
$paraPattern = '(?s)<w:p[ >].*?</w:p>'
$paraMatches = [regex]::Matches($xmlContent, $paraPattern)

$lines = @()
foreach ($para in $paraMatches) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    $lineText = ($tMatches | ForEach-Object { $_.Groups[1].Value }) -join ''
    # Decode &amp; &quot; etc
    $lineText = $lineText -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>'
    $lines += $lineText
}

Write-Host "Hindi original lines: $($lines.Count)"
$lines | Out-File 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\part5_hindi_original_text.txt' -Encoding UTF8
Write-Host "=== First 50 non-empty lines ==="
$count = 0
for ($i = 0; $i -lt $lines.Count -and $count -lt 50; $i++) {
    if ($lines[$i].Trim() -ne '') {
        Write-Host "$($i): $($lines[$i].Substring(0, [Math]::Min(120, $lines[$i].Length)))"
        $count++
    }
}
