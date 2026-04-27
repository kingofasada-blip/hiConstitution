$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$jsonPath = Join-Path $rootPath "data\articles.json"

$part11Docs = Get-ChildItem -LiteralPath $rootPath -File | Where-Object { $_.Name -like 'part 11*.docx' }
$englishDoc = ($part11Docs | Where-Object Name -eq 'part 11 english.docx' | Select-Object -First 1).FullName
$englishSimpleDoc = ($part11Docs | Where-Object Name -eq 'part 11 english Simplified Explanation.docx' | Select-Object -First 1).FullName
$hindiDoc = ($part11Docs | Where-Object { $_.Name -like 'part 11 *original*.docx' -and $_.Name -notlike '*english*' } | Select-Object -First 1).FullName
$hindiSimpleDoc = ($part11Docs | Where-Object { $_.Name -like 'part 11*.docx' -and $_.Name -notlike '*english*' -and $_.Name -notlike '*original*' } | Select-Object -First 1).FullName

foreach ($requiredPath in @($englishDoc, $englishSimpleDoc, $hindiDoc, $hindiSimpleDoc)) {
    if ([string]::IsNullOrWhiteSpace($requiredPath) -or -not (Test-Path -LiteralPath $requiredPath)) {
        throw "One or more Part XI source docx files were not found."
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

function Clean-TitleText {
    param([string]$Text)

    $clean = $Text.Trim()
    $clean = $clean -replace '^\[+', ''
    $clean = $clean -replace '\]+$', ''
    $clean = $clean.Trim()
    $clean = $clean.TrimEnd('.', ']')
    return $clean
}

function Clean-BodyText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = $Text.Trim()
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

function New-OriginalArticle {
    param(
        [string]$Id,
        [string]$Title,
        [string]$HeadingPrefix
    )

    return [ordered]@{
        id = $Id
        titleText = $Title
        text = "<strong>$HeadingPrefix $Id. $Title.-</strong>"
        amendmentLabel = ""
        amendmentLines = @()
        inAmendments = $false
    }
}

function Finalize-OriginalArticle {
    param($Article)

    if ($null -eq $Article) {
        return $null
    }

    if ($Article.amendmentLines.Count -gt 0) {
        $Article.text += "`n<strong>$($Article.amendmentLabel)</strong>"
        foreach ($line in $Article.amendmentLines) {
            $Article.text += "`n$line"
        }
    }

    $Article.Remove('amendmentLabel')
    $Article.Remove('amendmentLines')
    $Article.Remove('inAmendments')
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
    $articlePattern = '^(?:[\u2070\u00B9\u00B2\u00B3\u2074\u2075\u2076\u2077\u2078\u2079]+\[)?\[?(\d{3})([A-Za-z\u0915-\u0918]*)\.\s*(.+?)(?:(?:\s*[\u2014\u2013]\s*)|(?:\s-\s))(.*)$'

    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()

        if ($line -match $articlePattern) {
            $final = Finalize-OriginalArticle -Article $current
            if ($null -ne $final) {
                $articles[$final.id] = $final
            }

            $articleId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $articleTitle = Clean-TitleText -Text $matches[3]
            $articleBody = Clean-BodyText -Text $matches[4]

            $current = New-OriginalArticle -Id $articleId -Title $articleTitle -HeadingPrefix $HeadingPrefix
            $current.amendmentLabel = $AmendmentLabel

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
    $pattern = '^(?:Article|\u0905\u0928\u0941\u091A\u094D\u091B\u0947\u0926)\s+(\d{3})([A-Za-z\u0915-\u0918]*)\s*:\s*(.*)$'

    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()

        if ($line -match $pattern) {
            if ($null -ne $currentId) {
                $articles[$currentId] = ($buffer -join "`n").Trim()
            }

            $currentId = Normalize-ArticleId -Digits $matches[1] -Suffix $matches[2]
            $buffer = @($matches[3].Trim())
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
$englishSimplified = Parse-SimplifiedDoc -Path $englishSimpleDoc
$hindiSimplified = Parse-SimplifiedDoc -Path $hindiSimpleDoc

$orderedIds = @(
    "245", "246", "246A", "247", "248", "249", "250", "251", "252", "253", "254", "255",
    "256", "257", "257A", "258", "258A", "259", "260", "261", "262", "263"
)

$partArticles = @()
foreach ($id in $orderedIds) {
    if (-not $englishOriginal.Contains($id)) {
        throw "Missing original English content for article $id"
    }

    $enRecord = $englishOriginal[$id]
    $partArticles += [ordered]@{
        id = $id
        title = "Article ${id}: $($enRecord.titleText)"
        preview = Get-PreviewText -SimplifiedText $englishSimplified[$id] -OriginalText $enRecord.text
        text = $enRecord.text
        simplified = $englishSimplified[$id]
        hindi = if ($hindiOriginal.Contains($id)) { $hindiOriginal[$id].text } else { "" }
        hindiSimplified = if ($hindiSimplified.Contains($id)) { $hindiSimplified[$id] } else { "" }
    }
}

$partXI = [ordered]@{
    partId = "XI"
    partTitle = "Part XI - Relations Between the Union and the States"
    partDesc = "Articles 245 to 263 covering legislative and administrative relations between the Union and the States."
    articles = $partArticles
}

$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$updated = @()

foreach ($part in $json) {
    if ($part.partId -eq "XI") {
        $updated += $partXI
    }
    else {
        $updated += $part
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json -InputObject $updated -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Part XI rebuilt from the four docx sources."
