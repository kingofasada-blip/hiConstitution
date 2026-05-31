import zipfile
import xml.etree.ElementTree as ET
import os
import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"

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

def clean_key(num_part, suffix_part):
    num = num_part.strip()
    suff = map_hindi_suffix(suffix_part)
    return f"{num}{suff}".upper()

def extract_simplified_docx(docx_path):
    if not os.path.exists(docx_path):
        print(f"File not found: {docx_path}")
        return []
    
    with zipfile.ZipFile(docx_path, 'r') as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    para_list = []
    for para in root.iter('{%s}p' % W):
        runs = list(para.iter('{%s}r' % W))
        if not runs: continue
        
        run_texts = []
        runs_data = []
        for r in runs:
            rpr = r.find('{%s}rPr' % W)
            is_bold = rpr is not None and (rpr.find('{%s}b' % W) is not None or rpr.find('{%s}bCs' % W) is not None)
            
            t = r.find('{%s}t' % W)
            if t is not None and t.text:
                run_texts.append(t.text)
                runs_data.append((t.text, is_bold))
        
        full_text = "".join(run_texts).strip()
        if full_text:
            first_bold = runs_data[0][1] if runs_data else False
            para_list.append({'text': full_text, 'bold': first_bold})
    return para_list

def parse_simplified_file(docx_path, name):
    print(f"\n==================== Simplified File: {name} ====================")
    paras = extract_simplified_docx(docx_path)
    print(f"Total paragraphs extracted: {len(paras)}")
    
    i = 0
    parsed = {}
    while i < len(paras):
        p = paras[i]
        # Check if it's an article header
        # Pattern in simplify files is: "Article 243: Definitions. (परिभाषाएं)" or "Article 243A: Gram Sabha. (ग्राम सभा)"
        # Sometimes there could be multiple articles like "Article 243ZH to 243ZT" or something? Let's check.
        if p['text'].startswith('Article'):
            print(f"\nHeader line: '{p['text']}'")
            # Extract keys using regex
            art_keys = re.findall(r'(\d+[A-Za-z]*)', p['text'])
            print(f"Keys extracted: {art_keys}")
            
            # Find the following Simplified (English) and सारांश टिप्पणी (Hindi) paragraphs
            clean_en = ""
            clean_hi = ""
            
            # Look ahead for next 4 paragraphs to find English and Hindi summaries
            j = i + 1
            found_en = False
            found_hi = False
            while j < min(i + 5, len(paras)):
                next_p = paras[j]
                if next_p['text'].startswith('Article'):
                    # We hit the next article without finding English/Hindi? Break.
                    break
                
                # Check for English Simplified
                if next_p['text'].lower().startswith('simplified') and not found_en:
                    # Strip "Simplified :" prefix case insensitively
                    clean_en = re.sub(r'^Simplified\s*:\s*', '', next_p['text'], flags=re.IGNORECASE).strip()
                    found_en = True
                    print(f"  En found at offset {j-i}: '{clean_en[:60]}...'")
                
                # Check for Hindi Summary (सारांश टिप्पणी)
                if (next_p['text'].startswith('सारांश टिप्पणी') or next_p['text'].startswith('सारांश टिपण्णी')) and not found_hi:
                    # Strip "सारांश टिप्पणी:" prefix
                    clean_hi = re.sub(r'^सारांश टिप्पणी\s*:\s*', '', next_p['text']).strip()
                    clean_hi = re.sub(r'^सारांश टिपण्णी\s*:\s*', '', clean_hi).strip()
                    found_hi = True
                    print(f"  Hi found at offset {j-i}: '{clean_hi[:60]}...'")
                
                j += 1
            
            # If we didn't find them explicitly with prefixes, let's look at the paragraphs sequentially
            if not found_en and not found_hi:
                # If they don't have prefixes, the first paragraph after header is usually English and the second is Hindi
                if i + 1 < len(paras) and not paras[i+1]['text'].startswith('Article'):
                    clean_en = paras[i+1]['text']
                    print(f"  Fallback En: '{clean_en[:60]}...'")
                if i + 2 < len(paras) and not paras[i+2]['text'].startswith('Article'):
                    clean_hi = paras[i+2]['text']
                    print(f"  Fallback Hi: '{clean_hi[:60]}...'")
            
            for k in art_keys:
                parsed[k.upper()] = {
                    'english': clean_en,
                    'hindi': clean_hi
                }
            
            # Advance i to j - 1
            i = j
            continue
        i += 1
        
    print(f"Total parsed articles: {len(parsed)}")
    print(f"Parsed keys: {list(parsed.keys())}")
    return parsed

# Test parsing
p9_simp = parse_simplified_file(os.path.join(BASE_DIR, 'part 9 simplify  hindi and english.docx'), "Part 9 Simplify")
p9a_simp = parse_simplified_file(os.path.join(BASE_DIR, 'part 9A simplify  hindi and english.docx'), "Part 9A Simplify")
p9b_simp = parse_simplified_file(os.path.join(BASE_DIR, 'part 9B simplify  hindi and english.docx'), "Part 9B Simplify")
