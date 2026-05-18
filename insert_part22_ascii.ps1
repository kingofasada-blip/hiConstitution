$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$jsonPath = Join-Path $rootPath "data\articles.json"

$englishDoc = Join-Path $rootPath "PART 22 - english original.docx"
$englishSimpleDoc = Join-Path $rootPath "PART 22 - english simlify.docx"
$hindiDoc = Join-Path $rootPath "PART 22 - hindi original.docx"
$hindiSimpleDoc = Join-Path $rootPath "PART 22 - hindi simplify.docx"

foreach ($requiredPath in @($englishDoc, $englishSimpleDoc, $hindiDoc, $hindiSimpleDoc)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Part 22 source file: $requiredPath"
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$hindiArticleWord = [string]::Concat(
    [char]0x0905, [char]0x0928, [char]0x0941, [char]0x091A,
    [char]0x094D, [char]0x091B, [char]0x0947, [char]0x0926
)
$hindiAmendmentLabel = [string]::Concat(
    [char]0x0938, [char]0x0902, [char]0x0936,
    [char]0x094B, [char]0x0927, [char]0x0928, ' ', ':'
)
$hindiProvisoWord = [string]::Concat(
    [char]0x092A, [char]0x0930, [char]0x0902, [char]0x0924, [char]0x0941
)
$emDash = [string][char]0x2014
$enDash = [string][char]0x2013

function Convert-DigitsToSuperscriptText {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $map = @{
        '0' = [char]8304; '1' = [char]185; '2' = [char]178; '3' = [char]179; '4' = [char]8308
        '5' = [char]8309; '6' = [char]8310; '7' = [char]8311; '8' = [char]8312; '9' = [char]8313
    }
    $converted = ""
    foreach ($char in $Text.ToCharArray()) {
        $key = [string]$char
        if ($map.ContainsKey($key)) { $converted += $map[$key] } else { $converted += $char }
    }
    return $converted
}

function Get-DocLines {
    param([string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($resolved)
    try {
        $entry = $zip.GetEntry("word/document.xml")
        if ($null -eq $entry) { throw "word/document.xml not found in $Path" }
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
        if ($runs.Count -eq 0) { continue }
        $line = ""
        foreach ($run in $runs) {
            $textRuns = [regex]::Matches($run.Value, '<w:t[^>]*>(.*?)</w:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($textRuns.Count -eq 0) { continue }
            $runText = ""
            foreach ($textRun in $textRuns) { $runText += [System.Net.WebUtility]::HtmlDecode($textRun.Groups[1].Value) }
            if ($run.Value -match '<w:vertAlign\b[^>]*w:val="superscript"') {
                $runText = Convert-DigitsToSuperscriptText -Text $runText
            }
            $line += $runText
        }
        $line = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line)) { $lines += $line }
    }
    return $lines
}

function Convert-SuperscriptsToHtml {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $map = @{
        ([char]8304) = '0'; ([char]185) = '1'; ([char]178) = '2'; ([char]179) = '3'; ([char]8308) = '4'
        ([char]8309) = '5'; ([char]8310) = '6'; ([char]8311) = '7'; ([char]8312) = '8'; ([char]8313) = '9'
    }
    return [regex]::Replace(
        $Text,
        '([\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+)',
        {
            param($match)
            $digits = ""
            foreach ($char in $match.Groups[1].Value.ToCharArray()) {
                if ($map.ContainsKey($char)) { $digits += $map[$char] }
            }
            if ([string]::IsNullOrWhiteSpace($digits)) { return $match.Value }
            return "<sup>$digits</sup>"
        }
    )
}

function Convert-ReferenceMarkersToHtml {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    return [regex]::Replace($Text, '(?<!\d)(\d+)(?=(?:\[|\*+))', { param($match) "<sup>$($match.Groups[1].Value)</sup>" })
}

function Normalize-ArticleId {
    param([string]$Digits, [string]$Suffix)
    $normalizedSuffix = ""
    if ($null -ne $Suffix) { $normalizedSuffix = $Suffix }
    $normalizedSuffix = $normalizedSuffix.Trim() -replace '[-\s]', ''
    $normalizedSuffix = $normalizedSuffix `
        -replace '\u0915', 'A' `
        -replace '\u0916', 'B' `
        -replace '\u0917', 'C' `
        -replace '\u0918', 'D' `
        -replace '\u0919', 'E' `
        -replace '\u091A', 'F' `
        -replace '\u091B', 'G' `
        -replace '\u091C', 'H' `
        -replace '\u091D', 'I' `
        -replace '\u091E', 'J'
    return "$Digits$($normalizedSuffix.ToUpperInvariant())"
}

function Normalize-SourceLine {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $normalized = $Text.Trim()
    $normalized = $normalized -replace '^\uFEFF', ''
    $normalized = $normalized -replace '^\*\*', ''
    $normalized = $normalized -replace '\*\*', ''
    return $normalized.Trim()
}

function Clean-TitleText {
    param([string]$Text)
    $clean = Normalize-SourceLine -Text $Text
    $clean = $clean -replace '^\[+', ''
    $clean = $clean -replace '\]+$', ''
    $clean = $clean.Trim()
    $clean = $clean -replace "[\.\]\-$([regex]::Escape($emDash))$([regex]::Escape($enDash))]+$", ''
    return $clean
}

function Clean-BodyText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
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

function Split-HeadingAndBody {
    param([string]$Text)
    $separatorPattern = '^(.*?)(?:\.\s*—|\.\s*–|\.—|\.–|—|–)(.*)$'
    if ($Text -match $separatorPattern) {
        return [ordered]@{ Title = $matches[1]; Body = $matches[2] }
    }
    return [ordered]@{ Title = $Text; Body = "" }
}

function New-OriginalArticle {
    param([string]$Id, [string]$Title, [string]$HeadingPrefix, [string]$OpeningPrefixHtml)
    $displayId = $Id.Substring(0, 3)
    if ($Id.Length -gt 3) { $displayId += $Id.Substring(3) }
    $titlePrefix = "<strong>${OpeningPrefixHtml}${HeadingPrefix} $displayId. $Title$emDash</strong>"
    return [ordered]@{
        id = $Id
        titleText = $Title
        text = $titlePrefix
        amendmentLines = @()
        inAmendments = $false
        amendmentLabel = "Amendments:"
    }
}

function Finalize-OriginalArticle {
    param([hashtable]$Article)
    if ($null -eq $Article) { return $null }
    if ($Article.amendmentLines.Count -gt 0) {
        $Article.text += "`n<strong>$($Article.amendmentLabel)</strong>"
        foreach ($line in $Article.amendmentLines) { $Article.text += "`n$line" }
    }
    $Article.Remove("amendmentLines")
    $Article.Remove("inAmendments")
    $Article.Remove("amendmentLabel")
    return $Article
}

function Parse-OriginalDoc {
    param([string]$Path, [string]$HeadingPrefix, [string]$AmendmentLabel)
    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $current = $null
    $articlePattern = '^(.*?)(\d{3})(?:-?([A-Za-z\u0915-\u091E]+))?\.\s*(.*)$'
    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        if ($line -match $articlePattern) {
            $final = Finalize-OriginalArticle -Article $current
            if ($null -ne $final) { $articles[$final.id] = $final }
            $openingPrefixRaw = $matches[1]
            $articleId = Normalize-ArticleId -Digits $matches[2] -Suffix $matches[3]
            $headingParts = Split-HeadingAndBody -Text $matches[4]
            $articleTitle = Clean-TitleText -Text $headingParts.Title
            $articleBody = Clean-BodyText -Text $headingParts.Body
            $openingPrefixHtml = Convert-ReferenceMarkersToHtml -Text (Convert-SuperscriptsToHtml -Text $openingPrefixRaw)
            $current = New-OriginalArticle -Id $articleId -Title $articleTitle -HeadingPrefix $HeadingPrefix -OpeningPrefixHtml $openingPrefixHtml
            $current.amendmentLabel = $AmendmentLabel
            if (-not [string]::IsNullOrWhiteSpace($articleBody)) { $current.text += "`n$articleBody" }
            continue
        }
        if ($null -eq $current) { continue }
        if ($line -match "^(Amendment:|Amendments:|Amendment / Footnote:.*|$([regex]::Escape($hindiAmendmentLabel))|.+/ .+:.*)$") {
            $current.inAmendments = $true
            $lineProcessed = Clean-BodyText -Text $line
            if ($lineProcessed -match '^[^:]+:\s*') {
                $lineProcessed = $lineProcessed -replace '^[^:]+:\s*', ''
                if (-not [string]::IsNullOrWhiteSpace($lineProcessed)) { $current.amendmentLines += $lineProcessed }
            }
            continue
        }
        $lineProcessed = Clean-BodyText -Text $line
        if ([string]::IsNullOrWhiteSpace($lineProcessed)) { continue }
        if ($current.inAmendments) { $current.amendmentLines += $lineProcessed } else { $current.text += "`n$lineProcessed" }
    }
    $final = Finalize-OriginalArticle -Article $current
    if ($null -ne $final) { $articles[$final.id] = $final }
    return $articles
}

function Parse-EnglishSimplifiedDoc {
    param([string]$Path)
    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $currentId = $null
    $buffer = @()
    $pattern = '^Article\s+(\d{3}(?:-?[A-Za-z])?)(?:\s*\([^)]+\))?(?::\s*|\s+)(.*)$'
    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        if ($line -match $pattern) {
            if ($null -ne $currentId) { $articles[$currentId] = ($buffer -join "`n").Trim() }
            $articleToken = $matches[1]
            $text = $matches[2]
            if ($articleToken -match '^(\d{3})(?:-?([A-Za-z]))?$') {
                $currentId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            } else {
                $currentId = $articleToken.ToUpperInvariant() -replace '-', ''
            }
            $buffer = @()
            $text = $text.Trim()
            if (-not [string]::IsNullOrWhiteSpace($text)) { $buffer += $text }
            continue
        }
        if ($null -ne $currentId) { $buffer += $line }
    }
    if ($null -ne $currentId) { $articles[$currentId] = ($buffer -join "`n").Trim() }
    return $articles
}

function Parse-HindiSimplifiedDoc {
    param([string]$Path)
    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $currentId = $null
    $buffer = @()
    $pattern = "^(?:$([regex]::Escape($hindiArticleWord))\s*)?(\d{3})([\u0915-\u091E]*)\s*(?::\s*|\s+)(.*)$"
    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        if ($line -match $pattern) {
            if ($null -ne $currentId) { $articles[$currentId] = ($buffer -join "`n").Trim() }
            $currentId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $text = $matches[3].Trim()
            $buffer = @()
            if (-not [string]::IsNullOrWhiteSpace($text)) { $buffer += $text }
            continue
        }
        if ($null -ne $currentId) { $buffer += $line }
    }
    if ($null -ne $currentId) { $articles[$currentId] = ($buffer -join "`n").Trim() }
    return $articles
}

function Get-PreviewText {
    param([string]$SimplifiedText, [string]$OriginalText)
    $source = $SimplifiedText
    if ([string]::IsNullOrWhiteSpace($source)) { $source = $OriginalText }
    $preview = ($source -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
    $preview = $preview -replace '^.*?(Article|अनुच्छेद)\s+', '$1 '
    if ($preview.Length -gt 180) { $preview = $preview.Substring(0, 180) + "..." }
    return $preview
}

$englishOriginal = Parse-OriginalDoc -Path $englishDoc -HeadingPrefix "Article" -AmendmentLabel "Amendments:"
$hindiOriginal = Parse-OriginalDoc -Path $hindiDoc -HeadingPrefix $hindiArticleWord -AmendmentLabel $hindiAmendmentLabel
$englishSimplified = Parse-EnglishSimplifiedDoc -Path $englishSimpleDoc
$hindiSimplified = Parse-HindiSimplifiedDoc -Path $hindiSimpleDoc

$validArticlePattern = '^(393|394A?|395)$'
$orderedIds = @($englishOriginal.Keys | Where-Object { $_ -match $validArticlePattern })
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

$partXXII = [ordered]@{
    partId = "XXII"
    partTitle = "Part XXII - Short Title, Commencement, Authoritative Text in Hindi and Repeals"
    partDesc = "Articles 393 to 395, including Article 394A, covering the short title, commencement, authoritative Hindi text, and repeals."
    articles = $partArticles
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($json -isnot [System.Array] -and $json.PSObject.Properties.Name -contains 'value') { $json = $json.value }
$json = @($json)
$updated = @()

foreach ($part in $json) {
    if ($part.partId -eq "XXII") {
        $updated += $partXXII
    }
    else {
        $updated += $part
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json $updated -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Part XXII rebuilt from the available docx sources."
