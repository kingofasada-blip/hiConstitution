
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 hindi original.docx'

# ── Extract paragraphs WITH bold info ──────────────────────────────────
with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

root = tree.getroot()
paragraphs = []  # list of (text, is_bold_start)

for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    if not runs:
        continue
    full_text = []
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if line:
        paragraphs.append(line)

# Show all paragraphs
for i, p in enumerate(paragraphs):
    print(str(i) + ': ' + p[:120])
