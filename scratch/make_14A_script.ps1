$script = Get-Content ".\insert_part14_ascii.ps1" -Raw

$script = $script -replace 'part 14 original english\.docx', 'part 14A - PART XIVA TRIBUNALS (in english original).docx'
$script = $script -replace 'part 14 english simple explanation\.docx', 'part 14A english simple explanation.docx'
$script = $script -replace 'part 14 hindi original\.docx', 'part 14A hindi original .docx'
$script = $script -replace 'part 14 hindi saral\.docx', 'part 14A hindi saral.docx'
$script = $script -replace 'Part XIV source file', 'Part XIVA source file'
$script = $script -replace '\$partXIV = \[ordered\]@\{[^}]+\}', '$partXIVA = [ordered]@{
    partId = "XIVA"
    partTitle = "Part XIVA - Tribunals"
    partDesc = "Articles 323A to 323B, dealing with administrative and other tribunals."
    articles = $partArticles
}'

$script = $script -replace '\$updated \+= \$partXIV', '$updated += $partXIVA'
$script = $script -replace 'if \(\$part\.partId -eq "XIV"\)', 'if ($part.partId -eq "XIVA")'
$script = $script -replace 'if \(\$part\.partId -eq "XIII"', 'if ($part.partId -eq "XIV"'
$script = $script -replace 'Part XIII is the preceding part', 'Part XIV is the preceding part'
$script = $script -replace 'Part XIV rebuilt', 'Part XIVA rebuilt'
# IMPORTANT: fix the value wrapper logic since I removed -InputObject manually earlier but the old script had it
$script = $script -replace '\$json = Get-Content -LiteralPath \$jsonPath -Raw -Encoding UTF8 \| ConvertFrom-Json', '$json = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json; if($json.value) { $json = $json.value }'
$script = $script -replace 'ConvertTo-Json -InputObject \$updated -Depth 16', 'ConvertTo-Json $updated -Depth 16'

[System.IO.File]::WriteAllText(".\insert_part14A_ascii.ps1", $script)
Write-Output "Created insert_part14A_ascii.ps1"
