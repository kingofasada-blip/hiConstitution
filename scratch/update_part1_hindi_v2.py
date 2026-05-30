
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 hindi original.docx'
json_path  = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
NEWLINE    = '`n'   # same as English section

# ── Superscript unicode map ───────────────────────────────────────────
SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

def to_sup_tag(ch_str):
    """Convert superscript unicode chars to <sup>N</sup> HTML."""
    num = ''.join(SUPER_MAP.get(c, c) for c in ch_str)
    return '<sup>' + num + '</sup>'

def process_superscripts(text):
    """
    Convert leading + embedded superscript unicode chars to <sup> tags.
    e.g. "¹[(2) राज्य...]"  -> "<sup>1</sup>[(2) राज्य...]"
    e.g. "...प्रभाव²रा..."  -> "...प्रभाव<sup>2</sup>रा..."
    """
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

def strip_docx_bold_markers(text):
    """Remove **[...** and **] markers used in docx for bold indicators."""
    text = re.sub(r'\*\*\[', '[', text)
    text = re.sub(r'\]\*\*', ']', text)
    text = re.sub(r'\*\*', '', text)
    return text

# ── Extract paragraphs with bold flag ────────────────────────────────
with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
root = tree.getroot()
para_list = []

for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    full_text = []
    first_run_bold = False
    first_run_checked = False
    for r in runs:
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and rpr.find('{%s}b' % W) is not None
            if not first_run_checked and t.text.strip():
                first_run_bold = is_bold
                first_run_checked = True
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if line:
        para_list.append({'text': line, 'bold': first_run_bold})

# ── Group paragraphs into articles ───────────────────────────────────
# Article starts with bold=True AND matches "N. title–"
art_start_re = re.compile(r'^(\d+[^\s.\u2013\-]*)\.')

articles_raw = {}   # key=str -> list of para dicts
art_order    = []

current_art = None
for p in para_list:
    m = art_start_re.match(p['text'])
    if p['bold'] and m:
        key = m.group(1)
        current_art = key
        if key not in articles_raw:
            articles_raw[key] = []
            art_order.append(key)
        articles_raw[key].append(p)
    elif current_art is not None:
        articles_raw[current_art].append(p)

print('Articles grouped:', art_order)

# ── Format one article into final HTML string ─────────────────────────
def format_article(paras):
    """
    Rules (matching English format exactly):
    1. First para (bold, article title line):
       - "N. TITLE–body"  or "N. TITLE–"
       - <strong>N. TITLE—</strong>`nbody
    2. Subsequent body paras (bold=False):
       - Superscripts converted to <sup>
       - Lines joined with `n
    3. "संशोधन:" para (bold=True, not an article start):
       - <strong>संशोधन:</strong>`n
       - Then each amendment note gets: <sup>N</sup> text...
         with sequential numbering matching superscripts in body
    """
    parts = []
    amendment_section = False
    amend_counter = [0]   # mutable for closure

    for i, p in enumerate(paras):
        raw = strip_docx_bold_markers(p['text'])

        if i == 0:
            # --- Article title line ---
            # Find em-dash or hyphen separator
            dash_re = re.search(r'[–\-]', raw)
            if dash_re:
                before = raw[:dash_re.start()].strip()
                after  = raw[dash_re.end():].strip()
                # Process superscripts in title (unlikely but safe)
                before = process_superscripts(before)
                if after:
                    after = process_superscripts(after)
                    parts.append('<strong>' + before + '—</strong>' + NEWLINE + after)
                else:
                    parts.append('<strong>' + before + '—</strong>')
            else:
                parts.append('<strong>' + process_superscripts(raw) + '</strong>')
            amendment_section = False

        elif p['bold'] and raw.strip().rstrip(':') == 'संशोधन':
            # --- "संशोधन:" header ---
            amendment_section = True
            amend_counter[0] = 0
            parts.append('<strong>संशोधन:</strong>')

        elif amendment_section:
            # --- Amendment note lines ---
            amend_counter[0] += 1
            n = amend_counter[0]
            # These lines may or may not start with a superscript.
            # We always prepend <sup>N</sup> to match English format.
            # Strip any leading superscript chars first (they'll be replaced by our counter)
            clean = raw
            # Remove leading superscript chars if present
            while clean and clean[0] in SUPER_CHARS:
                clean = clean[1:]
            clean = clean.strip()
            # Process any embedded superscripts
            clean = process_superscripts(clean)
            parts.append('<sup>' + str(n) + '</sup> ' + clean)

        else:
            # --- Body line ---
            parts.append(process_superscripts(raw))

    return NEWLINE.join(parts)

# ── Build final article HTML strings ─────────────────────────────────
# Article 2A (2क) is inside article 2's lines in docx
# We'll handle it specially

article_html = {}

for key in art_order:
    paras = articles_raw[key]
    if key == '2':
        # Separate article 2 body from 2क embedded line
        art2_paras  = []
        art2k_paras = []
        in_2k = False
        for p in paras:
            if '2क' in p['text'] or 'सिक्किम' in p['text']:
                in_2k = True
                art2k_paras.append(p)
            elif in_2k:
                # Lines after 2क (संशोधन for 2क)
                art2k_paras.append(p)
            else:
                art2_paras.append(p)
        article_html['2']  = format_article(art2_paras)
        # Now build 2क as its own article
        # 2क line is a single para with embedded text
        # Parse it: "¹**[2क. [सिक्किम...]—**text...]"
        if art2k_paras:
            ka_line = art2k_paras[0]['text']
            ka_line = strip_docx_bold_markers(ka_line)
            # Remove leading superscript
            while ka_line and ka_line[0] in SUPER_CHARS:
                ka_line = ka_line[1:]
            ka_line = ka_line.strip()
            # Now ka_line = "[2क. [सिक्किम...]–संविधान...]"
            # Remove outer brackets
            if ka_line.startswith('[') and ka_line.endswith(']'):
                ka_line = ka_line[1:-1]
            # Find dash
            dash_m = re.search(r'[–\-]', ka_line)
            if dash_m:
                title_part = ka_line[:dash_m.start()].strip()
                body_part  = ka_line[dash_m.end():].strip()
                html_2k = '<strong>' + process_superscripts(title_part) + '—</strong>' + NEWLINE + process_superscripts(body_part)
            else:
                html_2k = '<strong>' + process_superscripts(ka_line) + '</strong>'
            # Add संशोधन for 2क
            amend_notes = []
            for sp in art2k_paras[1:]:
                raw_sp = strip_docx_bold_markers(sp['text'])
                # Skip the bold "संशोधन:" header line itself
                if sp['bold'] and raw_sp.strip().rstrip(':') == 'संशोधन':
                    html_2k += NEWLINE + '<strong>संशोधन:</strong>'
                else:
                    while raw_sp and raw_sp[0] in SUPER_CHARS:
                        raw_sp = raw_sp[1:]
                    amend_notes.append(raw_sp.strip())
            for j, note in enumerate(amend_notes, 1):
                html_2k += NEWLINE + '<sup>' + str(j) + '</sup> ' + process_superscripts(note)
            article_html['2A'] = html_2k
    else:
        article_html[key] = format_article(paras)

# ── Load + update articles.json ───────────────────────────────────────
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

part1_idx = None
for i, part in enumerate(data):
    if part.get('partId') == 'I':
        part1_idx = i
        break

part1    = data[part1_idx]
articles = part1['articles']

# Map JSON id -> docx key
id_to_docx = {'1':'1', '2':'2', '2A':'2A', '3':'3', '4':'4'}

print('\n=== FINAL HINDI HTML ===')
for a in articles:
    art_id  = str(a.get('id',''))
    docx_key = id_to_docx.get(art_id)
    if docx_key and docx_key in article_html:
        a['hindi'] = article_html[docx_key]
        print('\n--- Art', art_id, '---')
        print(a['hindi'])
    else:
        print('\n--- Art', art_id, ': no docx key ---')

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone! articles.json saved.')
