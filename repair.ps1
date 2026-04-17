$jsonContent = [System.IO.File]::ReadAllText("c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", [System.Text.Encoding]::UTF8)
$startIndex = $jsonContent.IndexOf("`"id`": `"96`"")
$start = $jsonContent.LastIndexOf("{", $startIndex)
$endIndex = $jsonContent.IndexOf("`"id`":  `"124`"")
$end = $jsonContent.LastIndexOf("{", $endIndex)
$result = $jsonContent.Substring(0, $start) + $jsonContent.Substring($end)

$utf8NoBom = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText("c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", $result, $utf8NoBom)
