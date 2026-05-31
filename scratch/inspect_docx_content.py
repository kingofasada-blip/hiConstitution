import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

def extract_first_n_paras(docx_path, n=50):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return
    
    print(f"\n==================== {os.path.basename(docx_path)} (First {n} paragraphs) ====================")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    count = 0
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        
        run_texts = []
        runs_data = []
        for r in runs:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
                runs_data.append((t.text, is_bold))
        
        full_text = "".join(run_texts).strip()
        if full_text:
            print(f"Para {count}: '{full_text}'")
            print(f"Runs: {runs_data}")
            count += 1
            if count >= n:
                break

# Let's inspect original and simplify docx for Part 9, 9A, 9B
files_to_inspect = [
    os.path.join(BASE_DIR, 'part 9 original hindi.docx'),
    os.path.join(BASE_DIR, 'part 9 simplify  hindi and english.docx'),
    os.path.join(BASE_DIR, 'part 9A original hindi.docx'),
    os.path.join(BASE_DIR, 'part 9A simplify  hindi and english.docx'),
    os.path.join(BASE_DIR, 'part 9B original hindi.docx'),
    os.path.join(BASE_DIR, 'part 9B simplify  hindi and english.docx')
]

for fp in files_to_inspect:
    extract_first_n_paras(fp, n=20)
