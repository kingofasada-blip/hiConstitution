
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

orig_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 hindi original.docx'
simp_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 3 english and hindi simplify.docx'
json_path  = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
W          = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
NEWLINE    = '`n'

# ── Superscript helpers ───────────────────────────────────────────────
SUPER_MAP   = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
               '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

def process_superscripts(text):
    result = ''; i = 0
    while i < len(text):
        if text[i] in SUPER_CHARS:
            sup = ''
            while i < len(text) and text[i] in SUPER_CHARS:
                sup += text[i]; i += 1
            num = ''.join(SUPER_MAP.get(c,c) for c in sup)
            result += '<sup>' + num + '</sup>'
        else:
            result += text[i]; i += 1
    return result

def strip_bold_markers(text):
    text = re.sub(r'\*\*\[','[',text); text = re.sub(r'\]\*\*',']',text)
    return re.sub(r'\*\*','',text)

# ── Extract paragraphs ────────────────────────────────────────────────
def extract_paras(docx_path):
    with zipfile.ZipFile(docx_path,'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        full_text=[]; first_bold=False; first_checked=False
        for r in runs:
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                rpr = r.find('{%s}rPr' % W)
                is_bold = rpr is not None and rpr.find('{%s}b' % W) is not None
                if not first_checked and t.text.strip():
                    first_bold=is_bold; first_checked=True
                full_text.append(t.text)
        line = ''.join(full_text).strip()
        if line:
            para_list.append({'text':line,'bold':first_bold})
    return para_list

# ── Group original paras by article ──────────────────────────────────
def group_by_article(paras):
    art_start_re = re.compile(r'^(\d+[^\s.\u2013\-]*)\.')
    articles={}; order=[]; current=None
    for p in paras:
        m = art_start_re.match(p['text'])
        if p['bold'] and m:
            key = m.group(1)
            current = key
            if key not in articles:
                articles[key]=[]; order.append(key)
            articles[key].append(p)
        elif current is not None:
            articles[current].append(p)
    return articles, order

# ── Format article as hindi HTML ──────────────────────────────────────
def format_article_html(paras):
    parts=[]; in_amendment=False; amend_count=0
    for i,p in enumerate(paras):
        raw = strip_bold_markers(p['text'])
        if i == 0:
            dash_m = re.search(r'[–\-]', raw)
            if dash_m:
                before = process_superscripts(raw[:dash_m.start()].strip())
                after  = process_superscripts(raw[dash_m.end():].strip())
                parts.append('<strong>'+before+'—</strong>'+(NEWLINE+after if after else ''))
            else:
                parts.append('<strong>'+process_superscripts(raw)+'</strong>')
            in_amendment=False; amend_count=0
        elif p['bold'] and raw.strip().rstrip(':')=='संशोधन':
            in_amendment=True; amend_count=0
            parts.append('<strong>संशोधन:</strong>')
        elif in_amendment:
            clean=raw
            while clean and clean[0] in SUPER_CHARS: clean=clean[1:]
            clean=process_superscripts(clean.strip())
            amend_count+=1
            parts.append('<sup>'+str(amend_count)+'</sup> '+clean)
        else:
            parts.append(process_superscripts(raw))
    return NEWLINE.join(parts)

# ══ STEP 1: Original Hindi ════════════════════════════════════════════
orig_paras = extract_paras(orig_path)
art_groups, art_order = group_by_article(orig_paras)
print('Original articles found:', art_order)

hindi_html = {}
for key in art_order:
    hindi_html[key] = format_article_html(art_groups[key])

# ══ STEP 2: Simplified Hindi ══════════════════════════════════════════
simp_paras = extract_paras(simp_path)

# Simplify pattern: bold heading "Article N / अनुच्छेद N" then EN then HI
# Group by heading blocks
simp_groups = {}  # art_id -> hindi_text
i = 0
while i < len(simp_paras):
    p = simp_paras[i]
    # Check if this is a heading like "Article 12 / अनुच्छेद 12"
    if p['bold']:
        # Extract article number from heading
        # e.g. "Article 21A / अनुच्छेद 21क" -> "21A"
        m = re.search(r'Article\s+(\d+[A-Za-z]*)', p['text'])
        if m:
            art_key = m.group(1).upper()  # "21A", "31C" etc.
            # Next para = English, para after = Hindi
            en_idx = i + 1
            hi_idx = i + 2
            if hi_idx < len(simp_paras):
                simp_groups[art_key] = simp_paras[hi_idx]['text']
            i += 3
            continue
    i += 1

print('\nSimplified Hindi groups:', list(simp_groups.keys()))

# ══ STEP 3: Load JSON, update Part III ═══════════════════════════════
with open(json_path,'r',encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId')=='III')
articles = part3['articles']

# Build a canonical key from JSON article id
# JSON id: "12","13"..."21A"..."31A","31B","31C","31D","32"...
def canonical(art_id):
    return str(art_id).upper().replace('A','A').replace('B','B').replace('C','C').replace('D','D')

print('\n=== Updating Part III articles ===')
for a in articles:
    art_id = str(a.get('id',''))
    can    = canonical(art_id)

    # Hindi original: try exact key, then numeric part
    num_only = re.match(r'^(\d+)', art_id)
    num_key  = num_only.group(1) if num_only else art_id

    if can in hindi_html:
        a['hindi'] = hindi_html[can]
        print('Art '+art_id+' -> hindi OK (key='+can+')')
    elif num_key in hindi_html:
        # suffix like 21A might be in "21" with extra paras — use num_key
        a['hindi'] = hindi_html[num_key]
        print('Art '+art_id+' -> hindi OK (num_key='+num_key+')')
    else:
        print('Art '+art_id+' -> WARNING: no hindi found')

    # Hindi simplified
    simp_key = can  # e.g. "21A", "31C"
    if simp_key in simp_groups:
        a['hindiSimplified'] = '<strong>सारांश टिप्पणी:</strong> ' + simp_groups[simp_key]
        print('Art '+art_id+' -> hindiSimplified OK')
    elif num_key+'A' not in simp_groups and num_key in simp_groups:
        a['hindiSimplified'] = '<strong>सारांश टिप्पणी:</strong> ' + simp_groups[num_key]
        print('Art '+art_id+' -> hindiSimplified OK (num_key)')
    else:
        print('Art '+art_id+' -> WARNING: no hindiSimplified found (key='+simp_key+')')

with open(json_path,'w',encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone! articles.json saved.')

# Preview first 3
print('\n=== PREVIEW (first 3 articles) ===')
for a in articles[:3]:
    print('\n--- Art',a['id'],'---')
    print('hindi:',a.get('hindi','')[:200])
    print('hindiSimplified:',a.get('hindiSimplified','')[:150])
