$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$jsonPath = Join-Path $rootPath "data\articles.json"

$englishDoc = Join-Path $rootPath "part 14A - PART XIVA TRIBUNALS (in english original).docx"
$englishSimpleDoc = Join-Path $rootPath "part 14A english simple explanation.docx"
$hindiDoc = Join-Path $rootPath "part 14A hindi original .docx"
$hindiSimpleDoc = Join-Path $rootPath "part 14A hindi saral.docx"

foreach ($requiredPath in @($englishDoc, $englishSimpleDoc, $hindiDoc, $hindiSimpleDoc)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Part XIVA source file: $requiredPath"
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$hindiArticleWord = [string]::Concat(
    [char]0x0905, [char]0x0928, [char]0x0941, [char]0x091A,
    [char]0x094D, [char]0x091B, [char]0x0947, [char]0x0926
)
$hindiAmendmentLabel = [string]::Concat(
    [char]0x0938, [char]0x0902, [char]0x0936,
    [char]0x094B, [char]0x0927, [char]0x0928, ':'
)
$hindiClauseWord = [string]::Concat(
    [char]0x0916, [char]0x0902, [char]0x0921
)
$hindiSubClauseWord = [string]::Concat(
    [char]0x0909, [char]0x092A, [char]0x0916, [char]0x0902, [char]0x0921
)
$hindiProvisoWord = [string]::Concat(
    [char]0x092A, [char]0x0930, [char]0x0902, [char]0x0924, [char]0x0941
)
$emDash = [string][char]0x2014
$enDash = [string][char]0x2013

function Get-DocLines {
    param([string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($resolved)

    try {
        $entry = $zip.GetEntry("word/document.xml")
        if ($null -eq $entry) {
            throw "word/document.xml not found in $Path"
        }

        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xmlText = $reader.ReadToEnd()
        $reader.Dispose()
    }
    finally {
        $zip.Dispose()
    }

    $paragraphs = [regex]::Matches($xmlText, '<w:p\b.*?</w:p>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $lines = @()

    foreach ($paragraph in $paragraphs) {
        $textRuns = [regex]::Matches($paragraph.Value, '<w:t[^>]*>(.*?)</w:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($textRuns.Count -eq 0) {
            continue
        }

        $line = ""
        foreach ($textRun in $textRuns) {
            $line += [System.Net.WebUtility]::HtmlDecode($textRun.Groups[1].Value)
        }

        $line = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $lines += $line
        }
    }

    return $lines
}

function Convert-SuperscriptsToHtml {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $map = @{
        ([char]8304) = '0'
        ([char]185)  = '1'
        ([char]178)  = '2'
        ([char]179)  = '3'
        ([char]8308) = '4'
        ([char]8309) = '5'
        ([char]8310) = '6'
        ([char]8311) = '7'
        ([char]8312) = '8'
        ([char]8313) = '9'
    }

    return [regex]::Replace(
        $Text,
        '([\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+)',
        {
            param($match)

            $digits = ""
            foreach ($char in $match.Groups[1].Value.ToCharArray()) {
                if ($map.ContainsKey($char)) {
                    $digits += $map[$char]
                }
            }

            if ([string]::IsNullOrWhiteSpace($digits)) {
                return $match.Value
            }

            return "<sup>$digits</sup>"
        }
    )
}

function Normalize-ArticleId {
    param(
        [string]$Digits,
        [string]$Suffix
    )

    $normalizedSuffix = ($Suffix -replace '\u0915', 'A' -replace '\u0916', 'B' -replace '\u0917', 'C' -replace '\u0918', 'D').ToUpperInvariant()
    return "$Digits$normalizedSuffix"
}

function Normalize-SourceLine {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $normalized = $Text.Trim()
    $normalized = $normalized -replace '^\uFEFF', ''
    $normalized = $normalized -replace '^\*\*', ''
    $normalized = $normalized -replace '\*\*', ''
    return $normalized.Trim()
}

function Clean-TitleText {
    param([string]$Text)

    $clean = Normalize-SourceLine -Text $Text
    $clean = $clean.Trim()
    $clean = $clean -replace '^\[+', ''
    $clean = $clean -replace '\]+$', ''
    $clean = $clean.Trim()
    $clean = $clean -replace "[\.\]$([regex]::Escape($emDash))$([regex]::Escape($enDash))]+$", ''
    return $clean
}

function Clean-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = Normalize-SourceLine -Text $Text
    $clean = Convert-SuperscriptsToHtml -Text $clean
    $clean = $clean -replace ':\.', ':'
    $clean = $clean -replace '\]\.?$', ']'
    $clean = $clean -replace '(?<!^)(\([0-9A-Za-z]+\))\s', "`n`$1 "
    $clean = $clean -replace '(?<!^)(\([\u0915-\u0939]\))\s', "`n`$1 "
    $clean = $clean -replace '(?<!^)(Provided that|Provided further that|Provided also that)\b', "`n`$1"
    $clean = $clean -replace "(?<!^)($([regex]::Escape($hindiProvisoWord)))\b", "`n`$1"
    return $clean.Trim()
}

function Normalize-ClauseReferenceBreaks {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $normalized = $Text
    $patterns = @(
        '(?im)\b(clause|sub-clause|clauses|sub-clauses|proviso|provisos|article|articles|part|parts)\s*\r?\n\s*(\([0-9A-Za-z]+\))',
        "(?im)($([regex]::Escape($hindiArticleWord))|$([regex]::Escape($hindiClauseWord))|$([regex]::Escape($hindiSubClauseWord))|$([regex]::Escape($hindiProvisoWord)))\s*\r?\n\s*(\([^)]+\))",
        '(?im)(<sup>\d+</sup>\[)\s*(\([0-9A-Za-z]+\))'
    )

    foreach ($pattern in $patterns) {
        $normalized = [regex]::Replace($normalized, $pattern, '$1 $2')
    }

    return $normalized
}

function New-OriginalArticle {
    param(
        [string]$Id,
        [string]$Title,
        [string]$HeadingPrefix,
        [string]$OpeningPrefixHtml
    )

    return [ordered]@{
        id = $Id
        titleText = $Title
        text = "<strong>$OpeningPrefixHtml$HeadingPrefix $Id. $Title.-</strong>"
        amendmentLabel = ""
        amendmentLines = @()
        inAmendments = $false
        referenceNumbers = New-Object System.Collections.ArrayList
    }
}

function Add-ReferenceNumbers {
    param(
        $Article,
        [string]$RawText
    )

    if ($null -eq $Article -or [string]::IsNullOrWhiteSpace($RawText)) {
        return
    }

    $numberMap = @{
        ([char]8304) = '0'
        ([char]185)  = '1'
        ([char]178)  = '2'
        ([char]179)  = '3'
        ([char]8308) = '4'
        ([char]8309) = '5'
        ([char]8310) = '6'
        ([char]8311) = '7'
        ([char]8312) = '8'
        ([char]8313) = '9'
    }

    $matches = [regex]::Matches($RawText, '[\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+')
    foreach ($match in $matches) {
        $digits = ""
        foreach ($char in $match.Value.ToCharArray()) {
            if ($numberMap.ContainsKey($char)) {
                $digits += $numberMap[$char]
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($digits) -and -not $Article.referenceNumbers.Contains($digits)) {
            [void]$Article.referenceNumbers.Add($digits)
        }
    }
}

function Finalize-OriginalArticle {
    param($Article)

    if ($null -eq $Article) {
        return $null
    }

    if ($Article.amendmentLines.Count -gt 0) {
        $Article.text += "`n<strong>$($Article.amendmentLabel)</strong>"
        for ($i = 0; $i -lt $Article.amendmentLines.Count; $i++) {
            $line = Normalize-ClauseReferenceBreaks -Text $Article.amendmentLines[$i]
            if ($i -lt $Article.referenceNumbers.Count) {
                $line = "<sup>$($Article.referenceNumbers[$i])</sup> $line"
            }
            $Article.text += "`n$line"
        }
    }

    $Article.text = Normalize-ClauseReferenceBreaks -Text $Article.text
    $Article.Remove('amendmentLabel')
    $Article.Remove('amendmentLines')
    $Article.Remove('inAmendments')
    $Article.Remove('referenceNumbers')
    return $Article
}

function Parse-OriginalDoc {
    param(
        [string]$Path,
        [string]$HeadingPrefix,
        [string]$AmendmentLabel
    )

    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $current = $null
    $articlePattern = "^(?:[\d\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+\[?)?\[?(\d{3})([A-Za-z\u0915-\u0918]*)\.\s*(.+?)(?:\s*[$([regex]::Escape($emDash))$([regex]::Escape($enDash))]\s*)(.*)$"

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine

        if ($line -match $articlePattern) {
            $final = Finalize-OriginalArticle -Article $current
            if ($null -ne $final) {
                $articles[$final.id] = $final
            }

            $articleId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $articleTitle = Clean-TitleText -Text $matches[3]
            $articleBody = Clean-BodyText -Text $matches[4]
            $openingPrefixRaw = ([regex]::Match($line, '^(.*?)(?=\d{3}[A-Za-z\u0915-\u0918]*\.)')).Groups[1].Value
            $openingPrefixHtml = Convert-SuperscriptsToHtml -Text $openingPrefixRaw

            $current = New-OriginalArticle -Id $articleId -Title $articleTitle -HeadingPrefix $HeadingPrefix -OpeningPrefixHtml $openingPrefixHtml
            $current.amendmentLabel = $AmendmentLabel
            Add-ReferenceNumbers -Article $current -RawText $line

            if (-not [string]::IsNullOrWhiteSpace($articleBody)) {
                $current.text += "`n$articleBody"
            }
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match "^(Amendments:|$([regex]::Escape($hindiAmendmentLabel)))$") {
            $current.inAmendments = $true
            continue
        }

        $lineProcessed = Clean-BodyText -Text $line
        if ([string]::IsNullOrWhiteSpace($lineProcessed)) {
            continue
        }

        if ($current.inAmendments) {
            $current.amendmentLines += $lineProcessed
        }
        else {
            Add-ReferenceNumbers -Article $current -RawText $line
            $current.text += "`n$lineProcessed"
        }
    }

    $final = Finalize-OriginalArticle -Article $current
    if ($null -ne $final) {
        $articles[$final.id] = $final
    }

    return $articles
}

function Get-HeadingKey {
    param([string]$Text)

    $key = (Normalize-SourceLine -Text $Text).ToLowerInvariant()
    $key = $key -replace '^[^a-z0-9\u0900-\u097F]+', ''
    $key = $key -replace '[^a-z0-9\u0900-\u097F]+', ''
    return $key
}

function Parse-EnglishSimplifiedDoc {
    param([string]$Path)

    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    
    $currentId = $null
    $buffer = @()
    
    $pattern = "^Article\s+(\d{3}[A-Za-z]?)(?:\s*\([^)]+\))?:\s*(.*)$"

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        
        if ($line -match $pattern) {
            if ($null -ne $currentId) {
                $articles[$currentId] = ($buffer -join "`n").Trim()
            }
            $currentId = $matches[1].ToUpperInvariant()
            $buffer = @()
            $text = $matches[2].Trim()
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $buffer += $text
            }
            continue
        }
        elseif ($line -match "^CHAPTER") {
            continue
        }
        
        if ($null -ne $currentId) {
            $buffer += $line
        }
    }

    if ($null -ne $currentId) {
        $articles[$currentId] = ($buffer -join "`n").Trim()
    }

    return $articles
}

function Parse-HindiSimplifiedDoc {
    param([string]$Path)

    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $hindiArticleWord = [string]::Concat([char]0x0905, [char]0x0928, [char]0x0941, [char]0x091A, [char]0x094D, [char]0x091B, [char]0x0947, [char]0x0926)

    $pattern = "^(?:$([regex]::Escape($hindiArticleWord))\s*)?(\d{3})([A-Za-z\u0915-\u0918]*)\s*:\s*(.*)$"

    $currentId = $null
    $buffer = @()

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        
        if ($line -match $pattern) {
            if ($null -ne $currentId) {
                $articles[$currentId] = ($buffer -join "`n").Trim()
            }
            $articleId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $currentId = $articleId
            $buffer = @()
            $text = $matches[3].Trim()
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $buffer += $text
            }
            continue
        }
        
        if ($null -ne $currentId) {
            $buffer += $line
        }
    }

    if ($null -ne $currentId) {
        $articles[$currentId] = ($buffer -join "`n").Trim()
    }

    return $articles
}

function Get-PreviewText {
    param(
        [string]$SimplifiedText,
        [string]$OriginalText
    )

    $source = $SimplifiedText
    if ([string]::IsNullOrWhiteSpace($source)) {
        $source = $OriginalText
    }

    $preview = ($source -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
    if ($preview.Length -gt 180) {
        $preview = $preview.Substring(0, 180) + "..."
    }

    return $preview
}

$englishOriginal = Parse-OriginalDoc -Path $englishDoc -HeadingPrefix "Article" -AmendmentLabel "Amendments:"
$hindiOriginal = Parse-OriginalDoc -Path $hindiDoc -HeadingPrefix $hindiArticleWord -AmendmentLabel $hindiAmendmentLabel
$orderedEnglishArticles = @($englishOriginal.GetEnumerator() | ForEach-Object { $_.Value })
$englishSimplified = Parse-EnglishSimplifiedDoc -Path $englishSimpleDoc
$hindiSimplified = Parse-HindiSimplifiedDoc -Path $hindiSimpleDoc

$orderedIds = @($englishOriginal.Keys)
$partArticles = @()

foreach ($id in $orderedIds) {
    $enRecord = $englishOriginal[$id]
    $partArticles += [ordered]@{
        id = $id
        title = "Article ${id}: $($enRecord.titleText)"
        preview = Get-PreviewText -SimplifiedText $englishSimplified[$id] -OriginalText $enRecord.text
        text = $enRecord.text
        simplified = if ($englishSimplified.Contains($id)) { $englishSimplified[$id] } else { "" }
        hindi = if ($hindiOriginal.Contains($id)) { $hindiOriginal[$id].text } else { "" }
        hindiSimplified = if ($hindiSimplified.Contains($id)) { $hindiSimplified[$id] } else { "" }
    }
}

$partXIVA = [ordered]@{
    partId = "XIVA"
    partTitle = "Part XIVA - Tribunals"
    partDesc = "Articles 323A to 323B, dealing with administrative and other tribunals."
    articles = $partArticles
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($json -isnot [System.Array] -and $json.PSObject.Properties.Name -contains 'value') {
    $json = $json.value
}
$json = @($json)
$updated = @()
$inserted = $false

foreach ($part in $json) {
    if ($part.partId -eq "XIVA") {
        $updated += $partXIVA
        $inserted = $true
    }
    else {
        $updated += $part
        # Assuming Part XIV is the preceding part
        if ($part.partId -eq "XIV" -and -not $inserted) {
            $updated += $partXIVA
            $inserted = $true
        }
    }
}

if (-not $inserted) {
    $updated += $partXIVA
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $updated -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Part XIVA rebuilt and inserted from the four docx sources."
