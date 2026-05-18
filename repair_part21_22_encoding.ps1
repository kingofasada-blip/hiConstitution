$jsonPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json"

function Test-LooksLikeMojibake {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    foreach ($code in @(194, 195, 224, 226)) {
        if ($Text.IndexOf([char]$code) -ge 0) {
            return $true
        }
    }

    return $false
}

function Repair-MojibakeText {
    param([string]$Text)

    if (-not (Test-LooksLikeMojibake -Text $Text)) {
        return $Text
    }

    $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($Text)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($json -isnot [System.Array] -and ($json.PSObject.Properties.Name -contains "value")) {
    $json = $json.value
}

foreach ($part in $json) {
    if ($part.partId -in @("XXI", "XXII")) {
        $part.partTitle = Repair-MojibakeText -Text $part.partTitle
        $part.partDesc = Repair-MojibakeText -Text $part.partDesc

        foreach ($article in $part.articles) {
            foreach ($field in @("title", "preview", "text", "simplified", "hindi", "hindiSimplified")) {
                $value = $article.$field
                if ($value -is [string]) {
                    $article.$field = Repair-MojibakeText -Text $value
                }
            }
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json @($json) -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Encoding repaired for Part XXI and Part XXII."
