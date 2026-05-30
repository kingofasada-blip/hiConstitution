# Extract text from docx XML using regex approach
$xmlContent = Get-Content 'c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_simplified_unzipped\word\document.xml' -Encoding UTF8 -Raw

# Extract all w:t content using regex
$matches = [regex]::Matches($xmlContent, '<w:t[^>]*>([^<]*)</w:t>')
$texts = $matches | ForEach-Object { $_.Groups[1].Value }

# Now get paragraphs - split by </w:p>
$paraMatches = [regex]::Matches($xmlContent, '<w:p[ >].*?</w:p>')

$lines = @()
foreach ($para in $paraMatches) {
    $tMatches = [regex]::Matches($para.Value, '<w:t[^>]*>([^<]*)</w:t>')
    $lineText = ($tMatches | ForEach-Object { $_.Groups[1].Value }) -join ''
    $lines += $lineText
}

Write-Host "Lines count: $($lines.Count)"
$lines | Out-File 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\part5_simplified_text.txt' -Encoding UTF8
Write-Host "=== First 80 lines ==="
for ($i = 0; $i -lt [Math]::Min(80, $lines.Count); $i++) {
    Write-Host "$($i): $($lines[$i])"
}
