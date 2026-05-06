$jsonText = Get-Content -Raw .\data\articles.json
$part14AText = Get-Content -Raw .\scratch\part14A_only.json

# The part14AText has formatting, but it is just a JSON object.
$matches = [regex]::Matches($jsonText, '"partId"\s*:\s*"XV"')
if ($matches.Count -gt 0) {
    $index = $matches[0].Index
    # Go back to the '{' before "partId": "XV"
    $bracketIndex = $jsonText.LastIndexOf('{', $index)
    if ($bracketIndex -gt 0) {
        # Create the combined JSON
        $newJsonText = $jsonText.Substring(0, $bracketIndex) + $part14AText + ",`r`n                         " + $jsonText.Substring($bracketIndex)
        
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText(".\data\articles.json", $newJsonText, $utf8NoBom)
        Write-Output "Successfully string-inserted Part 14A."
    } else {
        Write-Output "Could not find opening bracket for Part XV."
    }
} else {
    Write-Output "Could not find Part XV."
}
