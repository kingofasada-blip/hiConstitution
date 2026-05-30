# ============================================================
# format_hindi_parts1to5.ps1
# Formatting only - NO text/word changes:
#   1. Title (before em-dash —) stays bold, body moves to new line
#   2. "sanshodhan" word gets bolded, list starts on next line
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Unicode: em-dash U+2014, and "sanshodhan" U+0938 U+0902 U+0936 U+094B U+0927 U+0928
$emDash    = [char]0x2014   # —
$sanshodhan = [string]::new([char[]]@(0x0938,0x0902,0x0936,0x094B,0x0927,0x0928))  # संशोधन

$targetParts = @('I','II','III','IV','IVA','V')

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$totalUpdated = 0

foreach ($part in $json) {
    if ($part.partId -notin $targetParts) { continue }
    Write-Host "Processing Part $($part.partId)..."
    $partUpdated = 0

    foreach ($art in $part.articles) {
        if (-not $art.hindi -or $art.hindi.Trim() -eq '') { continue }

        $h = $art.hindi
        $orig = $h

        # ----------------------------------------------------------------
        # STEP 1: Fix title/body separation
        # ----------------------------------------------------------------
        # Case A (Part V style): <strong>NN. Title— body text</strong>
        # The em-dash is INSIDE <strong>, and body follows inside same tag.
        # Fix: close </strong> right after —, add newline, then body
        # Pattern: <strong>...—<NON-NEWLINE-TEXT></strong>
        if ($h -match '^<strong>[^<]*' + [regex]::Escape($emDash)) {
            # Find the em-dash position inside the opening <strong>
            $strongOpenEnd = $h.IndexOf('</strong>')
            $emDashPos = $h.IndexOf($emDash)
            
            if ($emDashPos -gt 0 -and $emDashPos -lt $strongOpenEnd) {
                # There's content after — but before </strong>
                # Extract: everything up to and including —
                $titlePart = $h.Substring(0, $emDashPos + 1)  # includes —
                $rest = $h.Substring($emDashPos + 1)            # after —
                
                # rest might be: " body</strong>\nmore text"
                # We want: "</strong>\nbody\nmore text"
                # Remove leading spaces from rest
                $bodyAndMore = $rest.TrimStart()
                
                # Remove closing </strong> from the beginning of bodyAndMore if present
                # (it might be at the end of first paragraph in <strong>)
                # Find and remove the first </strong> from bodyAndMore
                $closeIdx = $bodyAndMore.IndexOf('</strong>')
                if ($closeIdx -ge 0) {
                    # Everything before </strong> is body-in-strong, after is already outside
                    $bodyInStrong = $bodyAndMore.Substring(0, $closeIdx).Trim()
                    $afterStrong  = $bodyAndMore.Substring($closeIdx + 9).TrimStart()  # 9 = len("</strong>")
                    
                    if ($bodyInStrong.Length -gt 0) {
                        $h = $titlePart + '</strong>' + "`n" + $bodyInStrong
                        if ($afterStrong.Length -gt 0) {
                            $h = $h + "`n" + $afterStrong
                        }
                    } else {
                        # Nothing between — and </strong>
                        $h = $titlePart + '</strong>'
                        if ($afterStrong.Length -gt 0) {
                            $h = $h + "`n" + $afterStrong
                        }
                    }
                } else {
                    # No </strong> found — just add newline after title
                    $h = $titlePart + '</strong>' + "`n" + $bodyAndMore
                }
            }
            # else: em-dash is already at/near end of <strong>, or no em-dash before </strong>
        }

        # Case B (Part I style): No <strong> at all, first line is "NN. Title\n"
        # Add <strong> to the first line if no <strong> exists at all
        if (-not ($h -match '^<strong>') -and -not ($h -match '^<')) {
            $lines = $h -split "`n"
            if ($lines.Count -gt 0 -and $lines[0].Trim() -ne '') {
                $titleLine = $lines[0].Trim()
                $lines[0] = "<strong>$titleLine</strong>"
            }
            $h = [string]::Join("`n", $lines)
        }

        # Case C (Part III/IV style): <strong>अनुच्छेद N. Title-</strong>\nbody
        # This is already correct (newline after </strong>). 
        # But ensure no double newline added.
        # Just ensure </strong> is followed by \n (not space then text)
        $h = [regex]::Replace($h, '</strong> +([^\n<])', "</strong>`n`$1")

        # ----------------------------------------------------------------
        # STEP 2: Bold "sanshodhan" and put list on new line
        # ----------------------------------------------------------------
        # Current pattern: "संशोधन :\n1. text" or "संशोधन : 1. text" or "संशोधन:\n"
        # We also handle: already bolded "<strong>संशोधन</strong>"
        
        # First, un-bold if already bolded (to re-apply cleanly)
        $h = $h -replace "<strong>$([regex]::Escape($sanshodhan))</strong>", $sanshodhan

        # Now bold "संशोधन" when it appears as a section header (at line start or after \n)
        # Pattern: (start-of-string or \n) + संशोधन + optional-space + : + optional-space + digit
        # Replace संशोधन : 1.  →  <strong>संशोधन</strong> :\n1.
        $h = [regex]::Replace($h,
            "(?m)(^|\n)($([regex]::Escape($sanshodhan)))\s*:\s*(\d)",
            { param($m)
                $m.Groups[1].Value + '<strong>' + $m.Groups[2].Value + '</strong> :' + "`n" + $m.Groups[3].Value
            })

        # Also handle: संशोधन : followed by newline-then-numbers (already on next line)
        # Pattern: संशोधन :\n  — already correct, just bold it
        $h = [regex]::Replace($h,
            "(?m)(^|\n)($([regex]::Escape($sanshodhan)))\s*:\s*(`n|$)",
            { param($m)
                $m.Groups[1].Value + '<strong>' + $m.Groups[2].Value + '</strong> :' + "`n"
            })

        # ----------------------------------------------------------------
        # Apply if changed
        # ----------------------------------------------------------------
        $h = $h.Trim()
        if ($h -ne $orig.Trim()) {
            $art.hindi = $h
            $partUpdated++
            $totalUpdated++
        }
    }
    Write-Host "  Updated: $partUpdated articles"
}

Write-Host ""
Write-Host "Total updated: $totalUpdated"

# Save
$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# ---- Verify samples ----
Write-Host ""
Write-Host "=== VERIFY SAMPLES ==="
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$p1 = $verify | Where-Object {$_.partId -eq 'I'}
$a1 = $p1.articles | Where-Object {$_.id -eq '1'}
Write-Host "Part I Art 1 (first 200):"
Write-Host $a1.hindi.Substring(0,[Math]::Min(200,$a1.hindi.Length))
Write-Host ""

$p5 = $verify | Where-Object {$_.partId -eq 'V'}
$a74 = $p5.articles | Where-Object {$_.id -eq '74'}
Write-Host "Part V Art 74 (first 300):"
Write-Host $a74.hindi.Substring(0,[Math]::Min(300,$a74.hindi.Length))
Write-Host ""

$a143 = $p5.articles | Where-Object {$_.id -eq '143'}
Write-Host "Part V Art 143 (first 400 - has sanshodhan):"
Write-Host $a143.hindi.Substring(0,[Math]::Min(400,$a143.hindi.Length))
