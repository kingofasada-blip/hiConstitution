$jsonPath = ".\data\articles.json"
$text = Get-Content -Raw -Encoding UTF8 $jsonPath

# The user reported that superscripts with brackets like <sup>1</sup>[ are sometimes separated from their content by a newline.
# We will find any <sup>number</sup>[ or <sup>number</sup>* that is immediately followed by a newline (and optional whitespace)
# and remove the newline, attaching the bracket to the following text.

$newText = [regex]::Replace($text, '(<sup>\d+</sup>(?:\[|\*))\s*\r?\n\s*', '$1')

# Also, if the <sup> happens to be PRECEDING a newline but it shouldn't be? 
# The issue explicitly says "waha koshtahk ko agli line me likh diya" - "the bracket was written on the next line"
# Wait, this means the bracket was moved to the next line AFTER the text? No, "jis koshthak ke aage upr likhna tha waha koshtahk ko agli line me likh diya" means "the bracket was written on the next line" relative to what?
# "where the superscript was to be written before the bracket, there the bracket was written on the next line"
# This perfectly describes:
# <sup>1</sup>
# [
# Or:
# <sup>1</sup>[
# (2)
# Since the regex (?<!^)(\([0-9A-Za-z]+\))\s in insert_part14_ascii.ps1 added a newline BEFORE the (2), it resulted in 1[ being on the previous line, and (2) being on the next line.
# By replacing (<sup>\d+</sup>\[)\s*\r?\n\s* with $1, we join them back to <sup>1</sup>[(2).

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($jsonPath, $newText, $utf8NoBom)

Write-Output "Fixed newline issues after superscript brackets."
