import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    full_text = []
    for r in para.iter('{%s}r' % W):
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if '21' in line or '२१' in line or 'क' in line:
        # Just search for 21 or 21क or similar near para 83-90
        if 80 <= idx <= 95:
            print(f"Para {idx}: {line}")
