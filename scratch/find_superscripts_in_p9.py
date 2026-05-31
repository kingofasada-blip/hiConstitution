import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5','⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

def check_file(docx_path, name):
    if not os.path.exists(docx_path):
        print(f"{name}: File not found")
        return
    
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    found_sups = {}
    found_amend = False
    for idx, para in enumerate(root.iter('{%s}p' % W)):
        run_texts = []
        for r in para.iter('{%s}r' % W):
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
        text = "".join(run_texts).strip()
        if not text:
            continue
        
        for c in text:
            if c in SUPER_CHARS:
                found_sups[c] = found_sups.get(c, 0) + 1
        if "संशोधन" in text:
            found_amend = True
            
    print(f"\n==================== {name} ====================")
    print(f"Superscripts found: {found_sups}")
    print(f"Contains 'संशोधन': {found_amend}")

check_file(os.path.join(BASE_DIR, 'part 9 original hindi.docx'), "Part 9 Original")
check_file(os.path.join(BASE_DIR, 'part 9A original hindi.docx'), "Part 9A Original")
check_file(os.path.join(BASE_DIR, 'part 9B original hindi.docx'), "Part 9B Original")
