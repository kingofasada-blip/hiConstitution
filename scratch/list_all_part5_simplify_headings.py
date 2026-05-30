import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\Part 5 - Simplified english and hindi.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

headings = []
for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    if not runs: continue
    full_text = ''.join(r.find('{%s}t' % W).text for r in runs if r.find('{%s}t' % W) is not None and r.find('{%s}t' % W).text).strip()
    if full_text.startswith('Article'):
        headings.append(full_text)

print(f"Total headings found in simplified docx: {len(headings)}")
print("Combined headings (with commas, 'and', or multiple numbers):")
for h in headings:
    # Check if there are multiple numbers or combined keywords
    nums = re.findall(r'\d+', h)
    if len(nums) > 1:
        print(h)
