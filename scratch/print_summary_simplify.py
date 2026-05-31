import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

def check_keys_in_file(docx_path):
    if not os.path.exists(docx_path):
        return "Not Found"
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    keys = []
    for para in root.iter('{%s}p' % W):
        run_texts = []
        for r in para.iter('{%s}r' % W):
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
        text = "".join(run_texts).strip()
        if text.startswith('Article'):
            art_keys = re.findall(r'(\d+[A-Za-z]*)', text)
            keys.extend(art_keys)
    return keys

p9_keys = check_keys_in_file(os.path.join(BASE_DIR, 'part 9 simplify  hindi and english.docx'))
p9a_keys = check_keys_in_file(os.path.join(BASE_DIR, 'part 9A simplify  hindi and english.docx'))
p9b_keys = check_keys_in_file(os.path.join(BASE_DIR, 'part 9B simplify  hindi and english.docx'))

print("Part 9 Simplify keys:", p9_keys)
print("Part 9A Simplify keys:", p9a_keys)
print("Part 9B Simplify keys:", p9b_keys)
