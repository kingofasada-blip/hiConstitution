$jsonPath = ".\data\articles.json"
$content = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
if ($content.value) { $array = $content.value } else { $array = $content }

$p14 = $array | Where-Object { $_.partId -eq 'XIV' }
$a314 = $p14.articles | Where-Object { $_.id -eq '314' }

$a314 | ConvertTo-Json -Depth 3 | Out-File .\scratch\view_314.json -Encoding utf8
