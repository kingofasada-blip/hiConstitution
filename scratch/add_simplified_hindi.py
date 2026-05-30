
import zipfile, json, sys, io
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 english and hindi simplify .docx'
json_path  = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

# ── 1. Extract all paragraphs ──────────────────────────────────────────
with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

root = tree.getroot()
para_list = []

for para in root.iter('{%s}p' % W):
    runs = list(para.iter('{%s}r' % W))
    if not runs:
        continue
    full_text = ''.join(
        r.find('{%s}t' % W).text
        for r in runs
        if r.find('{%s}t' % W) is not None and r.find('{%s}t' % W).text
    ).strip()
    if full_text:
        para_list.append(full_text)

# ── 2. Pick Hindi simplified paragraphs ──────────────────────────────
# Structure: [0]=heading1, [1]=EN simp1, [2]=HI simp1,
#            [3]=heading2, [4]=EN simp2, [5]=HI simp2, ...
# Hindi paras: index 2, 5, 8, 11, 14
art_ids = ['1', '2', '2A', '3', '4']
hindi_paras = {}
for i, art_id in enumerate(art_ids):
    hindi_paras[art_id] = para_list[2 + i * 3]

print('Extracted Hindi simplified:')
for k, v in hindi_paras.items():
    print('Art', k, ':', v[:100])

# ── 3. Key terms to bold (matching English simplified style) ──────────
bold_terms = {
    '1':  ['इंडिया, अर्थात् भारत', 'राज्यों के संघ', 'पहली अनुसूची', 'संघ राज्यक्षेत्र'],
    '2':  ['नए राज्यों को प्रवेश देने', 'नए राज्यों की स्थापना', 'नियमों और शर्तों'],
    '2A': ['सिक्किम', 'संविधान संशोधन'],
    '3':  ['नए राज्य का निर्माण', 'राष्ट्रपति की पूर्व सिफारिश', 'राज्य के विधानमंडल', 'अनुच्छेद 368'],
    '4':  ['अनुच्छेद 2', 'अनुच्छेद 3', 'पहली अनुसूची', 'चौथी अनुसूची', 'अनुच्छेद 368'],
}

def make_hindi_simplified(art_id, text):
    """
    Format matching English 'simplified' style:
    <strong>सारांश टिप्पणी:</strong> ...text with <strong>key terms</strong>...
    """
    terms = sorted(bold_terms.get(art_id, []), key=len, reverse=True)
    for term in terms:
        if term in text:
            text = text.replace(term, '<strong>' + term + '</strong>', 1)
    return '<strong>सारांश टिप्पणी:</strong> ' + text

# ── 4. Load JSON and update hindiSimplified field ─────────────────────
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = next(p for p in data if p.get('partId') == 'I')

print('\n=== Updating hindiSimplified field ===')
for a in part1['articles']:
    art_id = str(a.get('id', ''))
    if art_id in hindi_paras:
        html = make_hindi_simplified(art_id, hindi_paras[art_id])
        a['hindiSimplified'] = html
        print('\nArt', art_id, '-> hindiSimplified:')
        print(html)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone! articles.json saved.')
