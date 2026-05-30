import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

# Regex to match footnote/brackets and "अनुच्छेद [number]"
heading_pat = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*अनुच्छेद\s+(\d+[क-हA-Za-z]*)')

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    full_text = []
    has_bold = False
    for r in para.iter('{%s}r' % W):
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            if is_bold:
                has_bold = True
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    m = heading_pat.match(line)
    if m:
        print(f"Para {idx} (has_bold={has_bold}, group={m.group(1)}): {line}")
