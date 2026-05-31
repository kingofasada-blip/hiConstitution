import zipfile
import xml.etree.ElementTree as ET
import os
import json
import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())
NEWLINE = '`n'

BASE_MAP = {
    'क': 'A', 'ख': 'B', 'ग': 'C', 'घ': 'D', 'ङ': 'E',
    'च': 'F', 'छ': 'G', 'ज': 'H', 'झ': 'I', 'ञ': 'J',
    'ट': 'K', 'ठ': 'L', 'ड': 'M', 'ढ': 'N', 'ण': 'O',
    'त': 'P', 'थ': 'Q', 'द': 'R', 'ध': 'S', 'न': 'T',
    'प': 'U', 'फ': 'V', 'ब': 'W', 'भ': 'X', 'म': 'Y',
    'य': 'Z'
}

def map_hindi_suffix(suffix):
    if not suffix:
        return ""
    suffix = suffix.strip()
    if suffix.startswith('य') and len(suffix) > 1:
        rem = suffix[1:]
        mapped_rem = "".join(BASE_MAP.get(c, c) for c in rem)
        return "Z" + mapped_rem
    return "".join(BASE_MAP.get(c, c) for c in suffix)

def get_article_key(line):
    # Matches optional superscript/bracket, then 243 followed by optional Hindi chars, then a dot.
    m = re.match(r'^(?:[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*)?(243[\u0900-\u097F]*)\.', line)
    if m:
        key_raw = m.group(1)
        suffix = key_raw[3:]
        mapped_suffix = map_hindi_suffix(suffix)
        return "243" + mapped_suffix
    return None

def is_amendment_header(line):
    cleaned = line.strip().rstrip(':').replace(' ', '')
    return cleaned == 'संशोधन'

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
        
        # Clean title and body to check for duplicate/typo heading text after dash
        clean_t = re.sub(r'^\s*\[?\s*(?:अनुच्छेद\s+)?\d+[क-हA-Za-z]*\.?\s*\]?\s*', '', title).strip()
        clean_b = body.strip()
        if clean_t == clean_b:
            body = ""
            
        return title, body
        
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
        
        line_json = line.replace('\n', NEWLINE)
        art_key = get_article_key(line)
        is_amend = is_amendment_header(line)
        
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
            key = p['heading_key']
            current = key
            if key not in articles:
                articles[key] = []
                order.append(key)
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
                clean = process_superscripts(raw.strip())
                parts.append('* ' + clean)
            
        else:
            parts.append(process_superscripts(raw))

    return NEWLINE.join(parts)

# Extract simplified explanations
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
            para_list.append(line)
    return para_list

def parse_simplified_file(docx_path):
    paras = extract_simplified_docx(docx_path)
    simp_groups = {}
    i = 0
    while i < len(paras):
        line = paras[i]
        if line.startswith('Article'):
            art_keys = re.findall(r'(\d+[A-Za-z]*)', line)
            
            clean_en = ""
            clean_hi = ""
            
            j = i + 1
            found_en = False
            found_hi = False
            while j < min(i + 5, len(paras)):
                next_p = paras[j]
                if next_p.startswith('Article'):
                    break
                if next_p.lower().startswith('simplified') and not found_en:
                    clean_en = re.sub(r'^Simplified\s*:\s*', '', next_p, flags=re.IGNORECASE).strip()
                    found_en = True
                elif (next_p.startswith('सारांश टिप्पणी') or next_p.startswith('सारांश टिपण्णी')) and not found_hi:
                    clean_hi = re.sub(r'^सारांश टिप्पणी\s*:\s*', '', next_p).strip()
                    clean_hi = re.sub(r'^सारांश टिपण्णी\s*:\s*', '', clean_hi).strip()
                    found_hi = True
                j += 1
                
            if not found_en and not found_hi:
                if i + 1 < len(paras) and not paras[i+1].startswith('Article'):
                    clean_en = paras[i+1]
                if i + 2 < len(paras) and not paras[i+2].startswith('Article'):
                    clean_hi = paras[i+2]
                    
            for k in art_keys:
                simp_groups[k.upper()] = {
                    'english': clean_en,
                    'hindi': clean_hi
                }
            i = j
            continue
        i += 1
    return simp_groups

# ----------------------------------------------------
# MAIN PIPELINE
# ----------------------------------------------------
def main():
    # Original Hindi data
    orig_files = [
        os.path.join(BASE_DIR, 'part 9 original hindi.docx'),
        os.path.join(BASE_DIR, 'part 9A original hindi.docx'),
        os.path.join(BASE_DIR, 'part 9B original hindi.docx')
    ]

    original_hindi_html = {}
    for fp in orig_files:
        print(f"Processing original Hindi file: {fp}")
        paras = extract_original_docx(fp)
        groups, order = group_original_articles(paras)
        for k in order:
            original_hindi_html[k] = format_original_html(groups[k])

    print(f"Extracted {len(original_hindi_html)} original Hindi articles.")

    # Simplified English/Hindi data
    simp_files = [
        os.path.join(BASE_DIR, 'part 9 simplify  hindi and english.docx'),
        os.path.join(BASE_DIR, 'part 9A simplify  hindi and english.docx'),
        os.path.join(BASE_DIR, 'part 9B simplify  hindi and english.docx')
    ]

    simplified_data = {}
    for fp in simp_files:
        print(f"Processing simplified file: {fp}")
        data_extracted = parse_simplified_file(fp)
        for k, val in data_extracted.items():
            simplified_data[k] = val

    print(f"Extracted {len(simplified_data)} simplified articles.")

    # Load articles.json
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    target_parts = ["IX", "IXA", "IXB"]
    updated_counts = {p: 0 for p in target_parts}

    for part in data:
        part_id = part.get('partId')
        if part_id in target_parts:
            print(f"\nUpdating Part {part_id}...")
            for art in part.get('articles', []):
                art_id = str(art['id']).upper()
                
                # Update original Hindi
                if art_id in original_hindi_html:
                    art['hindi'] = original_hindi_html[art_id]
                    print(f"  Updated original Hindi for Article {art_id}")
                else:
                    print(f"  WARNING: No original Hindi found for Article {art_id}")
                    
                # Update simplified English & Hindi
                if art_id in simplified_data:
                    if simplified_data[art_id]['english']:
                        art['simplified'] = simplified_data[art_id]['english']
                    if simplified_data[art_id]['hindi']:
                        art['hindiSimplified'] = '<strong>सारांश टिप्पणी:</strong> ' + simplified_data[art_id]['hindi']
                    print(f"  Updated simplified English/Hindi for Article {art_id}")
                else:
                    print(f"  WARNING: No simplified data found for Article {art_id}")
                
                updated_counts[part_id] += 1

    print("\nSummary of Updates:")
    for p, c in updated_counts.items():
        print(f"Part {p}: {c} articles updated.")

    # Save to temporary file
    with open(TMP_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nSuccessfully wrote updated JSON to: {TMP_JSON_PATH}")

if __name__ == '__main__':
    main()
