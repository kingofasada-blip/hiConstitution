import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

headings = []
for idx, para in enumerate(root.iter('{%s}p' % W)):
    runs = list(para.iter('{%s}r' % W))
    if not runs: continue
    
    full_text = []
    first_bold_run_containing_art = False
    
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            full_text.append(t.text)
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            if 'अनुच्छेद' in t.text and is_bold:
                first_bold_run_containing_art = True
                
    line = ''.join(full_text).strip()
    if first_bold_run_containing_art:
        headings.append((idx, line))

print(f"Found {len(headings)} headings:")
for idx, line in headings:
    print(f"Para {idx}: {line[:120]}")
