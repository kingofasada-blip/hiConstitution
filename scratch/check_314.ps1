$rootPath = "c:\Users\DeLL\Desktop\hiCONSTITUTION"
$hindiDoc = Join-Path $rootPath "part 14 hindi original.docx"
$hindiSimpleDoc = Join-Path $rootPath "part 14 hindi saral.docx"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-DocLines {
    param([string]$Path)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $zip.GetEntry("word/document.xml")
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xmlText = $reader.ReadToEnd()
        $reader.Dispose()
    } finally { $zip.Dispose() }
    $paragraphs = [regex]::Matches($xmlText, '<w:p\b.*?</w:p>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $lines = @()
    foreach ($paragraph in $paragraphs) {
        $textRuns = [regex]::Matches($paragraph.Value, '<w:t[^>]*>(.*?)</w:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($textRuns.Count -eq 0) { continue }
        $line = ""
        foreach ($textRun in $textRuns) { $line += [System.Net.WebUtility]::HtmlDecode($textRun.Groups[1].Value) }
        $line = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line)) { $lines += $line }
    }
    return $lines
}

$hLines = Get-DocLines $hindiDoc
$hsLines = Get-DocLines $hindiSimpleDoc

"--- Hindi Original lines near 314 ---"
$hLines | Select-String -Pattern "314" -Context 2, 5

"--- Hindi Saral lines near 314 ---"
$hsLines | Select-String -Pattern "314" -Context 2, 5
