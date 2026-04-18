$docxPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\part 9B original eng.docx"
$zipPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\part9b.zip"
$extractPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\part9b_extracted_docx"
$jsonPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json"

if (-not (Test-Path -LiteralPath $docxPath)) {
    throw "Part IXB docx file not found: $docxPath"
}

Copy-Item -LiteralPath $docxPath -Destination $zipPath -Force

if (Test-Path -LiteralPath $extractPath) {
    Remove-Item -LiteralPath $extractPath -Recurse -Force
}

Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

$xmlPath = Join-Path $extractPath "word\document.xml"
$xmlText = Get-Content -LiteralPath $xmlPath -Raw -Encoding UTF8

$paragraphMatches = [regex]::Matches($xmlText, '<w:p\b.*?</w:p>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
$lines = @()

foreach ($paragraphMatch in $paragraphMatches) {
    $textMatches = [regex]::Matches($paragraphMatch.Value, '<w:t[^>]*>(.*?)</w:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($textMatches.Count -eq 0) {
        continue
    }

    $line = ""
    foreach ($textMatch in $textMatches) {
        $line += [System.Net.WebUtility]::HtmlDecode($textMatch.Groups[1].Value)
    }

    $line = $line.Trim()
    if (-not [string]::IsNullOrWhiteSpace($line)) {
        $lines += $line
    }
}

$articles = @()
$currentArticle = $null
$articlePattern = '^(\d{3}[A-Z]{1,2})\s*\.\s+(.+?)(?:\u2014|--|-)\s*(.*)$'
$skipPatterns = @(
    '^As per your instructions',
    '^PART IXB\b',
    '^THE CO-OPERATIVE SOCIETIES\b'
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

    $lineProcessed = Format-BodyText -Text $line
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

$part9B = [ordered]@{
    partId = "IXB"
    partTitle = "Part IXB - The Co-operative Societies"
    partDesc = "Articles 243ZH to 243ZT dealing with co-operative societies."
    articles = $articles
}

$jsonText = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8
$schema = $jsonText | ConvertFrom-Json

$newSchema = @()
foreach ($part in $schema) {
    if ($part.partId -eq "IXB") {
        continue
    }

    $newSchema += $part

    if ($part.partId -eq "IXA") {
        $newSchema += $part9B
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOutput = ConvertTo-Json -InputObject $newSchema -Depth 12
[System.IO.File]::WriteAllText($jsonPath, $jsonOutput, $utf8NoBom)

Write-Output "Part IXB successfully rebuilt from the docx source."
