import zipfile
import xml.etree.ElementTree as ET
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

out = []

def inspect_sanshodhan(docx_path, name):
    if not os.path.exists(docx_path):
        out.append(f"{name}: File not found\n")
        return
    
    out.append(f"\n==================== Context in {name} ====================\n")
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    paras = []
    for para in root.iter('{%s}p' % W):
        run_texts = []
        for r in para.iter('{%s}r' % W):
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
        text = "".join(run_texts).strip()
        if text:
            paras.append(text)
            
    for idx, text in enumerate(paras):
        if "संशोधन" in text:
            out.append(f"Match at Para {idx}: '{text}'\n")
            start = max(0, idx - 2)
            end = min(len(paras), idx + 3)
            for j in range(start, end):
                marker = "--> " if j == idx else "    "
                out.append(f"{marker}Para {j}: '{paras[j]}'\n")

inspect_sanshodhan(os.path.join(BASE_DIR, 'part 9 original hindi.docx'), "Part 9 Original")
inspect_sanshodhan(os.path.join(BASE_DIR, 'part 9A original hindi.docx'), "Part 9A Original")
inspect_sanshodhan(os.path.join(BASE_DIR, 'part 9B original hindi.docx'), "Part 9B Original")

with open(os.path.join(BASE_DIR, "scratch", "sanshodhan_matches.txt"), "w", encoding="utf-8") as f:
    f.writelines(out)
