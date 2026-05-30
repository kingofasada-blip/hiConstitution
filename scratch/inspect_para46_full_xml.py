import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

for idx, para in enumerate(root.iter('{%s}p' % W)):
    full_text = ''.join(para.itertext()).strip()
    if '60. राष्ट्रपति द्वारा शपथ' in full_text:
        print(f"Para {idx} XML:")
        ET.dump(para)
        break
