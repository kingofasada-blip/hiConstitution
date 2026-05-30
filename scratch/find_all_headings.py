import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    runs = list(para.iter('{%s}r' % W))
    if not runs: continue
    full_text = []
    first_bold = False; first_checked = False
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            if not first_checked and t.text.strip():
                first_bold = is_bold; first_checked = True
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if line and first_bold:
        print(f"Para {idx}: {line[:120]}")
