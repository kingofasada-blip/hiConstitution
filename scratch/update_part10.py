import zipfile
import xml.etree.ElementTree as ET
import os
import json
import sys
import io
import re

# Set stdout to UTF-8 to prevent encoding errors on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

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

def get_non_empty_paras(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        full_text, runs_data = extract_para_text_with_br(para)
        if full_text.strip():
            para_list.append((full_text.strip(), runs_data))
    return para_list

def format_english_heading(heading_text, has_superscript_1=False):
    # Clean heading text
    heading_text = heading_text.strip()
    # Strip leading superscript indicators like ¹[ or [ if any
    heading_text = re.sub(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?', '', heading_text)
    # Strip trailing dash/period/colon/spaces
    heading_text = re.sub(r'[\s—–\-\.:]+$', '', heading_text)
    # Prepend Article
    if not heading_text.startswith('Article'):
        m = re.match(r'^(\d+[A-Za-z]?)\.?\s*(.*)', heading_text)
        if m:
            num, rest = m.groups()
            heading_text = f"Article {num}. {rest}"
    
    if has_superscript_1:
        return f"<strong><sup>1</sup>[{heading_text}.-</strong>"
    else:
        return f"<strong>{heading_text}.-</strong>"

def main():
    original_docx = os.path.join(BASE_DIR, 'part9b_extracted_docx', 'part 10 original hindi and english.docx')
    simplified_docx = os.path.join(BASE_DIR, 'part9b_extracted_docx', 'part 10 simplify  hindi and english.docx')
    
    print(f"Reading original document: {original_docx}")
    orig_paras = get_non_empty_paras(original_docx)
    print(f"Total non-empty paragraphs: {len(orig_paras)}")
    
    print(f"Reading simplified document: {simplified_docx}")
    simp_paras = get_non_empty_paras(simplified_docx)
    print(f"Total non-empty paragraphs: {len(simp_paras)}")
    
    # ----------------------------------------------------
    # Parse English Original (Paras 0 to 21)
    # ----------------------------------------------------
    
    # Article 244 English
    # Para 1 has heading + start of body
    para1_text, para1_runs = orig_paras[1]
    # We find where heading ends: heading is bold.
    bold_parts = []
    plain_parts = []
    for run in para1_runs:
        if run['bold']:
            bold_parts.append(run['text'])
        else:
            plain_parts.append(run['text'])
            
    heading_244_en = "".join(bold_parts).strip()
    body_start_244_en = "".join(plain_parts).strip()
    # Strip leading dash/spaces from body start
    body_start_244_en = re.sub(r'^[\s—–\-]+', '', body_start_244_en).strip()
    
    formatted_heading_244_en = format_english_heading(heading_244_en)
    clause1_244_en = process_superscripts(body_start_244_en)
    clause2_244_en = process_superscripts(orig_paras[2][0])
    
    # Amendments for 244
    # Para 3 is 'Amendments:'
    # Paras 4 to 8 are the 5 footnote lines
    amendments_244_en = []
    for idx, (text, _) in enumerate(orig_paras[4:9]):
        clean_text = process_superscripts(text.strip())
        amendments_244_en.append(f"<sup><strong>{idx+1}</strong></sup> {clean_text}")
        
    text_244 = formatted_heading_244_en + "\n" + clause1_244_en + "\n" + clause2_244_en + "\n" + "<strong>Amendments:</strong>" + "\n" + "\n".join(amendments_244_en)
    
    # Article 244A English
    # Para 9 is heading: has ¹[ at start (plain), then bold title, then — (plain)
    para9_text, para9_runs = orig_paras[9]
    bold_parts_244a = []
    for run in para9_runs:
        if run['bold']:
            bold_parts_244a.append(run['text'])
    heading_244a_en = "".join(bold_parts_244a).strip()
    formatted_heading_244a_en = format_english_heading(heading_244a_en, has_superscript_1=True)
    
    # Paras 10 to 18 are clauses
    clauses_244a_en = []
    for text, _ in orig_paras[10:19]:
        clauses_244a_en.append(process_superscripts(text))
        
    # Amendments for 244A
    # Para 19 is 'Amendments:'
    # Paras 20 and 21 are the footnotes
    amendments_244a_en = []
    for idx, (text, _) in enumerate(orig_paras[20:22]):
        clean_text = process_superscripts(text.strip())
        amendments_244a_en.append(f"<sup><strong>{idx+1}</strong></sup> {clean_text}")
        
    text_244a = formatted_heading_244a_en + "\n" + "\n".join(clauses_244a_en) + "\n" + "<strong>Amendments:</strong>" + "\n" + "\n".join(amendments_244a_en)

    # ----------------------------------------------------
    # Parse Hindi Original (Paras 22 to 46)
    # ----------------------------------------------------
    
    # Article 244 Hindi
    # Para 23: Heading
    para23_text, para23_runs = orig_paras[23]
    bold_parts_244_hi = []
    for run in para23_runs:
        if run['bold']:
            bold_parts_244_hi.append(run['text'])
    heading_244_hi = "".join(bold_parts_244_hi).strip()
    heading_244_hi = re.sub(r'[\s—–\-:]+$', '', heading_244_hi).strip()
    formatted_heading_244_hi = f"<strong>{heading_244_hi}—</strong>"
    
    # Paras 24 and 25 are clauses
    clause1_244_hi = process_superscripts(orig_paras[24][0])
    clause2_244_hi = process_superscripts(orig_paras[25][0])
    
    # Amendments for 244
    # Para 26 is 'संशोधन:'
    # Paras 27 to 31 are footnotes
    amendments_244_hi = []
    for idx, (text, _) in enumerate(orig_paras[27:32]):
        clean_text = process_superscripts(text.strip())
        # Strip leading superscript characters or digits if present
        clean_text = re.sub(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰\d\.\s]+', '', clean_text)
        amendments_244_hi.append(f"<sup>{idx+1}</sup> {clean_text}")
        
    hindi_244 = formatted_heading_244_hi + "`n" + clause1_244_hi + "`n" + clause2_244_hi + "`n" + "<strong>संशोधन:</strong>" + "`n" + "`n".join(amendments_244_hi)

    # Article 244A Hindi
    # Para 32: Heading
    para32_text, para32_runs = orig_paras[32]
    bold_parts_244a_hi = []
    for run in para32_runs:
        if run['bold']:
            bold_parts_244a_hi.append(run['text'])
    heading_244a_hi = "".join(bold_parts_244a_hi).strip()
    heading_244a_hi = re.sub(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?', '', heading_244a_hi)
    heading_244a_hi = re.sub(r'[\s—–\-:]+$', '', heading_244a_hi).strip()
    formatted_heading_244a_hi = f"<strong><sup>1</sup>[{heading_244a_hi}—</strong>"
    
    # Paras 33 to 43 are clauses
    clauses_244a_hi = []
    for text, _ in orig_paras[33:44]:
        clauses_244a_hi.append(process_superscripts(text))
        
    # Amendments for 244A
    # Para 44 is 'संशोधन:'
    # Paras 45 and 46 are footnotes
    amendments_244a_hi = []
    for idx, (text, _) in enumerate(orig_paras[45:47]):
        clean_text = process_superscripts(text.strip())
        clean_text = re.sub(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰\d\.\s]+', '', clean_text)
        amendments_244a_hi.append(f"<sup>{idx+1}</sup> {clean_text}")
        
    hindi_244a = formatted_heading_244a_hi + "`n" + "`n".join(clauses_244a_hi) + "`n" + "<strong>संशोधन:</strong>" + "`n" + "`n".join(amendments_244a_hi)

    # ----------------------------------------------------
    # Parse Simplified explanations (Paras 0 to 6)
    # ----------------------------------------------------
    
    # Article 244 Simplified
    # Para 2: Simplified : ...
    # Para 3: सारांश टिप्पणी:  ...
    simp_244_en = re.sub(r'^Simplified\s*:\s*', '', simp_paras[2][0], flags=re.IGNORECASE).strip()
    simp_244_hi = re.sub(r'^सारांश टिप्पणी\s*:\s*', '', simp_paras[3][0]).strip()
    simp_244_hi = re.sub(r'^सारांश टिप्पणी\s*', '', simp_244_hi).strip() # just in case of double spacing
    formatted_simp_244_hi = f"<strong>सारांश टिप्पणी:</strong> {simp_244_hi}"
    
    # Article 244A Simplified
    # Para 5: Simplified : ...
    # Para 6: सारांश टिप्पणी:  ...
    simp_244a_en = re.sub(r'^Simplified\s*:\s*', '', simp_paras[5][0], flags=re.IGNORECASE).strip()
    simp_244a_hi = re.sub(r'^सारांश टिप्पणी\s*:\s*', '', simp_paras[6][0]).strip()
    simp_244a_hi = re.sub(r'^सारांश टिप्पणी\s*', '', simp_244a_hi).strip()
    formatted_simp_244a_hi = f"<strong>सारांश टिप्पणी:</strong> {simp_244a_hi}"

    # ----------------------------------------------------
    # Generate Previews
    # ----------------------------------------------------
    # First ~140 characters of English clauses, ending with ...
    preview_244 = clause1_244_en[:140].strip() + "..."
    preview_244a = clauses_244a_en[0][:140].strip() + "..."

    # ----------------------------------------------------
    # Update JSON database
    # ----------------------------------------------------
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        db = json.load(f)
        
    part_x = next((p for p in db if p['partId'] == 'X'), None)
    if part_x is None:
        print("ERROR: Part X not found in database!")
        sys.exit(1)
        
    print("Found Part X.")
    
    # Build updated Article objects
    art_244_obj = {
        "id": "244",
        "title": "Article 244: Administration of Scheduled Areas and Tribal Areas",
        "preview": preview_244,
        "text": text_244,
        "simplified": simp_244_en,
        "hindi": hindi_244,
        "hindiSimplified": formatted_simp_244_hi
    }
    
    art_244a_obj = {
        "id": "244A",
        "title": "Article 244A: Formation of an autonomous State comprising certain tribal areas in Assam and creation of local Legislature or Council of Ministers or both therefor",
        "preview": preview_244a,
        "text": text_244a,
        "simplified": simp_244a_en,
        "hindi": hindi_244a,
        "hindiSimplified": formatted_simp_244a_hi
    }
    
    # Set the articles under Part X
    part_x['articles'] = [art_244_obj, art_244a_obj]
    print("Updated Part X articles.")
    
    # Write to tmp JSON path
    with open(TMP_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully wrote temporary database to {TMP_JSON_PATH}")

if __name__ == '__main__':
    main()
