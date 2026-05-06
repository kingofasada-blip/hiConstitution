$jsonPath = ".\data\articles.json"
$part14APath = ".\scratch\part14A_only.json"

# Read main array
$content = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
if ($content.value) { $array = @($content.value) } else { $array = @($content) }

# Read Part 14A
$part14A = Get-Content -Raw -Encoding UTF8 $part14APath | ConvertFrom-Json

# Apply superscripts to Part 14A
$targetArticles14A = @('323A', '323B')
foreach ($article in $part14A.articles) {
    if ($article.id -in $targetArticles14A) {
        $article.text = [regex]::Replace($article.text, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
        $article.hindi = [regex]::Replace($article.hindi, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
        $article.preview = [regex]::Replace($article.preview, '(?<!\d)(\d+)(?=\[|\*)', '<sup>$1</sup>')
    }
}

# Insert Part 14A right after Part XIV
$newArray = @()
foreach ($part in $array) {
    if ($part -eq $null) { continue }
    $newArray += $part
    if ($part.partId -eq 'XIV') {
        $newArray += $part14A
    }
}

# Ensure it doesn't wrap with value by manual string manipulation of ConvertTo-Json output if needed
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $newArray -Depth 16

# Remove {"value": wrapper if present
if ($jsonOut -match '^\s*\{\s*"value"\s*:\s*(\[[\s\S]*\])\s*\}\s*$') {
    $jsonOut = $matches[1]
}

[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Output "Successfully safely inserted Part 14A!"
