import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    if 45 <= idx <= 50:
        full_text = []
        for r in para.iter('{%s}r' % W):
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                full_text.append(t.text)
        print(f"Para {idx}: {''.join(full_text).strip()}")
