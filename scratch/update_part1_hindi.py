
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 hindi original.docx'
json_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'

# ── 1. Extract all paragraphs from docx ──────────────────────────────
with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
root = tree.getroot()
paragraphs = []

for para in root.iter('{%s}p' % W):
    full_text = []
    for r in para.iter('{%s}r' % W):
        t = r.find('{%s}t' % W)
        if t is not None and t.text:
            full_text.append(t.text)
    line = ''.join(full_text).strip()
    if line:
        paragraphs.append(line)

# ── 2. Group paragraphs by article ───────────────────────────────────
# Article line starts like: "1. Title–body" or "2क. [Title]–body"
art_start_re = re.compile(r'^(\d+[^\s\.\–\-]*)\.\s')

articles_raw = {}   # key = article number string -> list of lines
current_art = None
art_order = []      # to preserve order

for p in paragraphs:
    m = art_start_re.match(p)
    if m:
        art_num_str = m.group(1)
        current_art = art_num_str
        if current_art not in articles_raw:
            articles_raw[current_art] = []
            art_order.append(current_art)
        articles_raw[current_art].append(p)
    elif current_art is not None:
        articles_raw[current_art].append(p)

print('Articles parsed from docx:')
for k in art_order:
    print('  [' + k + '] => ' + str(articles_raw[k][0])[:80])

# ── 3. Format article HTML ────────────────────────────────────────────
def clean_line(line):
    """Remove footnote superscripts like ¹ ² ³ and standalone ** markers"""
    line = re.sub(r'[¹²³⁴⁵⁶⁷⁸⁹]+', '', line)
    line = re.sub(r'\*\*\[|\]\*\*|\*\*', '', line)
    line = re.sub(r'^\[|\]$', '', line.strip())
    return line.strip()

def format_article_html(lines):
    """
    Format article lines into HTML:
    - First line: bold the title (before –), then newline, then rest
    - Subsequent lines: as-is (cleaned)
    """
    result_parts = []

    for i, line in enumerate(lines):
        cleaned = clean_line(line)
        if not cleaned:
            continue

        if i == 0:
            # Find the em-dash or hyphen separator
            dash_pos = -1
            for sym in ['–', '-']:
                pos = cleaned.find(sym)
                if pos > 0:
                    dash_pos = pos
                    break

            if dash_pos > 0:
                title_part = cleaned[:dash_pos].strip()
                body_part = cleaned[dash_pos+1:].strip()
                if body_part:
                    result_parts.append('<strong>' + title_part + ' –</strong>')
                    result_parts.append(body_part)
                else:
                    result_parts.append('<strong>' + title_part + ' –</strong>')
            else:
                result_parts.append('<strong>' + cleaned + '</strong>')
        else:
            result_parts.append(cleaned)

    return '\n'.join(result_parts)

# ── 4. Load articles.json ─────────────────────────────────────────────
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# ── 5. Find Part I ────────────────────────────────────────────────────
part1_idx = None
for i, part in enumerate(data):
    if part.get('partId') == 'I':
        part1_idx = i
        break

if part1_idx is None:
    print('ERROR: Part I not found!')
    sys.exit(1)

part1 = data[part1_idx]
articles = part1.get('articles', [])

# ── 6. Map each JSON article to docx article by extracting number ─────
# JSON article id: "1", "2", "2A", "3", "4"
# Docx keys: "1", "2", "2", "3", "4"  (2क parsed as "2" again — but 2 comes first)
# So: JSON id "1"->docx "1", "2"->"2", "2A"->skip (omitted), "3"->"3", "4"->"4"

def get_art_num_from_id(art_id):
    """Extract numeric part from id like '1','2','2A','3','4'"""
    m = re.match(r'^(\d+)', str(art_id))
    if m:
        return m.group(1)
    return None

print('\n--- Updating Part I hindi fields ---')
for a in articles:
    art_id = str(a.get('id', ''))
    title_en = a.get('title', '')

    # Article 2A is omitted, skip but still clear old hindi
    if art_id == '2A':
        # Article 2क (Sikkim) was omitted - put the omitted text
        omit_text = articles_raw.get('2')  # "2क" lines if any exist
        # Actually in our docx "2क" lines are part of art "2" continuation
        # Let's find 2क specifically
        docx_2ka = None
        for ln in articles_raw.get('2', []):
            if '2क' in ln or 'सिक्किम' in ln:
                docx_2ka = [ln]
                break
        if docx_2ka:
            html = format_article_html(docx_2ka)
            a['hindi'] = html
            print('Art 2A: set from 2क line, len=' + str(len(html)))
        else:
            a['hindi'] = '<strong>2क. [सिक्किम का संघ के साथ सहयुक्त किया जाना] –</strong>\nसंविधान (छत्तीसवां संशोधन) अधिनियम, 1975 की धारा 5 द्वारा (26-4-1975 से) लोप किया गया।'
            print('Art 2A: set default omitted text')
        continue

    num = get_art_num_from_id(art_id)
    docx_lines = articles_raw.get(num)

    if docx_lines:
        # For article 2, we only want the actual Article 2 lines, not 2क lines
        if num == '2':
            filtered = [ln for ln in docx_lines if '2क' not in ln and 'सिक्किम' not in ln and 'पैंतीसवां' not in ln]
            docx_lines = filtered if filtered else docx_lines

        html = format_article_html(docx_lines)
        a['hindi'] = html
        print('Art ' + art_id + ' (' + title_en[:40] + '): updated, len=' + str(len(html)))
    else:
        print('Art ' + art_id + ': NO docx match for num=' + str(num))

# ── 7. Save JSON ──────────────────────────────────────────────────────
with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone! articles.json saved.')
print('\n=== PREVIEW OF UPDATED HINDI ===')
for a in articles:
    print('\n--- Article', a.get('id'), '---')
    print(a.get('hindi', '(empty)')[:400])
    print('...')
