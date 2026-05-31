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
JSON_PATH = os.path.join(BASE_DIR, 'data', 'schedules.json')
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'schedules_tmp.json')

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

# Names of States and UTs to bold at the start of entries
STATES_EN = ["Andhra Pradesh", "Assam", "Bihar", "Gujarat", "Kerala", "Madhya Pradesh", 
             "Tamil Nadu", "Maharashtra", "Karnataka", "Odisha", "Punjab", "Rajasthan", 
             "Uttar Pradesh", "West Bengal", "Nagaland", "Haryana", "Himachal Pradesh", 
             "Manipur", "Tripura", "Meghalaya", "Sikkim", "Mizoram", "Arunachal Pradesh", 
             "Goa", "Chhattisgarh", "Uttarakhand", "Jharkhand", "Telangana"]

UTS_EN = ["Delhi", "The Andaman and Nicobar Islands", "Lakshadweep", 
          "Dadra and Nagar Haveli and Daman and Diu", "Puducherry", "Chandigarh", 
          "Jammu and Kashmir", "Ladakh"]

NAMES_EN = sorted(STATES_EN + UTS_EN, key=len, reverse=True)

STATES_HI = ["आंध्र प्रदेश", "असम", "बिहार", "गुजरात", "केरल", "मध्य प्रदेश", 
             "तमिलनाडु", "महाराष्ट्र", "कर्नाटक", "ओडिशा", "पंजाब", "राजस्थान", 
             "उत्तर प्रदेश", "पश्चिमी बंगाल", "नागालैंड", "हरियाणा", "हिमाचल प्रदेश", 
             "मणिपुर", "त्रिपुरा", "मेघालय", "सिक्किम", "मिजोरम", "अरुणाचल प्रदेश", 
             "गोवा", "छत्तीसगढ़", "उत्तराखंड", "झारखंड", "तेलंगाना"]

UTS_HI = ["दिल्ली", "अंदमान और निकोबार द्वीप", "लक्षद्वीप", 
          "दादरा और नागर हवेली और दमण और दीव", "पुडुचेरी", "चंडीगढ़", 
          "जम्मू-कश्मीर", "लद्दाख"]

NAMES_HI = sorted(STATES_HI + UTS_HI, key=len, reverse=True)

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

def bold_name_at_start(para_text, name_list):
    for name in name_list:
        idx = para_text.find(name)
        if idx != -1:
            prefix = para_text[:idx]
            # Ensure the prefix only contains characters commonly found before the name
            if re.match(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰\d\.\s\[\]\*\-\—<>supstrong/]*$', prefix):
                rest = para_text[idx + len(name):]
                return prefix + f"<strong>{name}</strong>" + rest
    return para_text

def extract_para_text_with_bold(para):
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
            
    if not runs_data:
        return ""
        
    parts = []
    current_bold = None
    current_text = []
    
    for r in runs_data:
        if current_bold is None:
            current_bold = r['bold']
            current_text.append(r['text'])
        elif current_bold == r['bold']:
            current_text.append(r['text'])
        else:
            combined = ''.join(current_text)
            if current_bold:
                parts.append('<strong>' + combined + '</strong>')
            else:
                parts.append(combined)
            current_bold = r['bold']
            current_text = [r['text']]
            
    if current_text:
        combined = ''.join(current_text)
        if current_bold:
            parts.append('<strong>' + combined + '</strong>')
        else:
            parts.append(combined)
            
    full_text = ''.join(parts)
    return full_text

def main():
    docx_path = os.path.join(BASE_DIR, 'schedule 1  original english and hindi text.docx')
    print(f"Reading First Schedule document: {docx_path}")
    
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    
    paras = []
    for para in root.iter('{%s}p' % W):
        formatted = extract_para_text_with_bold(para).strip()
        if formatted:
            paras.append(formatted)
            
    print(f"Total non-empty formatted paragraphs: {len(paras)}")
    
    # ----------------------------------------------------
    # Process English Section (index 0 to 101)
    # ----------------------------------------------------
    english_paras = []
    
    # Heading (index 0)
    heading_en = process_superscripts(paras[0])
    english_paras.append(heading_en)
    
    # Body (index 1 to 42)
    english_paras.append(process_superscripts(paras[1]))
    
    for p in paras[2:31]:
        processed = process_superscripts(p)
        bolded = bold_name_at_start(processed, NAMES_EN)
        english_paras.append(bolded)
        
    english_paras.append(process_superscripts(paras[31]))
    
    for p in paras[32:43]:
        processed = process_superscripts(p)
        bolded = bold_name_at_start(processed, NAMES_EN)
        english_paras.append(bolded)
        
    # Amendments Collapsible Container
    amend_start = "<details><summary style='cursor: pointer; font-weight: 700; color: var(--navy); outline: none; margin-top: 20px; user-select: none;'>Amendments (Click to expand)</summary><div style='margin-top: 10px; font-size: 0.95rem; line-height: 1.65;'>"
    
    # Footnotes (index 44 to 101)
    for idx, p in enumerate(paras[44:102]):
        clean_p = process_superscripts(p)
        footnote_text = f"<sup><strong>{idx+1}</strong></sup> {clean_p}"
        if idx == 0:
            english_paras.append(amend_start + footnote_text)
        elif idx == len(paras[44:102]) - 1:
            english_paras.append(footnote_text + "</div></details>")
        else:
            english_paras.append(footnote_text)
        
    details_content = "\n".join(english_paras)
    
    # ----------------------------------------------------
    # Process Hindi Section (index 102 to 203)
    # ----------------------------------------------------
    hindi_paras = []
    
    # Heading (index 102)
    heading_hi = process_superscripts(paras[102])
    hindi_paras.append(heading_hi)
    
    # Body (index 103 to 144)
    hindi_paras.append(process_superscripts(paras[103]))
    
    for p in paras[104:133]:
        processed = process_superscripts(p)
        bolded = bold_name_at_start(processed, NAMES_HI)
        hindi_paras.append(bolded)
        
    hindi_paras.append(process_superscripts(paras[133]))
    
    for p in paras[134:145]:
        processed = process_superscripts(p)
        bolded = bold_name_at_start(processed, NAMES_HI)
        hindi_paras.append(bolded)
        
    # Amendments Collapsible Container (Hindi)
    amend_start_hi = "<details><summary style='cursor: pointer; font-weight: 700; color: var(--navy); outline: none; margin-top: 20px; user-select: none;'>संशोधन (विस्तार के लिए क्लिक करें)</summary><div style='margin-top: 10px; font-size: 0.95rem; line-height: 1.65;'>"
    
    # Footnotes (index 146 to 203)
    for idx, p in enumerate(paras[146:204]):
        clean_p = process_superscripts(p)
        footnote_text = f"<sup>{idx+1}</sup> {clean_p}"
        if idx == 0:
            hindi_paras.append(amend_start_hi + footnote_text)
        elif idx == len(paras[146:204]) - 1:
            hindi_paras.append(footnote_text + "</div></details>")
        else:
            hindi_paras.append(footnote_text)
        
    hindi_content = "\n".join(hindi_paras)
    
    # ----------------------------------------------------
    # Update JSON
    # ----------------------------------------------------
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        db = json.load(f)
        
    sch1 = next((s for s in db if s['id'] == '1'), None)
    if sch1 is None:
        print("ERROR: First Schedule entry not found in database!")
        sys.exit(1)
        
    sch1['details'] = details_content
    sch1['hindi'] = hindi_content
    
    with open(TMP_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully wrote temporary schedules database to {TMP_JSON_PATH}")

if __name__ == '__main__':
    main()
