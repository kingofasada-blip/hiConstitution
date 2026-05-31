import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

def dump_headings(docx_path, name):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return
    
    print(f"\n==================== Headings in {name} ====================")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    for idx, para in enumerate(root.iter('{%s}p' % W)):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        
        run_texts = []
        is_bold_para = False
        for r in runs:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            if is_bold:
                is_bold_para = True
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
        
        full_text = "".join(run_texts).strip()
        if not full_text:
            continue
        
        # Check if first word starts with U+185 (superscript 1) or numbers or bracket
        first_15 = full_text[:15]
        # Regex to match: optional superscript/footnote markers, bracket, then number 243, optionally followed by Hindi letters
        # Hindi letter range: \u0900-\u097F
        match = re.match(r'^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*)?(\d+[\u0900-\u097F]*)\b', first_15)
        if match:
            print(f"Para {idx}: '{full_text}' (Matches key: {match.group(1)})")
        elif is_bold_para and ('भाग' in full_text or 'अध्याय' in full_text):
            print(f"Para {idx} (Title/Header): '{full_text}'")

dump_headings(os.path.join(BASE_DIR, 'part 9 original hindi.docx'), "Part 9")
dump_headings(os.path.join(BASE_DIR, 'part 9A original hindi.docx'), "Part 9A")
dump_headings(os.path.join(BASE_DIR, 'part 9B original hindi.docx'), "Part 9B")
