$jsonPath = "C:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json"
$data = Get-Content -Raw -Encoding UTF8 $jsonPath | ConvertFrom-Json
$part3 = $data | Where-Object { $_.partId -eq 'III' }

foreach ($a in $part3.articles) {
    $hindi = $a.hindi
    if ($null -eq $hindi -or [string]::IsNullOrWhiteSpace($hindi)) {
        continue
    }

    if ($a.id -eq '13') {
        $hindi = $hindi -replace '\(4\) इस अनुच्छेद की कोई बात', '¹[(4) इस अनुच्छेद की कोई बात'
    }
    elseif ($a.id -eq '15') {
        $hindi = $hindi -replace '\(4\) इस अनुच्छेद की या अनुच्छेद 29', '¹[(4) इस अनुच्छेद की या अनुच्छेद 29'
        $hindi = $hindi -replace '\(5\) इस अनुच्छेद या अनुच्छेद 19', '²[(5) इस अनुच्छेद या अनुच्छेद 19'
        $hindi = $hindi -replace '\(6\) इस अनुच्छेद या अनुच्छेद 19', '³[(6) इस अनुच्छेद या अनुच्छेद 19'
    }
    elseif ($a.id -eq '16') {
        $hindi = $hindi -replace '<sup>1</sup>', '¹'
        $hindi = $hindi -replace '\(4क\) इस अनुच्छेद की कोई बात', '²[(4क) इस अनुच्छेद की कोई बात'
        $hindi = $hindi -replace '<sup>3</sup>', '³'
        $hindi = $hindi -replace '\(4ख\) इस अनुच्छेद की कोई बात', '⁴[(4ख) इस अनुच्छेद की कोई बात'
        $hindi = $hindi -replace '\(6\) इस अनुच्छेद की कोई बात', '⁵[(6) इस अनुच्छेद की कोई बात'
    }
    elseif ($a.id -eq '19') {
        $hindi = $hindi -replace '<sup>1</sup>', '¹'
        $hindi = $hindi -replace '<sup>2</sup>', '²'
        $hindi = $hindi -replace '\(च\)\* \* \* \* \*\]', '³[(च)* * * * *]'
        $hindi = $hindi -replace '\(2\) खंड \(1\) के', '⁴[(2) खंड (1) के'
        $hindi = $hindi -replace '<sup>5</sup>', '⁵'
        $hindi = $hindi -replace '<sup>6</sup>', '⁶'
        $hindi = $hindi -replace '<sup>7</sup>', '⁷'
    }
    elseif ($a.id -eq '21A') {
        $hindi = $hindi -replace '<strong>अनुच्छेद 21क\. शिक्षा का अधिकार-</strong>', '<strong>¹[अनुच्छेद 21क. शिक्षा का अधिकार-</strong>'
    }
    elseif ($a.id -eq '22') {
        $hindi = $hindi -replace '\(4\) निवारक निरोध का', '¹[(4) निवारक निरोध का'
        $hindi = $hindi -replace '\(क\) ऐसे व्यक्तियों से', '²[(क) ऐसे व्यक्तियों से'
        $hindi = $hindi -replace '\(ख\) ऐसे व्यक्ति को खंड', '³[(ख) ऐसे व्यक्ति को खंड'
        
        # Clause 7 subclauses:
        # (क) किन परिस्थितियों के अधीन... advisor board की राय प्राप्त किए बिना निरुद्ध किया जा सकेगा;
        # We need to prepend ²[ to (क) and add ] at the end of (क)'s sentence
        $hindi = $hindi -replace '\(क\) किन परिस्थितियों के अधीन और किस वर्ग या वर्गों के मामलों में किसी व्यक्ति को निवारक निरोध का उपबंध करने वाली किसी विधि के अधीन तीन मास से अधिक अवधि के लिए खंड \(4\) के उपखंड \(क\) के उपबंधों के अनुसार सलाहकार बोर्ड की राय प्राप्त किए बिना निरुद्ध किया जा सकेगा;', '²[(क) किन परिस्थितियों के अधीन और किस वर्ग या वर्गों के मामलों में किसी व्यक्ति को निवारक निरोध का उपबंध करने वाली किसी विधि के अधीन तीन मास से अधिक अवधि के लिए खंड (4) के उपखंड (क) के उपबंधों के अनुसार सलाहकार बोर्ड की राय प्राप्त किए बिना निरुद्ध किया जा सकेगा;]'
        
        # (ख) किसी वर्ग या वर्गों के मामलों में कितनी अधिकतम अवधि... निरुद्ध किया जा सकेगा; और
        # We need to prepend ³[ and add ] before "और"
        $hindi = $hindi -replace '\(ख\) किसी वर्ग या वर्गों के मामलों में कितनी अधिकतम अवधि के लिए किसी व्यक्ति को निवारक निरोध का उपबंध करने वाली किसी विधि के अधीन निरुद्ध किया जा सकेगा; और', '³[(ख) किसी वर्ग या वर्गों के मामलों में कितनी अधिकतम अवधि के लिए किसी व्यक्ति को निवारक निरोध का उपबंध करने वाली किसी विधि के अधीन निरुद्ध किया जा सकेगा;] और'
        
        # (ग) <sup>5</sup>****[खंड... प्रक्रिया क्या होगी ।
        # Change to ⁴[(ग) ⁵****[खंड... प्रक्रिया क्या होगी ।]
        $hindi = $hindi -replace '\(ग\) <sup>5</sup>\*\*\*\*\[खंड \(4\) के उपखंड \(क\)\] के अधीन की जाने वाली जांच में सलाहकार बोर्ड द्वारा अनुसरण की जाने वाली प्रक्रिया क्या होगी ।', '⁴[(ग) ⁵****[खंड (4) के उपखंड (क)] के अधीन की जाने वाली जांच में सलाहकार बोर्ड द्वारा अनुसरण की जाने वाली प्रक्रिया क्या होगी ।]'
    }
    elseif ($a.id -eq '31A') {
        $hindi = $hindi -replace '<strong>अनुच्छेद 31क\. संपदाओं', '<strong>²[अनुच्छेद 31क. संपदाओं'
        $hindi = $hindi -replace '\(1\) अनुच्छेद 13', '³[(1) अनुच्छेद 13'
        $hindi = $hindi -replace '<sup>2</sup>', '⁴'
        $hindi = $hindi -replace 'परंतु यह और कि', '⁵[परंतु यह और कि'
        $hindi = $hindi -replace '\(क\) “संपदा"', '⁶[(क) “संपदा"'
        $hindi = $hindi -replace '<sup>4</sup>', '⁷'
        $hindi = $hindi -replace '<sup>6</sup>', '⁸'
    }
    elseif ($a.id -eq '31B') {
        $hindi = $hindi -replace '<strong>अनुच्छेद 31ख\. कुछ', '<strong>¹[अनुच्छेद 31ख. कुछ'
    }
    elseif ($a.id -eq '31C') {
        $hindi = $hindi -replace '<strong>अनुच्छेद 31ग\. कुछ', '<strong>¹[अनुच्छेद 31ग. कुछ'
        $hindi = $hindi -replace '<sup>2</sup>', '²'
        $hindi = $hindi -replace '<sup>3</sup>', '³'
        $hindi = $hindi -replace '<sup>4</sup>', '⁴'
    }
    elseif ($a.id -eq '31D') {
        $hindi = $hindi -replace 'अनुच्छेद 31घ\. \[राष्ट्र', '¹अनुच्छेद 31घ. [राष्ट्र'
    }
    elseif ($a.id -eq '33') {
        $hindi = $hindi -replace 'अनुच्छेद 33\. इस भाग द्वारा', '¹[अनुच्छेद 33. इस भाग द्वारा'
    }

    $a.hindi = $hindi
}

# Save updated JSON using UTF-8 encoding
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonOut = ConvertTo-Json -InputObject $data -Depth 16
[System.IO.File]::WriteAllText($jsonPath, $jsonOut, $utf8NoBom)

Write-Output "Updates applied."
