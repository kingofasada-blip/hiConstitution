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
        has_bold_art = False
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                rpr = r.find('{%s}rPr' % W)
                is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
                if 'अनुच्छेद' in t.text and is_bold:
                    has_bold_art = True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text': line, 'bold_art': has_bold_art})
    return para_list

def map_suffix(key):
    mapping = {'क': 'A', 'ख': 'B', 'ग': 'C', 'घ': 'D'}
    for k, v in mapping.items():
        key = key.replace(k, v)
    return key

def group_by_article(paras):
    heading_pat = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*अनुच्छेद\s+(\d+[क-हA-Za-z]*)')
    articles = {}
    order = []
    current = None
    for idx, p in enumerate(paras):
        m = heading_pat.match(p['text'])
        is_heading = False
        if m and p['bold_art']:
            is_heading = True
            
        if is_heading:
            key = m.group(1)
            key = map_suffix(key)
            current = key
            if key not in articles:
                articles[key] = []; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

def split_title_body(text):
    text = text.strip()
    # Prioritize dash/hyphen with following text in the middle
    dash_m = re.search(r'\s*([—–])\s*(?=\S)|\s+-\s+(?=\S)', text)
    if dash_m:
        title = text[:dash_m.start()].strip()
        body = text[dash_m.end():].strip()
        return title, body
        
    m_trail = re.search(r'[–\-—]\s*\]?$', text)
    if m_trail:
        idx = m_trail.start()
        title = text[:idx]
        if text.endswith(']'):
            title += ']'
        return title.strip(), ""
        
    return text, ""

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx'
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)

for key in art_order:
    raw = art_groups[key][0]['text']
    title, body = split_title_body(raw)
    if key in ['32A', '33']:
        print(f"\nArt {key}:")
        print(f"  Title: {repr(title)}")
        print(f"  Body:  {repr(body)}")
