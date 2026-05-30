# Extract text from docx XML (word/document.xml)
# Uses regex to get text runs from w:t elements

function Extract-DocxText {
    param($xmlPath)
    $xml = [xml](Get-Content $xmlPath -Encoding UTF8 -Raw)
    $ns = @{ w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main' }
    $paragraphs = $xml.SelectNodes('//w:p', ([System.Xml.XmlNamespaceManager]([System.Xml.XmlDocument]$xml).NameTable))
    
    $lines = @()
    foreach ($para in $paragraphs) {
        $runs = $para.SelectNodes('.//w:t', ([System.Xml.XmlNamespaceManager]([System.Xml.XmlDocument]$xml).NameTable))
        $lineText = ''
        foreach ($run in $runs) {
            $lineText += $run.InnerText
        }
        $lines += $lineText
    }
    return $lines
}

# For simplified doc
$simplifiedLines = Extract-DocxText 'c:\Users\DeLL\Desktop\hiCONSTITUTION\part5_simplified_unzipped\word\document.xml'
$simplifiedLines | Out-File 'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\part5_simplified_text.txt' -Encoding UTF8
Write-Host "Simplified lines: $($simplifiedLines.Count)"
Write-Host "=== First 50 lines ==="
$simplifiedLines[0..49] | ForEach-Object { Write-Host $_ }
