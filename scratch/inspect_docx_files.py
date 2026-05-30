import zipfile
import xml.etree.ElementTree as ET
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
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

def inspect_docx(docx_path, name, limit=30):
    print(f"\n===== Inspecting {name} ({docx_path}) =====")
    try:
        with zipfile.ZipFile(docx_path, 'r') as z:
            with z.open('word/document.xml') as f:
                tree = ET.parse(f)
        root = tree.getroot()
    except Exception as e:
        print(f"Error opening: {e}")
        return
        
    count = 0
    for i, para in enumerate(root.iter('{%s}p' % W)):
        full_text, runs_data = extract_para_runs(para)
        text_strip = full_text.strip()
        if not text_strip:
            continue
        count += 1
        if count <= limit:
            print(f"P{count} (Index {i}):")
            print(f"  Raw: {repr(text_strip)}")
            print(f"  Runs: {[(r['text'], r['bold']) for r in runs_data]}")
    print(f"Total non-empty paragraphs: {count}")

inspect_docx('part 8 original hindi.docx', 'Part 8 Original Hindi')
inspect_docx('Part 8 - Simplified english and hindi.docx', 'Part 8 Simplified English and Hindi')
