$jsonPath = ".\data\articles.json"
$text = Get-Content -Raw -Encoding UTF8 $jsonPath

# Regex to find 1[ or 2* and replace with <sup>1</sup>[ etc.
# We'll specifically target the block for 323A and 323B to avoid messing up other parts by accident.
$startIndex = $text.IndexOf('"partId":  "XIVA"')
$endIndex = $text.IndexOf('"partId":  "XV"')

if ($startIndex -gt 0 -and $endIndex -gt $startIndex) {
    $part14AText = $text.Substring($startIndex, $endIndex - $startIndex)
    
    # Replace digits followed by [ or *
    $part14AText = [regex]::Replace($part14AText, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
    
    $newText = $text.Substring(0, $startIndex) + $part14AText + $text.Substring($endIndex)
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($jsonPath, $newText, $utf8NoBom)
    Write-Output "Applied superscripts to Part 14A safely."
} else {
    Write-Output "Could not find Part XIVA bounds."
}
