
import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 english and hindi simplify .docx'
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

root = tree.getroot()

para_list = []
for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    if not runs:
        continue
    run_data = []
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and rpr.find('{%s}b' % W) is not None
            run_data.append((t.text, is_bold))
    full_text = ''.join(x[0] for x in run_data).strip()
    if full_text:
        para_list.append({'text': full_text, 'runs': run_data})

# Hindi paras are at indices 2, 5, 8, 11, 14
hindi_indices = [2, 5, 8, 11, 14]
for idx in hindi_indices:
    p = para_list[idx]
    print('=== Para', idx, '===')
    print('Full text:', p['text'][:200])
    print('Runs (text, bold):')
    for t, b in p['runs']:
        print('  [bold=' + str(b) + '] ' + repr(t))
    print()
