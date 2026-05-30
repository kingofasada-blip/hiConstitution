import zipfile
import json
import sys
import io
import re
import os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())
NEWLINE = '`n'

# ── Path Configurations ───────────────────────────────────────────────
BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')

P8_ORIG = os.path.join(BASE_DIR, 'part 8 original hindi.docx')
P8_SIMP = os.path.join(BASE_DIR, 'Part 8 - Simplified english and hindi.docx')

# ── Helper Functions ──────────────────────────────────────────────────
def map_suffix(key):
    mapping = {'क': 'A', 'ख': 'B', 'ग': 'C', 'घ': 'D'}
    for k, v in mapping.items():
        key = key.replace(k, v)
    return key.upper()

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
    # Prioritize separator with following text in the middle
    dash_m = re.search(r'\s*([—–])\s*(?=\S)|\s+-\s+(?=\S)', text)
    if dash_m:
        title = text[:dash_m.start()].strip()
        body = text[dash_m.end():].strip()
        
        # Clean title and body to check for duplicate/typo heading text after dash
        clean_t = re.sub(r'^\s*\[?\s*(?:अनुच्छेद\s+)?\d+[क-हA-Za-z]*\.?\s*\]?\s*', '', title).strip()
        clean_b = body.strip()
        if clean_t == clean_b:
            body = ""
            
        return title, body
        
    # Trailing hyphen/dash
    m_trail = re.search(r'[–\-—]\s*\]?$', text)
    if m_trail:
        idx = m_trail.start()
        title = text[:idx]
        if text.endswith(']'):
            title += ']'
        return title.strip(), ""
        
    return text, ""

def extract_para_text_with_br(para):
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

def get_article_key_from_runs(line, runs_data):
    heading_pat_art = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*अनुच्छेद\s+(\d+[क-हA-Za-z]*)')
    heading_pat_num = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*(\d+[क-हA-Za-z]*)\.')
    
    m = heading_pat_art.match(line)
    if m:
        art_num = m.group(1)
        for r in runs_data:
            if art_num in r['text'] and r['bold']:
                return art_num
        for r in runs_data:
            if 'अनुच्छेद' in r['text'] and r['bold']:
                return art_num
                
    m = heading_pat_num.match(line)
    if m:
        art_num = m.group(1)
        for r in runs_data:
            if art_num in r['text'] and r['bold']:
                return art_num
                
    return None

def is_amendment_header_from_runs(line, runs_data):
    cleaned = line.strip().rstrip(':').replace(' ', '')
    return cleaned == 'संशोधन'

# ── 1. Original DOCX Extractor ────────────────────────────────────────
def extract_original_docx(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        
        full_text, runs_data = extract_para_text_with_br(para)
        line = full_text.strip()
        if not line: continue
        
        # Replace actual \n with JSON newline marker
        line_json = line.replace('\n', NEWLINE)
        
        art_key = get_article_key_from_runs(line, runs_data)
        is_amend = is_amendment_header_from_runs(line, runs_data)
        
        para_list.append({
            'text': line_json,
            'is_heading': art_key is not None,
            'heading_key': art_key,
            'is_amendment': is_amend
        })
    return para_list

def group_original_articles(paras):
    articles = {}
    order = []
    current = None
    for p in paras:
        if p['is_heading']:
            key = map_suffix(p['heading_key'])
            current = key
            if key not in articles:
                articles[key] = []; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

def format_original_html(paras):
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
            
        elif p['is_amendment']:
            in_amendment = True
            amend_count = 0
            parts.append('<strong>संशोधन:</strong>')
            
        elif in_amendment:
            # Check if this paragraph is a numbered footnote
            is_numbered_footnote = bool(re.match(r'^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰]+|\d+\.)', raw.strip()))
            if is_numbered_footnote:
                clean = raw
                # Strip leading superscript unicode characters
                while clean and clean[0] in SUPER_CHARS:
                    clean = clean[1:]
                # Strip leading digits and dots (e.g. "1. ")
                clean = re.sub(r'^\d+\.\s*', '', clean)
                clean = process_superscripts(clean.strip())
                amend_count += 1
                parts.append('<sup>' + str(amend_count) + '</sup> ' + clean)
            else:
                # Keep note text as is, process superscripts, and prefix with '* '
                clean = process_superscripts(raw.strip())
                parts.append('* ' + clean)
            
        else:
            parts.append(process_superscripts(raw))

    return NEWLINE.join(parts)

# ── 2. Simplified DOCX Extractor ──────────────────────────────────────
def extract_simplified_docx(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        full_text, runs_data = extract_para_text_with_br(para)
        line = full_text.strip()
        if line:
            first_bold = runs_data[0]['bold'] if runs_data else False
            para_list.append({'text': line, 'bold': first_bold})
    return para_list

def parse_simplified_p8(paras):
    simp_groups = {}
    i = 0
    while i < len(paras):
        p = paras[i]
        if p['text'].startswith('Article'):
            art_keys = re.findall(r'(\d+[A-Za-z]*)', p['text'])
            
            clean_en = ""
            en_idx = i + 1
            if en_idx < len(paras):
                raw_en = paras[en_idx]['text']
                clean_en = re.sub(r'^Simplified:\s*', '', raw_en, flags=re.IGNORECASE).strip()
                
            clean_hi = ""
            hi_idx = i + 2
            if hi_idx < len(paras):
                raw_hi = paras[hi_idx]['text']
                clean_hi = re.sub(r'^सारांश टिप्पणी:\s*', '', raw_hi, flags=re.IGNORECASE).strip()
                
            for k in art_keys:
                simp_groups[map_suffix(k)] = {
                    'english': clean_en,
                    'hindi': clean_hi
                }
            i += 3
            continue
        i += 1
    return simp_groups

# ══════════════════════════════════════════════════════════════════════
# MAIN PROCESSING
# ══════════════════════════════════════════════════════════════════════

import xml.etree.ElementTree as ET

print("--- Step 1: Processing Part 8 original DOCX ---")
p8_orig_paras = extract_original_docx(P8_ORIG)
p8_groups, p8_order = group_original_articles(p8_orig_paras)
p8_original_html = {k: format_original_html(p8_groups[k]) for k in p8_order}
print(f"Grouped {len(p8_order)} original articles in Part 8.")

print("\n--- Step 2: Processing Part 8 simplified DOCX ---")
p8_simp_paras = extract_simplified_docx(P8_SIMP)
p8_simplified_text = parse_simplified_p8(p8_simp_paras)
print(f"Extracted {len(p8_simplified_text)} simplified explanations in Part 8.")

# ── Load articles.json ───────────────────────────────────────────────
print("\n--- Step 3: Loading articles.json & applying updates (PART 8 ONLY) ---")
with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Part VIII
part8 = next(p for p in data if p.get('partId') == 'VIII')
for a in part8['articles']:
    art_id = str(a['id']).upper()
    if art_id in p8_original_html:
        a['hindi'] = p8_original_html[art_id]
        print(f"Updated Original Hindi for Article {art_id}")
    else:
        print(f"WARNING (Part 8): no original Hindi found for Article {art_id}")
        
    if art_id in p8_simplified_text:
        a['hindiSimplified'] = '<strong>सारांश टिप्पणी:</strong> ' + p8_simplified_text[art_id]['hindi']
        if p8_simplified_text[art_id]['english']:
            a['simplified'] = p8_simplified_text[art_id]['english']
        print(f"Updated Simplified English & Hindi for Article {art_id}")
    else:
        print(f"WARNING (Part 8): no simplified Hindi/English found for Article {art_id}")

# Save to temporary file
with open(TMP_JSON_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\nSaved updated data to temporary file: {TMP_JSON_PATH}")
