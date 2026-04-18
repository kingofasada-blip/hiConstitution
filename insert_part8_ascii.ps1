$zipPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\part8.zip"
$extractPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\part8_extracted"
$jsonPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json"
$xmlPath = Join-Path $extractPath "word\document.xml"

if (-not (Test-Path -LiteralPath $zipPath)) {
    throw "Part VIII zip file not found: $zipPath"
}

if (-not (Test-Path -LiteralPath $extractPath)) {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force
}

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
$articlePattern = '^(?:[^0-9]*?)?(\d{3}[A-Z]{0,2})\.\s+(.+?)(?:\u2014|--|-)\s*(.*)$'

function Convert-SuperscriptsToHtml {
    param([string]$Text)

    return [regex]::Replace(
        $Text,
        '([\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+)',
        {
            param($match)

            $digits = ""
            foreach ($char in $match.Groups[1].Value.ToCharArray()) {
                switch ([int][char]$char) {
                    8304 { $digits += '0' }
                    185  { $digits += '1' }
                    178  { $digits += '2' }
                    179  { $digits += '3' }
                    8308 { $digits += '4' }
                    8309 { $digits += '5' }
                    8310 { $digits += '6' }
                    8311 { $digits += '7' }
                    8312 { $digits += '8' }
                    8313 { $digits += '9' }
                }
            }

            return "<sup>$digits</sup>"
        }
    )
}

function Convert-SuperscriptTokenToDigits {
    param([string]$Token)

    $digits = ""
    foreach ($char in $Token.ToCharArray()) {
        switch ([int][char]$char) {
            8304 { $digits += '0' }
            185  { $digits += '1' }
            178  { $digits += '2' }
            179  { $digits += '3' }
            8308 { $digits += '4' }
            8309 { $digits += '5' }
            8310 { $digits += '6' }
            8311 { $digits += '7' }
            8312 { $digits += '8' }
            8313 { $digits += '9' }
        }
    }

    return $digits
}

function Get-AmendmentMarkersFromRaw {
    param([string]$Text)

    $markers = @()
    $matches = [regex]::Matches($Text, '([\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+)')
    foreach ($match in $matches) {
        $digits = Convert-SuperscriptTokenToDigits -Token $match.Groups[1].Value
        if (-not [string]::IsNullOrWhiteSpace($digits) -and -not ($markers -contains $digits)) {
            $markers += $digits
        }
    }

    return $markers
}

function Format-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $formatted = $Text.Trim()
    $formatted = Convert-SuperscriptsToHtml -Text $formatted
    $formatted = [regex]::Replace($formatted, '(?<!^) (Provided that|Provided further that|Provided also that)', "`n`$1")
    return $formatted
}

function New-ArticleRecord {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Body
    )

    $heading = $Title.TrimEnd('.')

    return [ordered]@{
        id = $Id
        title = "Article ${Id}: ${Title}"
        preview = $Body
        text = "<strong>Article ${Id}. ${heading}.-</strong>"
        amendmentLines = @()
        amendmentMarkers = @()
        inAmendments = $false
    }
}

function Finalize-Article {
    param($Article)

    if ($null -eq $Article) {
        return $null
    }

    $Article.preview = ($Article.preview -replace "`n", ' ').Trim()
    if ($Article.preview.Length -gt 150) {
        $Article.preview = $Article.preview.Substring(0, 150) + "..."
    }

    if ($Article.amendmentLines.Count -gt 0) {
        $markerIndex = 0
        $Article.text += "`n<strong>Amendments:</strong>"
        $visible = $Article.amendmentLines | Select-Object -First 2
        foreach ($line in $visible) {
            if ($line.Trim().StartsWith('*')) {
                $Article.text += "`n$line"
            } else {
                $prefix = ""
                if ($markerIndex -lt $Article.amendmentMarkers.Count) {
                    $prefix = "<sup>$($Article.amendmentMarkers[$markerIndex])</sup> "
                    $markerIndex++
                }
                $Article.text += "`n$prefix$line"
            }
        }

        if ($Article.amendmentLines.Count -gt 2) {
            $Article.text += "`n<details><summary>Show more... -></summary>"
            $hidden = $Article.amendmentLines | Select-Object -Skip 2
            foreach ($line in $hidden) {
                if ($line.Trim().StartsWith('*')) {
                    $Article.text += "`n$line"
                } else {
                    $prefix = ""
                    if ($markerIndex -lt $Article.amendmentMarkers.Count) {
                        $prefix = "<sup>$($Article.amendmentMarkers[$markerIndex])</sup> "
                        $markerIndex++
                    }
                    $Article.text += "`n$prefix$line"
                }
            }
            $Article.text += "`n</details>"
        }
    }

    $Article.Remove('amendmentLines')
    $Article.Remove('amendmentMarkers')
    $Article.Remove('inAmendments')
    return $Article
}

foreach ($rawLine in $lines) {
    $line = $rawLine.Trim()

    if ($line -match $articlePattern) {
        $finalized = Finalize-Article -Article $currentArticle
        if ($null -ne $finalized) {
            $articles += $finalized
        }

        $articleId = $matches[1]
        $articleTitle = (($matches[2] -replace '\[', '') -replace '\]', '').Trim()
        $articleBody = Format-BodyText -Text $matches[3]

        $currentArticle = New-ArticleRecord -Id $articleId -Title $articleTitle -Body $articleBody
        $currentArticle.amendmentMarkers += Get-AmendmentMarkersFromRaw -Text $line
        if (-not [string]::IsNullOrWhiteSpace($articleBody)) {
            $currentArticle.text += "`n$articleBody"
        }
        continue
    }

    if ($null -eq $currentArticle) {
        continue
    }

    if ($line -eq 'Amendments:') {
        $currentArticle.inAmendments = $true
        continue
    }

    $lineProcessed = Format-BodyText -Text $line
    if ([string]::IsNullOrWhiteSpace($lineProcessed)) {
        continue
    }

    if ($currentArticle.inAmendments) {
        $currentArticle.amendmentLines += $lineProcessed
        continue
    }

    foreach ($marker in (Get-AmendmentMarkersFromRaw -Text $line)) {
        if (-not ($currentArticle.amendmentMarkers -contains $marker)) {
            $currentArticle.amendmentMarkers += $marker
        }
    }

    $currentArticle.text += "`n$lineProcessed"
    if ([string]::IsNullOrWhiteSpace($currentArticle.preview)) {
        $currentArticle.preview = $lineProcessed
    }
}

$finalized = Finalize-Article -Article $currentArticle
if ($null -ne $finalized) {
    $articles += $finalized
}

$part8 = [ordered]@{
    partId = "VIII"
    partTitle = "Part VIII - The Union Territories"
    partDesc = "Articles 239 to 242 covering administration of Union Territories."
    articles = $articles
}

$jsonText = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8
$schema = $jsonText | ConvertFrom-Json

$newSchema = @()
foreach ($part in $schema) {
    if ($part.partId -eq "VIII") {
        continue
    }

    $newSchema += $part

    if ($part.partId -eq "VII") {
        $newSchema += $part8
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOutput = ConvertTo-Json -InputObject $newSchema -Depth 12
[System.IO.File]::WriteAllText($jsonPath, $jsonOutput, $utf8NoBom)

Write-Output "Part VIII successfully rebuilt from part8.zip."
