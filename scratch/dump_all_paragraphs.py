import zipfile
import xml.etree.ElementTree as ET
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def dump_all_paras(docx_path, out_path):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return
    
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    lines = []
    for idx, para in enumerate(root.iter('{%s}p' % W)):
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
            lines.append(f"Para {idx}: {full_text}\nRuns: {' '.join(runs_info)}\n\n")
            
    with open(out_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"Dumped {len(lines)} paras from {os.path.basename(docx_path)} to {out_path}")

dump_all_paras(os.path.join(BASE_DIR, 'part 9 original hindi.docx'), os.path.join(BASE_DIR, 'scratch', 'part9_original_all.txt'))
dump_all_paras(os.path.join(BASE_DIR, 'part 9A original hindi.docx'), os.path.join(BASE_DIR, 'scratch', 'part9a_original_all.txt'))
dump_all_paras(os.path.join(BASE_DIR, 'part 9B original hindi.docx'), os.path.join(BASE_DIR, 'scratch', 'part9b_original_all.txt'))
