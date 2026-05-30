
import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx','r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

# Check first 20 paragraphs for bold patterns
count = 0
for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    if not runs: continue
    full_text=[]
    bold_flags=[]
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            b_elem = rpr.find('{%s}b' % W) if rpr is not None else None
            # Also check bCs (bold complex script for Hindi)
            bCs_elem = rpr.find('{%s}bCs' % W) if rpr is not None else None
            is_bold = b_elem is not None or bCs_elem is not None
            bold_flags.append(is_bold)
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if line:
        any_bold = any(bold_flags)
        first_bold = bold_flags[0] if bold_flags else False
        print(str(count)+' [any_bold='+str(any_bold)+' first='+str(first_bold)+']: '+line[:100])
        count += 1
    if count >= 25:
        break
