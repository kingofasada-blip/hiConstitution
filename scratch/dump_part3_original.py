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

def group_by_article(paras):
    art_start_re = re.compile(r'^(\d+[^\s.\u2013\-]*)\.')
    articles = {}   # key -> list of para dicts
    order = []
    current = None
    for p in paras:
        # We match start of paragraph text with "Article number." e.g. "12." or "31क."
        m = art_start_re.match(p['text'])
        # A heading line should have bold = True and match the regex
        if p['bold'] and m:
            key = m.group(1)
            current = key
            if key not in articles:
                articles[key] = []; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx'
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)
print("Articles found in original:", art_order)

for key in art_order[:5]:
    print(f"\n--- Article {key} ---")
    for idx, p in enumerate(art_groups[key]):
        print(f"[{idx}] bold={p['bold']}: {p['text'][:150]}")
