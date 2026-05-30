import zipfile
import xml.etree.ElementTree as ET
import sys
import io

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def extract_para_text(para):
    run_parts = []
    for r in para.iter('{%s}r' % W):
        for child in r:
            if child.tag == '{%s}t' % W:
                if child.text:
                    run_parts.append(child.text)
            elif child.tag == '{%s}br' % W:
                run_parts.append('\n')
            elif child.tag == '{%s}tab' % W:
                run_parts.append('\t')
    return ''.join(run_parts).strip()

with zipfile.ZipFile('Part 8 - Simplified english and hindi.docx', 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)
root = tree.getroot()

with open('scratch/part8_simplified_dump.txt', 'w', encoding='utf-8') as out:
    count = 0
    for para in root.iter('{%s}p' % W):
        text = extract_para_text(para)
        if not text:
            continue
        count += 1
        out.write(f"P{count}: {text}\n\n")

print(f"Dumped {count} paragraphs to scratch/part8_simplified_dump.txt")
