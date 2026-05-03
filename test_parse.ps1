$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$hindiSimpleDoc = Join-Path $rootPath "part 14 hindi saral.docx"
$englishSimpleDoc = Join-Path $rootPath "part 14 english simple explanation.docx"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-DocLines {
    param([string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($resolved)
    try {
        $entry = $zip.GetEntry("word/document.xml")
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
        if ($textRuns.Count -eq 0) { continue }
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

$hLines = Get-DocLines $hindiSimpleDoc
$hLines | Out-File -FilePath .\hindi_simple.txt -Encoding UTF8
$eLines = Get-DocLines $englishSimpleDoc
$eLines | Out-File -FilePath .\english_simple.txt -Encoding UTF8
