
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 2 hindi original.docx'
simp_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 2 english and hindi simplify .docx'
json_path  = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
W          = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
NEWLINE    = '`n'

# ── Superscript map ───────────────────────────────────────────────────
SUPER_MAP   = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
               '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

def to_sup_tag(chars):
    num = ''.join(SUPER_MAP.get(c, c) for c in chars)
    return '<sup>' + num + '</sup>'

def process_superscripts(text):
    result = ''
    i = 0
    while i < len(text):
        if text[i] in SUPER_CHARS:
            sup = ''
            while i < len(text) and text[i] in SUPER_CHARS:
                sup += text[i]; i += 1
            result += to_sup_tag(sup)
        else:
            result += text[i]; i += 1
    return result

def strip_bold_markers(text):
    text = re.sub(r'\*\*\[', '[', text)
    text = re.sub(r'\]\*\*', ']', text)
    return re.sub(r'\*\*', '', text)

# ── Extract paragraphs with bold flag ────────────────────────────────
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
                is_bold = rpr is not None and rpr.find('{%s}b' % W) is not None
                if not first_checked and t.text.strip():
                    first_bold = is_bold; first_checked = True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text': line, 'bold': first_bold})
    return para_list

# ── Group original paragraphs by article ─────────────────────────────
def group_by_article(paras):
    art_start_re = re.compile(r'^(\d+[^\s.\u2013\-]*)\.')
    articles = {}   # key -> list of para dicts
    order    = []
    current  = None
    for p in paras:
        m = art_start_re.match(p['text'])
        if p['bold'] and m:
            key = m.group(1)
            current = key
            if key not in articles:
                articles[key] = []; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

# ── Format one article as hindi HTML ─────────────────────────────────
def format_article_html(paras):
    parts = []
    in_amendment = False
    amend_notes  = []

    for i, p in enumerate(paras):
        raw = strip_bold_markers(p['text'])

        if i == 0:
            # Title line: "N. TITLE–body" or "N. TITLE–"
            dash_m = re.search(r'[–\-]', raw)
            if dash_m:
                before = process_superscripts(raw[:dash_m.start()].strip())
                after  = process_superscripts(raw[dash_m.end():].strip())
                if after:
                    parts.append('<strong>' + before + '—</strong>' + NEWLINE + after)
                else:
                    parts.append('<strong>' + before + '—</strong>')
            else:
                parts.append('<strong>' + process_superscripts(raw) + '</strong>')
            in_amendment = False; amend_notes = []

        elif p['bold'] and raw.strip().rstrip(':') == 'संशोधन':
            # Flush any pending body parts, then start amendment section
            in_amendment = True; amend_notes = []
            parts.append('<strong>संशोधन:</strong>')

        elif in_amendment:
            # Amendment note — strip leading superscript chars (replaced by counter)
            clean = raw
            while clean and clean[0] in SUPER_CHARS:
                clean = clean[1:]
            clean = process_superscripts(clean.strip())
            amend_notes.append(clean)
            n = len(amend_notes)
            parts.append('<sup>' + str(n) + '</sup> ' + clean)

        else:
            parts.append(process_superscripts(raw))

    return NEWLINE.join(parts)

# ══════════════════════════════════════════════════════════════════════
# STEP 1: Process original Hindi
# ══════════════════════════════════════════════════════════════════════
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)

print('Articles found in original docx:', art_order)

# Build hindi HTML for each article
hindi_html = {}
for key in art_order:
    hindi_html[key] = format_article_html(art_groups[key])
    print('Art', key, '-> hindi len=', len(hindi_html[key]))

# ══════════════════════════════════════════════════════════════════════
# STEP 2: Process simplified Hindi
# ══════════════════════════════════════════════════════════════════════
simp_paras = extract_paras(simp_path)
# Plain text only (no bold runs in simplify doc)
simp_texts = [p['text'] for p in simp_paras]

# Pattern: [heading, EN, HI] repeated for each article
# Art 5=idx2, 6=idx5, 7=idx8, 8=idx11, 9=idx14, 10=idx17, 11=idx20
simp_art_ids = ['5', '6', '7', '8', '9', '10', '11']
hindi_simp = {}
for i, art_id in enumerate(simp_art_ids):
    hi_idx = 2 + i * 3
    if hi_idx < len(simp_texts):
        hindi_simp[art_id] = simp_texts[hi_idx]

print('\nSimplified Hindi extracted:')
for k, v in hindi_simp.items():
    print('Art', k, ':', v[:80])

# Key terms to bold per article (matching English simplified bold style)
bold_terms = {
    '5':  ['स्थाई निवास', 'भारत में जन्म', 'पांच वर्ष', 'नागरिकता'],
    '6':  ['पाकिस्तान से भारत', '19 जुलाई, 1948', 'नागरिकता प्रमाण-पत्र'],
    '7':  ['1 मार्च 1947', 'पाकिस्तान', 'भारत का नागरिक नहीं'],
    '8':  ['भारतीय मूल', 'विदेश में रहने', 'राजनयिक प्रतिनिधि'],
    '9':  ['विदेशी देश की नागरिकता', 'स्वेच्छा से', 'भारत का नागरिक नहीं'],
    '10': ['नागरिकता बनाए रखने', 'संसद', 'भावी कानून'],
    '11': ['संसद', 'नागरिकता का अधिकार', 'विनियमित'],
}

def make_hindi_simplified(art_id, text):
    terms = sorted(bold_terms.get(art_id, []), key=len, reverse=True)
    for term in terms:
        if term in text:
            text = text.replace(term, '<strong>' + term + '</strong>', 1)
    return '<strong>सारांश टिप्पणी:</strong> ' + text

# ══════════════════════════════════════════════════════════════════════
# STEP 3: Load JSON and update Part II articles
# ══════════════════════════════════════════════════════════════════════
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
articles = part2['articles']

print('\n=== Updating Part II articles ===')
for a in articles:
    art_id = str(a.get('id', ''))

    # Hindi original
    if art_id in hindi_html:
        a['hindi'] = hindi_html[art_id]
        print('Art', art_id, '-> hindi updated')
    else:
        print('Art', art_id, '-> WARNING: no hindi_html found')

    # Hindi simplified
    if art_id in hindi_simp:
        a['hindiSimplified'] = make_hindi_simplified(art_id, hindi_simp[art_id])
        print('Art', art_id, '-> hindiSimplified updated')
    else:
        print('Art', art_id, '-> WARNING: no hindiSimplified found')

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone! articles.json saved.')

# ── Preview ───────────────────────────────────────────────────────────
print('\n=== PREVIEW ===')
for a in articles:
    print('\n--- Art', a['id'], '---')
    print('hindi:', a.get('hindi','')[:250])
    print('hindiSimplified:', a.get('hindiSimplified','')[:150])
