import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

def print_headers(docx_path, name):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return
    print(f"\n==================== Headers in {name} ====================")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    for para in root.iter('{%s}p' % W):
        run_texts = []
        for r in para.iter('{%s}r' % W):
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
        text = "".join(run_texts).strip()
        if text.startswith('Article'):
            print(f"  Header: '{text}'")

print_headers(os.path.join(BASE_DIR, 'part 9 simplify  hindi and english.docx'), "Part 9 Simplify")
print_headers(os.path.join(BASE_DIR, 'part 9A simplify  hindi and english.docx'), "Part 9A Simplify")
print_headers(os.path.join(BASE_DIR, 'part 9B simplify  hindi and english.docx'), "Part 9B Simplify")
