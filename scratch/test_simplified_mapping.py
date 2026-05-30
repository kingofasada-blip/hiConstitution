import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def extract_paras(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        full_text = []
        first_bold = False; first_checked = False
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                rpr = r.find('{%s}rPr' % W)
                is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
                if not first_checked and t.text.strip():
                    first_bold = is_bold; first_checked = True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text': line, 'bold': first_bold})
    return para_list

simp_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 english and hindi simplify.docx'
simp_paras = extract_paras(simp_path)

simp_groups = {}  # art_id -> hindi_text
i = 0
while i < len(simp_paras):
    p = simp_paras[i]
    if p['bold'] and ('Article' in p['text'] or 'अनुच्छेद' in p['text']):
        # Split on '/' to get English part
        parts = p['text'].split('/')
        english_part = parts[0]
        # Find all keys like "12", "21A", "31A", "31B", etc.
        art_keys = re.findall(r'(\d+[A-Za-z]*)', english_part)
        
        # Next para = English explanation, para after = Hindi explanation
        en_idx = i + 1
        hi_idx = i + 2
        if hi_idx < len(simp_paras):
            hi_text = simp_paras[hi_idx]['text']
            for k in art_keys:
                simp_groups[k.upper()] = hi_text
        i += 3
        continue
    i += 1

print(f"Extracted {len(simp_groups)} simplified Hindi articles:")
for k, v in sorted(simp_groups.items(), key=lambda x: (int(re.match(r'\d+', x[0]).group()), x[0])):
    print(f"Art {k}: {v[:80]}...")
