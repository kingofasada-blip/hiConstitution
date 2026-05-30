import zipfile
import xml.etree.ElementTree as ET
import sys
import io

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def extract_para_runs(para):
    runs_data = []
    for r in para.iter('{%s}r' % W):
        rpr = r.find('{%s}rPr' % W)
        is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
        
        run_parts = []
        for child in r:
            if child.tag == '{%s}t' % W:
                if child.text:
                    run_parts.append(child.text)
            elif child.tag == '{%s}br' % W:
                run_parts.append('\n')
            elif child.tag == '{%s}tab' % W:
                run_parts.append('\t')
        
        run_text = ''.join(run_parts)
        if run_text:
            runs_data.append({'text': run_text, 'bold': is_bold})
            
    full_text = ''.join(r['text'] for r in runs_data)
    return full_text, runs_data

with zipfile.ZipFile('part 8 original hindi.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

with open('scratch/part8_original_hindi_dump.txt', 'w', encoding='utf-8') as out:
    count = 0
    for para in root.iter('{%s}p' % W):
        full_text, runs_data = extract_para_runs(para)
        text_strip = full_text.strip()
        if not text_strip:
            continue
        count += 1
        out.write(f"P{count}:\n")
        out.write(f"  Raw: {text_strip}\n")
        out.write(f"  Runs: {[(r['text'], r['bold']) for r in runs_data]}\n\n")

print(f"Dumped {count} paragraphs to scratch/part8_original_hindi_dump.txt")
