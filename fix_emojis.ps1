$path = "c:\Users\DeLL\Desktop\hiCONSTITUTION\Constitution-making.html"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$content = $content.Replace('â€”', '—')
$content = $content.Replace('â–¼', '▼')
$content = $content.Replace('ðŸ›ï¸', '🏛️')
$content = $content.Replace('â³', '⏳')
$content = $content.Replace('ðŸ‘¥', '👥')
$content = $content.Replace('ðŸ“‹', '📋')
$content = $content.Replace('ðŸ“Œ', '📌')
$content = $content.Replace('ðŸ“…', '📅')
$content = $content.Replace('âœ…', '✅')
$content = $content.Replace('ðŸ”', '🔍')
$content = $content.Replace('Â©', '©')
$content = $content.Replace('â€“', '–')
$content = $content.Replace('ðŸ‘¤', '👤')

Set-Content -Path $path -Value $content -Encoding UTF8
Write-Output "Done"