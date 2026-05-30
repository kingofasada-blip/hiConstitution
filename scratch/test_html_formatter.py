import zipfile, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())
NEWLINE = '`n'

def to_sup_tag(ch_str):
    num = ''.join(SUPER_MAP.get(c, c) for c in ch_str)
    return '<sup>' + num + '</sup>'

def process_superscripts(text):
    result = ''
    i = 0
    while i < len(text):
        if text[i] in SUPER_CHARS:
            sup_str = ''
            while i < len(text) and text[i] in SUPER_CHARS:
                sup_str += text[i]
                i += 1
            result += to_sup_tag(sup_str)
        else:
            result += text[i]
            i += 1
    return result

def split_title_body(text):
    text = text.strip()
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
        has_bold_amend = False
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                rpr = r.find('{%s}rPr' % W)
                is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
                if 'अनुच्छेद' in t.text and is_bold:
                    has_bold_art = True
                if 'संशोधन' in t.text and is_bold:
                    has_bold_amend = True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text': line, 'bold_art': has_bold_art, 'bold_amend': has_bold_amend})
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

def format_article_html(paras):
    parts = []
    in_amendment = False
    amend_count = 0

    for i, p in enumerate(paras):
        raw = p['text']

        if i == 0:
            title, body = split_title_body(raw)
            title_with_sups = process_superscripts(title)
            parts.append('<strong>' + title_with_sups + '—</strong>' + (NEWLINE + process_superscripts(body) if body else ''))
            in_amendment = False
            amend_count = 0
            
        elif p['bold_amend'] and raw.strip().rstrip(':') == 'संशोधन':
            in_amendment = True
            amend_count = 0
            parts.append('<strong>संशोधन:</strong>')
            
        elif in_amendment:
            clean = raw
            while clean and clean[0] in SUPER_CHARS:
                clean = clean[1:]
            clean = process_superscripts(clean.strip())
            amend_count += 1
            parts.append('<sup>' + str(amend_count) + '</sup> ' + clean)
            
        else:
            parts.append(process_superscripts(raw))

    return NEWLINE.join(parts)

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx'
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)

print("Article 13 HTML output:")
print(format_article_html(art_groups['13']))
