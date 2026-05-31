import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

out = []

def inspect_file(docx_path, name):
    if not os.path.exists(docx_path):
        out.append(f"File not found: {docx_path}\n")
        return
        
    out.append(f"\n==================== {name} ({os.path.basename(docx_path)}) ====================\n")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    count = 0
    for para in root.iter('{%s}p' % W):
        run_texts = []
        runs_info = []
        for r in para.iter('{%s}r' % W):
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
                runs_info.append(f"[{t.text}]({'bold' if is_bold else 'plain'})")
        
        full_text = "".join(run_texts).strip()
        if full_text:
            out.append(f"Para {count}: '{full_text}'\nRuns: {' '.join(runs_info)}\n\n")
            count += 1

inspect_file(os.path.join(BASE_DIR, 'part9b_extracted_docx', 'part 10 original hindi and english.docx'), "Part 10 Original")
inspect_file(os.path.join(BASE_DIR, 'part9b_extracted_docx', 'part 10 simplify  hindi and english.docx'), "Part 10 Simplify")

with open(os.path.join(BASE_DIR, 'scratch', 'part10_inspect.txt'), 'w', encoding='utf-8') as f:
    f.writelines(out)

print("Saved inspection details to scratch/part10_inspect.txt")
