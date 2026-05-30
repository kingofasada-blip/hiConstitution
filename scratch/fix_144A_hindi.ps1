# Fix 144A hindi field - using Unicode escapes to avoid encoding issues
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = 'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$json = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$part5idx = -1
for ($i = 0; $i -lt $json.Count; $i++) {
    if ($json[$i].partId -eq 'V') { $part5idx = $i; break }
}

$art144A = $json[$part5idx].articles | Where-Object { $_.id -eq '144A' }

# Build hindi text using char codes to avoid encoding issues in script file
# The text: '<strong>'[144क. [विधियों की सांविधानिक वैधता से संबंधित प्रश्नों के निपटारे के बारे में विशेष उपबंध।]</strong>—संविधान (तैंतालीसवां संशोधन) अधिनियम, 1977 की धारा 5 द्वारा (13-4-1978 से) लोप किया गया।\nसंशोधन : 1. संविधान (बयालीसवां संशोधन) अधिनियम, 1976 की धारा 25 द्वारा (1-2-1977 से) अंतःस्थापित।

$correctHindi = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes(
    "<strong>'[144" + [char]0x0915 + [char]0x093C + ". [" +
    [char]0x0935 + [char]0x093F + [char]0x0927 + [char]0x093F + [char]0x092F + [char]0x094B + [char]0x0902 + " " +
    [char]0x0915 + [char]0x0940 + " " +
    [char]0x0938 + [char]0x093E + [char]0x0902 + [char]0x0935 + [char]0x093F + [char]0x0927 + [char]0x093E + [char]0x0928 + [char]0x093F + [char]0x0915 + " " +
    [char]0x0935 + [char]0x0948 + [char]0x0927 + [char]0x0924 + [char]0x093E + " " +
    [char]0x0938 + [char]0x0947 + " " +
    [char]0x0938 + [char]0x0902 + [char]0x092C + [char]0x0902 + [char]0x0927 + [char]0x093F + [char]0x0924 + " " +
    [char]0x092A + [char]0x094D + [char]0x0930 + [char]0x0936 + [char]0x094D + [char]0x0928 + [char]0x094B + [char]0x0902 + " " +
    [char]0x0915 + [char]0x0947 + " " +
    [char]0x0928 + [char]0x093F + [char]0x092A + [char]0x091F + [char]0x093E + [char]0x0930 + [char]0x0947 + " " +
    [char]0x0915 + [char]0x0947 + " " +
    [char]0x092C + [char]0x093E + [char]0x0930 + [char]0x0947 + " " +
    [char]0x092E + [char]0x0947 + [char]0x0902 + " " +
    [char]0x0935 + [char]0x093F + [char]0x0936 + [char]0x0947 + [char]0x0937 + " " +
    [char]0x0909 + [char]0x092A + [char]0x092C + [char]0x0902 + [char]0x0927 + [char]0x0964 +
    "]</strong>" + [char]0x2014 +
    [char]0x0938 + [char]0x0902 + [char]0x0935 + [char]0x093F + [char]0x0927 + [char]0x093E + [char]0x0928 + " (" +
    [char]0x0924 + [char]0x0948 + [char]0x0902 + [char]0x0924 + [char]0x093E + [char]0x0932 + [char]0x0940 + [char]0x0938 + [char]0x0935 + [char]0x093E + [char]0x0902 + " " +
    [char]0x0938 + [char]0x0902 + [char]0x0936 + [char]0x094B + [char]0x0927 + [char]0x0928 + ") " +
    [char]0x0905 + [char]0x0927 + [char]0x093F + [char]0x0928 + [char]0x093F + [char]0x092F + [char]0x092E + ", 1977 " +
    [char]0x0915 + [char]0x0940 + " " +
    [char]0x0927 + [char]0x093E + [char]0x0930 + [char]0x093E + " 5 " +
    [char]0x0926 + [char]0x094D + [char]0x0935 + [char]0x093E + [char]0x0930 + [char]0x093E + " (13-4-1978 " +
    [char]0x0938 + [char]0x0947 + ") " +
    [char]0x0932 + [char]0x094B + [char]0x092A + " " +
    [char]0x0915 + [char]0x093F + [char]0x092F + [char]0x093E + " " +
    [char]0x0917 + [char]0x092F + [char]0x093E + [char]0x0964 +
    "`n" +
    [char]0x0938 + [char]0x0902 + [char]0x0936 + [char]0x094B + [char]0x0927 + [char]0x0928 + " : 1. " +
    [char]0x0938 + [char]0x0902 + [char]0x0935 + [char]0x093F + [char]0x0927 + [char]0x093E + [char]0x0928 + " (" +
    [char]0x092C + [char]0x092F + [char]0x093E + [char]0x0932 + [char]0x0940 + [char]0x0938 + [char]0x0935 + [char]0x093E + [char]0x0902 + " " +
    [char]0x0938 + [char]0x0902 + [char]0x0936 + [char]0x094B + [char]0x0927 + [char]0x0928 + ") " +
    [char]0x0905 + [char]0x0927 + [char]0x093F + [char]0x0928 + [char]0x093F + [char]0x092F + [char]0x092E + ", 1976 " +
    [char]0x0915 + [char]0x0940 + " " +
    [char]0x0927 + [char]0x093E + [char]0x0930 + [char]0x093E + " 25 " +
    [char]0x0926 + [char]0x094D + [char]0x0935 + [char]0x093E + [char]0x0930 + [char]0x093E + " (1-2-1977 " +
    [char]0x0938 + [char]0x0947 + ") " +
    [char]0x0905 + [char]0x0902 + [char]0x0924 + [char]0x0903 + [char]0x0938 + [char]0x094D + [char]0x0925 + [char]0x093E + [char]0x092A + [char]0x093F + [char]0x0924 + [char]0x0964
))

$art144A.hindi = $correctHindi
Write-Host "Set 144A hindi:" $art144A.hindi.Length "chars"

$jsonOut = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)
Write-Host "Saved!"

# Verify
$verify = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$p5v = $verify | Where-Object { $_.partId -eq 'V' }
$a144A = $p5v.articles | Where-Object { $_.id -eq '144A' }
Write-Host "144A hindi verified:" $a144A.hindi.Length "chars"
$a143 = $p5v.articles | Where-Object { $_.id -eq '143' }
Write-Host "143 hindi intact:" $a143.hindi.Length "chars"
$a145 = $p5v.articles | Where-Object { $_.id -eq '145' }
Write-Host "145 hindi intact:" $a145.hindi.Length "chars"
