
import zipfile, json, sys, io, re
from xml.etree import ElementTree as ET

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

docx_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 1 hindi original.docx'
json_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'

# ── Superscript unicode digits map ───────────────────────────────────
SUPER_MAP = {
    '¹': '1', '²': '2', '³': '3', '⁴': '4', '⁵': '5',
    '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9', '⁰': '0',
}
SUPER_CHARS = set(SUPER_MAP.keys())

def extract_leading_superscripts(text):
    """
    Extract leading superscript digits from text.
    Returns (sup_num_str, rest_text)
    e.g. "¹[text]" -> ("1", "[text]")
    e.g. "²[(ख)...]" -> ("2", "[(ख)...]")
    """
    sup = ''
    i = 0
    while i < len(text) and text[i] in SUPER_CHARS:
        sup += SUPER_MAP[text[i]]
        i += 1
    return (sup, text[i:])

# ── Extract paragraphs from docx with per-run bold info ──────────────
with zipfile.ZipFile(docx_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = ET.parse(f)

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
root = tree.getroot()

para_list = []  # list of {'text': str, 'bold_start': bool}

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
        para_list.append({'text': line, 'bold_start': first_run_bold})

print('Total paragraphs extracted:', len(para_list))
for i, p in enumerate(para_list):
    print(str(i) + ' [bold=' + str(p['bold_start']) + ']: ' + p['text'][:100])
