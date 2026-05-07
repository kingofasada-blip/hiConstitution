$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$jsonPath = Join-Path $rootPath "data\articles.json"

$part16Docs = Get-ChildItem -LiteralPath $rootPath -File | Where-Object { $_.Name -like 'part 16*.docx' }
$englishDoc = ($part16Docs | Where-Object Name -eq 'part 16 english original.docx' | Select-Object -First 1).FullName
$englishSimpleDoc = ($part16Docs | Where-Object Name -eq 'part 16 english simple  .docx' | Select-Object -First 1).FullName
$hindiDoc = ($part16Docs | Where-Object { $_.Name -notlike '*english*' -and $_.Name -like '*original.docx' } | Select-Object -First 1).FullName
$hindiSimpleDoc = ($part16Docs | Where-Object { $_.Name -notlike '*english*' -and $_.Name -ne [System.IO.Path]::GetFileName($hindiDoc) } | Select-Object -First 1).FullName

foreach ($requiredPath in @($englishDoc, $englishSimpleDoc, $hindiDoc, $hindiSimpleDoc)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Part 16 source file: $requiredPath"
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

function Convert-DigitsToSuperscriptText {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    $map = @{
        '0' = [char]8304
        '1' = [char]185
        '2' = [char]178
        '3' = [char]179
        '4' = [char]8308
        '5' = [char]8309
        '6' = [char]8310
        '7' = [char]8311
        '8' = [char]8312
        '9' = [char]8313
    }

    $converted = ""
    foreach ($char in $Text.ToCharArray()) {
        $key = [string]$char
        if ($map.ContainsKey($key)) {
            $converted += $map[$key]
        }
        else {
            $converted += $char
        }
    }

    return $converted
}

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
        $runs = [regex]::Matches($paragraph.Value, '<w:r\b.*?</w:r>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($runs.Count -eq 0) {
            continue
        }

        $line = ""
        foreach ($run in $runs) {
            $textRuns = [regex]::Matches($run.Value, '<w:t[^>]*>(.*?)</w:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($textRuns.Count -eq 0) {
                continue
            }

            $runText = ""
            foreach ($textRun in $textRuns) {
                $runText += [System.Net.WebUtility]::HtmlDecode($textRun.Groups[1].Value)
            }

            if ($run.Value -match '<w:vertAlign\b[^>]*w:val="superscript"') {
                $runText = Convert-DigitsToSuperscriptText -Text $runText
            }

            $line += $runText
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

function Convert-ReferenceMarkersToHtml {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    return [regex]::Replace(
        $Text,
        '(?<!\d)(\d+)(?=(?:\[|\*+))',
        {
            param($match)
            return "<sup>$($match.Groups[1].Value)</sup>"
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
    $clean = $clean -replace "[\.\]\-$([regex]::Escape($emDash))$([regex]::Escape($enDash))]+$", ''
    return $clean
}

function Clean-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = Normalize-SourceLine -Text $Text
    $clean = Convert-SuperscriptsToHtml -Text $clean
    $clean = Convert-ReferenceMarkersToHtml -Text $clean
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

function Split-HeadingAndBody {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @{
            Title = ""
            Body = ""
        }
    }

    $emIndex = $Text.IndexOf($emDash)
    if ($emIndex -gt -1) {
        return @{
            Title = $Text.Substring(0, $emIndex).Trim()
            Body = $Text.Substring($emIndex + $emDash.Length).Trim()
        }
    }

    $enIndex = $Text.IndexOf($enDash)
    if ($enIndex -gt -1) {
        return @{
            Title = $Text.Substring(0, $enIndex).Trim()
            Body = $Text.Substring($enIndex + $enDash.Length).Trim()
        }
    }

    $dashMatch = [regex]::Match($Text, '^(.*?)(?:\.-\s*|\s-\s*)(.*)$')
    if ($dashMatch.Success) {
        return @{
            Title = $dashMatch.Groups[1].Value.Trim()
            Body = $dashMatch.Groups[2].Value.Trim()
        }
    }

    return @{
        Title = $Text.Trim()
        Body = ""
    }
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
        text = "<strong>$HeadingPrefix $Id. $OpeningPrefixHtml$Title.-</strong>"
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

    $plainMatches = [regex]::Matches($RawText, '(?<!\d)(\d+)(?=(?:\[|\*+))')
    foreach ($match in $plainMatches) {
        $digits = $match.Groups[1].Value
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
    $Article.text = $Article.text -replace '(<sup>\d+</sup>\[)\s+', '$1'
    $Article.text = $Article.text -replace '(<sup>\d+</sup>\[)\s+\(', '$1('
    $Article.text = $Article.text -replace '^<strong>(.+?\s+\d+[A-Z]?\.)\s+<sup>(\d+)</sup>\[', '<strong><sup>$2</sup>[$1 '
    $Article.text = $Article.text -replace '^<strong>.*?(Article|अनुच्छेद)\s+', '<strong>$1 '
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
    $articlePattern = '^(.*?)(\d{3})([A-Za-z\u0915-\u0918]*)\.\s*(.*)$'

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine

        if ($line -match $articlePattern) {
            $final = Finalize-OriginalArticle -Article $current
            if ($null -ne $final) {
                $articles[$final.id] = $final
            }

            $openingPrefixRaw = $matches[1]
            $articleId = Normalize-ArticleId -Digits $matches[2] -Suffix $matches[3]
            $headingParts = Split-HeadingAndBody -Text $matches[4]
            $articleTitle = Clean-TitleText -Text $headingParts.Title
            $articleBody = Clean-BodyText -Text $headingParts.Body
            $openingPrefixHtml = Convert-ReferenceMarkersToHtml -Text (Convert-SuperscriptsToHtml -Text $openingPrefixRaw)

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
    $preview = $preview -replace '^.*?(Article|अनुच्छेद)\s+', '$1 '
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
    $englishText = $enRecord.text
    if ($id -match '[A-Z]$' -and $englishText -notmatch '^<strong><sup>\d+</sup>\[') {
        $englishText = $englishText -replace '^<strong>Article\s+([0-9]+[A-Z]?)\.\s+', '<strong><sup>1</sup>[Article $1. '
    }
    $hindiText = if ($hindiOriginal.Contains($id)) { $hindiOriginal[$id].text -replace '^<strong>.*?(अनुच्छेद\s+\d+[A-Z]?\.)', '<strong>$1' } else { "" }
    $partArticles += [ordered]@{
        id = $id
        title = "Article ${id}: $($enRecord.titleText)"
        preview = Get-PreviewText -SimplifiedText $englishSimplified[$id] -OriginalText $englishText
        text = $englishText
        simplified = if ($englishSimplified.Contains($id)) { $englishSimplified[$id] } else { "" }
        hindi = $hindiText
        hindiSimplified = if ($hindiSimplified.Contains($id)) { $hindiSimplified[$id] } else { "" }
    }
}

$partXVI = [ordered]@{
    partId = "XVI"
    partTitle = "Part XVI - Special Provisions Relating to Certain Classes"
    partDesc = "Articles 330 to 342A, dealing with representation, reservations, and special provisions for Scheduled Castes, Scheduled Tribes, backward classes, and Anglo-Indians."
    articles = $partArticles
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($json -isnot [System.Array] -and $json.PSObject.Properties.Name -contains 'value') {
    $json = $json.value
}
$json = @($json)
$updated = @()
$inserted = $false
$hasExistingPartXVI = @($json | Where-Object { $_.partId -eq "XVI" }).Count -gt 0

foreach ($part in $json) {
    if ($part.partId -eq "XVI") {
        $updated += $partXVI
        $inserted = $true
    }
    else {
        $updated += $part
        if ($part.partId -eq "XV" -and -not $inserted -and -not $hasExistingPartXVI) {
            $updated += $partXVI
            $inserted = $true
        }
    }
}

if (-not $inserted) {
    $updated += $partXVI
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $updated -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Part XVI rebuilt and inserted from the available docx sources."
