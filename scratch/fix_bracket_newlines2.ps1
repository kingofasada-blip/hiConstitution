$jsonPath = ".\data\articles.json"
$text = Get-Content -Raw -Encoding UTF8 $jsonPath

# We match the literal string \u003csup\u003e followed by digits, then \u003c/sup\u003e, then [ or *, then literal \n
# Regex pattern needs to escape the backslashes since the json string contains literal backslashes
# So \\u003csup\\u003e\d+\\u003c/sup\\u003e(?:\[|\*)\\n
# Wait, let's also allow optional spaces after the \n, but in json it's just space.
$pattern = '(\\u003csup\\u003e\d+\\u003c/sup\\u003e(?:\[|\*))\\n\s*'
$matchesCount = [regex]::Matches($text, $pattern).Count
Write-Output "Found $matchesCount matches to fix."

$newText = [regex]::Replace($text, $pattern, '$1')

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($jsonPath, $newText, $utf8NoBom)
Write-Output "Applied fix for brackets separated by newlines."
