import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()
body = root.find('{%s}body' % W)

# Let's find index of Para 46 and Para 49 in body children
para46_elem = None
para49_elem = None

# First, extract paragraphs as elements
paras_in_doc = list(root.iter('{%s}p' % W))

# Find the exact elements for Para 46 and 49
target_p46 = None
target_p49 = None
for idx, para in enumerate(root.iter('{%s}p' % W)):
    full_text = ''.join(para.itertext()).strip()
    if '60. राष्ट्रपति द्वारा शपथ' in full_text:
        target_p46 = para
    if '61. राष्ट्रपति पर महाभियोग' in full_text:
        target_p49 = para

# Now find their positions in the body children list
children = list(body)
idx_p46 = -1
idx_p49 = -1
for i, child in enumerate(children):
    # Check if this child or any sub-element of this child is target_p46/target_p49
    if target_p46 in child.iter('{%s}p' % W) or child == target_p46:
        idx_p46 = i
    if target_p49 in child.iter('{%s}p' % W) or child == target_p49:
        idx_p49 = i

print(f"Index in body: p46={idx_p46}, p49={idx_p49}")
for i in range(idx_p46, idx_p49 + 1):
    child = children[i]
    print(f"Child {i} tag: {child.tag}")
    # Print first 200 chars of text in this child
    txt = ''.join(child.itertext()).strip()
    print(f"  Text: {repr(txt[:200])}")
