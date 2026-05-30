import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 4 hindi original .docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

count = 0
for idx, para in enumerate(root.iter('{%s}p' % W)):
    runs = list(para.iter('{%s}r' % W))
    if not runs: continue
    full_text = []
    bold_runs = []
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            full_text.append(t.text)
            if is_bold:
                bold_runs.append(t.text)
    line = ''.join(full_text).strip()
    if line:
        print(f"Para {idx} (bold={len(bold_runs) > 0}): {line[:120]}")
        if bold_runs:
            print(f"   Bold runs: {bold_runs}")
        count += 1
    if count >= 30:
        break
