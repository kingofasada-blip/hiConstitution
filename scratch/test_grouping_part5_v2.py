import zipfile, sys, io, re, json
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def extract_paras(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    
    heading_pat = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*(\d+[क-हA-Za-z]*)\.')
    
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        full_text = []
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if not line: continue
        
        is_heading = False
        m = heading_pat.match(line)
        if m:
            art_num = m.group(1)
            for r in runs:
                t = r.find('{%s}t' % W)
                if t is not None and t.text and art_num in t.text:
                    rpr = r.find('{%s}rPr' % W)
                    is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
                    if is_bold:
                        is_heading = True
                        break
        
        is_amendment = False
        if line.strip().rstrip(':') == 'संशोधन':
            for r in runs:
                t = r.find('{%s}t' % W)
                if t is not None and t.text and 'संशोधन' in t.text:
                    rpr = r.find('{%s}rPr' % W)
                    is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
                    if is_bold:
                        is_amendment = True
                        break
                        
        para_list.append({
            'text': line,
            'is_heading': is_heading,
            'heading_key': m.group(1) if is_heading else None,
            'is_amendment': is_amendment
        })
    return para_list

def map_suffix(key):
    mapping = {'क': 'A', 'ख': 'B', 'ग': 'C', 'घ': 'D'}
    for k, v in mapping.items():
        key = key.replace(k, v)
    return key

def group_by_article(paras):
    articles = {}
    order = []
    current = None
    for idx, p in enumerate(paras):
        if p['is_heading']:
            key = p['heading_key']
            key = map_suffix(key)
            current = key
            if key not in articles:
                articles[key] = []; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx'
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)
print(f"Total articles grouped: {len(art_order)}")
print("Missing from expected 107:")
with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
part5_json = next(p for p in data if p.get('partId') == 'V')
json_ids = [a['id'] for a in part5_json['articles']]
missing = [jid for jid in json_ids if jid not in art_order]
print(missing)
