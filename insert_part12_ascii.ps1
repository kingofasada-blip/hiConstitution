$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$jsonPath = Join-Path $rootPath "data\articles.json"

$part12Docs = Get-ChildItem -LiteralPath $rootPath -File | Where-Object { $_.Name -like 'part 12*.docx' }
$englishDoc = ($part12Docs | Where-Object Name -eq 'part 12 english original FULL.docx' | Select-Object -First 1).FullName
if ([string]::IsNullOrWhiteSpace($englishDoc)) {
    $englishDoc = ($part12Docs | Where-Object Name -eq 'part 12 english original.docx' | Select-Object -First 1).FullName
}
$englishSimpleDoc = ($part12Docs | Where-Object Name -eq 'part 12 english simplyfied.docx' | Select-Object -First 1).FullName
$hindiDoc = ($part12Docs | Where-Object Name -eq 'part 12 hindi original.docx' | Select-Object -First 1).FullName
$hindiSimpleDoc = ($part12Docs | Where-Object Name -eq 'part 12 hindi saral.docx' | Select-Object -First 1).FullName

foreach ($requiredPath in @($englishDoc, $englishSimpleDoc, $hindiDoc, $hindiSimpleDoc)) {
    if ([string]::IsNullOrWhiteSpace($requiredPath) -or -not (Test-Path -LiteralPath $requiredPath)) {
        throw "One or more Part XII source docx files were not found."
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
$hindiClauseWord = "$([char]0x0916)$([char]0x0902)$([char]0x0921)"
$hindiSubClauseWord = "$([char]0x0909)$([char]0x092A)$([char]0x0916)$([char]0x0902)$([char]0x0921)"
$hindiArticleRefWord = "$([char]0x0905)$([char]0x0928)$([char]0x0941)$([char]0x091A)$([char]0x094D)$([char]0x091B)$([char]0x0947)$([char]0x0926)"
$hindiParagraphWord = "$([char]0x092A)$([char]0x0948)$([char]0x0930)$([char]0x093E)"
$hindiProvisoWord = "$([char]0x092A)$([char]0x0930)$([char]0x0902)$([char]0x0924)$([char]0x0941)$([char]0x0915)"

$sectionHeadings = @(
    "Distribution of Revenues between the Union and the States",
    "Miscellaneous Financial Provisions",
    "Property, Contracts, Rights, Liabilities, Obligations and Suits",
    "Articles relating to Part XII"
)

$hindiSectionHeadings = @(
    [string]::Concat([char]0x0938,[char]0x0902,[char]0x0918,[char]0x0914,[char]0x0930,[char]0x0930,[char]0x093E,[char]0x091C,[char]0x094D,[char]0x092F,[char]0x094B,[char]0x0902,[char]0x0915,[char]0x0947,[char]0x092C,[char]0x0940,[char]0x091A,[char]0x0930,[char]0x093E,[char]0x091C,[char]0x0938,[char]0x094D,[char]0x0935,[char]0x0915,[char]0x093E,[char]0x0935,[char]0x093F,[char]0x0924,[char]0x0930,[char]0x0923),
    [string]::Concat([char]0x0935,[char]0x093F,[char]0x0935,[char]0x093F,[char]0x0927,[char]0x0935,[char]0x093F,[char]0x0924,[char]0x094D,[char]0x0924,[char]0x0940,[char]0x092F,[char]0x0909,[char]0x092A,[char]0x092C,[char]0x0902,[char]0x0927),
    [string]::Concat([char]0x0938,[char]0x0902,[char]0x092A,[char]0x0924,[char]0x094D,[char]0x0924,[char]0x093F,[char]0x002C,[char]0x0905,[char]0x0928,[char]0x0941,[char]0x092C,[char]0x0902,[char]0x0927,[char]0x002C,[char]0x0905,[char]0x0927,[char]0x093F,[char]0x0915,[char]0x093E,[char]0x0930,[char]0x002C,[char]0x0926,[char]0x093E,[char]0x092F,[char]0x093F,[char]0x0924,[char]0x094D,[char]0x0935,[char]0x002C,[char]0x092C,[char]0x093E,[char]0x0927,[char]0x094D,[char]0x092F,[char]0x0924,[char]0x093E,[char]0x090F,[char]0x0901,[char]0x0914,[char]0x0930,[char]0x0935,[char]0x093E,[char]0x0926)
)

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
    $clean = $clean.TrimEnd('.', ']')
    return $clean
}

function Get-HeadingTitleText {
    param([string]$Text)

    $clean = Normalize-SourceLine -Text $Text
    return $clean.Trim()
}

function Clean-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = Normalize-SourceLine -Text $Text
    $clean = Convert-SuperscriptsToHtml -Text $clean
    $clean = $clean -replace ':\.', ':'
    $clean = $clean -replace '\u2014\.', [string][char]0x2014
    $clean = $clean -replace '\]\.?$', ''
    $clean = $clean -replace '(?<!^)(\([0-9A-Za-z]+\))\s', "`n`$1 "
    $clean = $clean -replace '(?<!^)(\([\u0915-\u0939]\))\s', "`n`$1 "
    $clean = $clean -replace '(?<!^)(\([ivxIVX]+\))\s', "`n`$1 "
    $clean = $clean -replace '(?<!^)(Provided that|Provided further that|Provided also that)\b', "`n`$1"
    $clean = $clean -replace '(?<!^)(\u092A\u0930\u0902\u0924\u0941)\b', "`n`$1"
    return $clean.Trim()
}

function Normalize-ClauseReferenceBreaks {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $normalized = $Text
    $patterns = @(
        '(?im)\b(clause|sub-clause|clauses|sub-clauses|proviso|provisos|article|articles|paragraph|paragraphs|part|parts)\s*\r?\n\s*(\([0-9A-Za-z]+\))',
        '(?im)\b(cls?\.|sub-cls?\.|arts?\.|paras?\.)\s*\r?\n\s*(\([0-9A-Za-z]+\))',
        "(?im)($([regex]::Escape($hindiClauseWord))|$([regex]::Escape($hindiSubClauseWord))|$([regex]::Escape($hindiArticleRefWord))|$([regex]::Escape($hindiParagraphWord))|$([regex]::Escape($hindiProvisoWord)))\s*\r?\n\s*(\([^)]+\))",
        '(?im)(<sup>\d+</sup>\[)\s*(\([0-9A-Za-z]+\))'
    )

    foreach ($pattern in $patterns) {
        $normalized = [regex]::Replace($normalized, $pattern, '$1 $2')
    }

    $normalized = [regex]::Replace($normalized, '(?im)(<sup>\d+</sup>\[)\s+(\([0-9A-Za-z]+\))', '$1$2')

    return $normalized
}

function New-OriginalArticle {
    param(
        [string]$Id,
        [string]$Title,
        [string]$HeadingTitle,
        [string]$HeadingPrefix,
        [string]$OpeningPrefixHtml
    )

    return [ordered]@{
        id = $Id
        titleText = $Title
        headingTitleText = $HeadingTitle
        text = "<strong>$OpeningPrefixHtml$HeadingPrefix $Id. $HeadingTitle.-</strong>"
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
    $Article.Remove('headingTitleText')
    $Article.Remove('referenceNumbers')
    return $Article
}

function Is-SectionHeading {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $false
    }

    $trimmed = (Normalize-SourceLine -Text $Line).Trim()
    return $sectionHeadings -contains $trimmed -or $hindiSectionHeadings -contains $trimmed
}

function Is-SimplifiedPreamble {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $false
    }

    $trimmed = (Normalize-SourceLine -Text $Line).Trim()
    if ($trimmed -like 'जी हाँ*') {
        return $true
    }

    if ($trimmed -like 'आपके निर्देशानुसार*') {
        return $true
    }

    return $false
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
    $articlePattern = '^(?:[\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+\[?)?\[?(\d{3})([A-Za-z\u0915-\u0918]*)\.\s*(.+?)(?:(?:\s*[\u2014\u2013]\s*)|(?:\s-\s))(.*)$'

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        if (Is-SectionHeading -Line $line) {
            continue
        }

        if ($line -match $articlePattern) {
            $final = Finalize-OriginalArticle -Article $current
            if ($null -ne $final) {
                $articles[$final.id] = $final
            }

            $articleId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $articleTitle = Clean-TitleText -Text $matches[3]
            $headingTitle = Get-HeadingTitleText -Text $matches[3]
            $articleBody = Clean-BodyText -Text $matches[4]
            $openingPrefixRaw = ([regex]::Match($line, '^(.*?)(?=\d{3}[A-Za-z\u0915-\u0918]*\.)')).Groups[1].Value
            $openingPrefixHtml = Convert-SuperscriptsToHtml -Text $openingPrefixRaw

            $current = New-OriginalArticle -Id $articleId -Title $articleTitle -HeadingTitle $headingTitle -HeadingPrefix $HeadingPrefix -OpeningPrefixHtml $openingPrefixHtml
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

        if ($line -match '^(Amendments:|\u0938\u0902\u0936\u094B\u0927\u0928:)$') {
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

function Parse-SimplifiedDoc {
    param([string]$Path)

    $lines = Get-DocLines -Path $Path
    $articles = [ordered]@{}
    $currentId = $null
    $buffer = @()
    $pattern = '^(?:(?:Article|\u0905\u0928\u0941\u091A\u094D\u091B\u0947\u0926)\s+)?(\d{3})([A-Za-z\u0915-\u0918]*)\s*(?:\((.*?)\))?\s*[\.:]\s*(.*)$'

    foreach ($rawLine in $lines) {
        $line = Normalize-SourceLine -Text $rawLine
        if (Is-SectionHeading -Line $line) {
            continue
        }
        if (Is-SimplifiedPreamble -Line $line) {
            continue
        }

        if ($line -match $pattern) {
            if ($null -ne $currentId) {
                $articles[$currentId] = ($buffer -join "`n").Trim()
            }

            $currentId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $initialText = if (-not [string]::IsNullOrWhiteSpace($matches[4])) { $matches[4].Trim() } elseif (-not [string]::IsNullOrWhiteSpace($matches[3])) { $matches[3].Trim() } else { "" }
            $buffer = @($initialText)
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

function Remove-BracketClauseGap {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    return [regex]::Replace($Text, '(?im)(<sup>\d+</sup>\[)\s+(\([^)]+\))', '$1$2')
}

$englishOriginal = Parse-OriginalDoc -Path $englishDoc -HeadingPrefix "Article" -AmendmentLabel "Amendments:"
$hindiOriginal = Parse-OriginalDoc -Path $hindiDoc -HeadingPrefix $hindiArticleWord -AmendmentLabel $hindiAmendmentLabel
$englishSimplified = Parse-SimplifiedDoc -Path $englishSimpleDoc
$hindiSimplified = Parse-SimplifiedDoc -Path $hindiSimpleDoc

$orderedIds = @($englishOriginal.Keys)
$partArticles = @()

foreach ($id in $orderedIds) {
    $enRecord = $englishOriginal[$id]
    $finalEnglishText = Remove-BracketClauseGap -Text $enRecord.text
    $finalHindiText = if ($hindiOriginal.Contains($id)) { Remove-BracketClauseGap -Text $hindiOriginal[$id].text } else { "" }
    $partArticles += [ordered]@{
        id = $id
        title = "Article ${id}: $($enRecord.titleText)"
        preview = Get-PreviewText -SimplifiedText $englishSimplified[$id] -OriginalText $finalEnglishText
        text = $finalEnglishText
        simplified = if ($englishSimplified.Contains($id)) { $englishSimplified[$id] } else { "" }
        hindi = $finalHindiText
        hindiSimplified = if ($hindiSimplified.Contains($id)) { $hindiSimplified[$id] } else { "" }
    }
}

$partXII = [ordered]@{
    partId = "XII"
    partTitle = "Part XII - Finance, Property, Contracts and Suits"
    partDesc = "Articles 264 to 300A covering finance, taxation, property, contracts, liabilities and the constitutional right to property."
    articles = $partArticles
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$updated = @()

foreach ($part in $json) {
    if ($part.partId -eq "XII") {
        $updated += $partXII
    }
    else {
        $updated += $part
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json -InputObject $updated -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Part XII rebuilt from the four docx sources."
