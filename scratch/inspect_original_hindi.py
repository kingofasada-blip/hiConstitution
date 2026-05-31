import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

def extract_original_docx_headers(docx_path):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return
    
    print(f"\n==================== Headers in {os.path.basename(docx_path)} ====================")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    # We want to see how headings are structured
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
        if not full_text:
            continue
        
        # Print if it looks like a heading or has bold run at the beginning
        # Typically headings in original Hindi:
        # starts with numbers, superscripts, brackets, or "भाग", "अनुच्छेद"
        is_suspicious_heading = False
        if any(c in full_text[:10] for c in ['[', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '⁰']):
            is_suspicious_heading = True
        elif re.match(r'^\d', full_text):
            is_suspicious_heading = True
        elif 'अनुच्छेद' in full_text[:15] or 'भाग' in full_text[:10]:
            is_suspicious_heading = True
            
        if is_suspicious_heading or (runs_data and runs_data[0][1]):
            print(f"Text: '{full_text}'")
            print(f"Runs: {runs_data[:4]} ...")

original_files = [
    os.path.join(BASE_DIR, 'part 9 original hindi.docx'),
    os.path.join(BASE_DIR, 'part 9A original hindi.docx'),
    os.path.join(BASE_DIR, 'part 9B original hindi.docx')
]

for fp in original_files:
    extract_original_docx_headers(fp)
