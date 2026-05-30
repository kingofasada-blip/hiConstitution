import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

found = 0
for idx, para in enumerate(root.iter('{%s}p' % W)):
    txt = ''.join(para.itertext()).strip()
    if 'ईश्वर' in txt or 'सत्यनिष्ठा' in txt or 'श्रद्धापूर्वक' in txt:
        print(f"Para {idx}: {txt[:120]}")
        found += 1

print(f"Total matching paragraphs: {found}")
