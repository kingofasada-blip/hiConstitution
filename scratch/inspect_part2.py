
import zipfile, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def extract_paras_with_bold(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs:
            continue
        full_text = []
        first_bold = False
        first_checked = False
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                rpr = r.find('{%s}rPr' % W)
                is_bold = rpr is not None and rpr.find('{%s}b' % W) is not None
                if not first_checked and t.text.strip():
                    first_bold = is_bold
                    first_checked = True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text': line, 'bold': first_bold})
    return para_list

# Original
orig = extract_paras_with_bold(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 2 hindi original.docx')
print('=== ORIGINAL PARAGRAPHS ===')
for i, p in enumerate(orig):
    print(str(i) + ' [bold=' + str(p['bold']) + ']: ' + p['text'][:120])

# Simplify
simp = extract_paras_with_bold(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 2 english and hindi simplify .docx')
print('\n=== SIMPLIFY PARAGRAPHS ===')
for i, p in enumerate(simp):
    print(str(i) + ' [bold=' + str(p['bold']) + ']: ' + p['text'][:120])
