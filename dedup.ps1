$json = Get-Content -Raw -Encoding UTF8 .\data\articles.json | ConvertFrom-Json
$dedup = @()
foreach ($p in $json) {
    $found = $false
    foreach ($d in $dedup) {
        if ($d.partId -eq $p.partId) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $dedup += $p
    }
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json -InputObject $dedup -Depth 16
[System.IO.File]::WriteAllText(".\data\articles.json", $jsonOut, $utf8NoBom)
Write-Output "Dedup done."
