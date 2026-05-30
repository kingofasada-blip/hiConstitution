[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$json = [System.IO.File]::ReadAllText('c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5 = $json | Where-Object { $_.partId -eq 'V' }

foreach ($id in @('124A','124B','124C')) {
    $art = $p5.articles | Where-Object { $_.id -eq $id }
    Write-Host "=== Article $id ==="
    Write-Host "hindi (first 200 chars):"
    Write-Host $art.hindi.Substring(0, [Math]::Min(200, $art.hindi.Length))
    Write-Host ""
}
