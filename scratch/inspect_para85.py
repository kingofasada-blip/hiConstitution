import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    if idx == 85:
        print("XML of Para 85:")
        ET.dump(para)
