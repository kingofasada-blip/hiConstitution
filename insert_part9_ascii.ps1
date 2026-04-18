$lines = Get-Content -Path "c:\Users\DeLL\Desktop\hiCONSTITUTION\part9_raw.txt" -Encoding UTF8
$articles = @()
$currentArticle = $null

$articlePattern = '^(\d{3}[A-Z]*)\.\s+(.+?)(?:\u2014|--|-)\s*(.*)$'
$skipPatterns = @(
    '^PART IX THE PANCHAYATS',
    '^As per your instructions',
    '^Ins\. by the Constitution'
)

function Should-SkipLine {
    param([string]$Line)

    foreach ($pattern in $skipPatterns) {
        if ($Line -match $pattern) {
            return $true
        }
    }

    return $false
}

function Format-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $formatted = $Text.Trim()
    $formatted = [regex]::Replace($formatted, '\u00B9\[', '<sup>1</sup>[')
    $formatted = [regex]::Replace($formatted, '(\d+)\[', '<sup>$1</sup>[')
    $formatted = [regex]::Replace($formatted, '(\d+)\*\*\*', '<sup>$1</sup>***')
    $formatted = [regex]::Replace($formatted, '(?<!^) (Provided that|Provided further that|Provided also that)', "`n`$1")
    $formatted = [regex]::Replace($formatted, '(?<!^)(\([0-9A-Za-z]+\))\s', "`n`$1 ")
    $formatted = [regex]::Replace($formatted, '(?<!^)(\([ivxIVX]+\))\s', "`n`$1 ")

    return $formatted
}

foreach ($rawLine in $lines) {
    if ([string]::IsNullOrWhiteSpace($rawLine)) {
        continue
    }

    $line = $rawLine.Trim()

    if (Should-SkipLine -Line $line) {
        continue
    }

    if ($line -match $articlePattern) {
        if ($null -ne $currentArticle) {
            $articles += $currentArticle
        }

        $articleId = $matches[1]
        $articleTitle = (($matches[2] -replace '\[', '') -replace '\]', '').Trim()
        $articleBody = Format-BodyText -Text $matches[3]

        $articleHeading = $articleTitle.TrimEnd('.')

        $currentArticle = [ordered]@{
            id = $articleId
            title = "Article ${articleId}: ${articleTitle}"
            preview = $articleBody
            text = "<strong>Article ${articleId}. ${articleHeading}.-</strong>"
        }

        if (-not [string]::IsNullOrWhiteSpace($articleBody)) {
            $currentArticle.text += "`n$articleBody"
        }

        continue
    }

    if ($null -eq $currentArticle) {
        continue
    }

    if ($line -match '^(Amendments?):$') {
        $lineProcessed = "<strong>$($matches[1]):</strong>"
    } else {
        $lineProcessed = Format-BodyText -Text $line
    }

    if (-not [string]::IsNullOrWhiteSpace($lineProcessed)) {
        $currentArticle.text += "`n$lineProcessed"

        if ([string]::IsNullOrWhiteSpace($currentArticle.preview)) {
            $currentArticle.preview = $lineProcessed
        }
    }
}

if ($null -ne $currentArticle) {
    $articles += $currentArticle
}

foreach ($article in $articles) {
    $preview = ($article.preview -replace "`n", ' ').Trim()
    if ($preview.Length -gt 150) {
        $preview = $preview.Substring(0, 150) + "..."
    }
    $article.preview = $preview
}

$part9 = [ordered]@{
    partId = "IX"
    partTitle = "Part IX - The Panchayats"
    partDesc = "Articles 243 to 243O detailing the constitution, composition, powers, and duration of Panchayats."
    articles = $articles
}

$jsonText = Get-Content -Path "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json" -Raw -Encoding UTF8
$schema = $jsonText | ConvertFrom-Json

$newSchema = @()
foreach ($part in $schema) {
    if ($part.partId -eq "IX") {
        continue
    }

    $newSchema += $part

    if ($part.partId -eq "VIII") {
        $newSchema += $part9
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOutput = ConvertTo-Json -InputObject $newSchema -Depth 12
[System.IO.File]::WriteAllText("c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", $jsonOutput, $utf8NoBom)

Write-Output "Part IX successfully rebuilt from part9_raw.txt."
