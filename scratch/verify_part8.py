import json
import sys
import io
import os
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')

print("--- Step 1: Loading databases ---")
with open(JSON_PATH, 'r', encoding='utf-8') as f:
    orig_data = json.load(f)
with open(TMP_JSON_PATH, 'r', encoding='utf-8') as f:
    new_data = json.load(f)

print("--- Step 2: Checking database integrity for other parts ---")
for orig_part, new_part in zip(orig_data, new_data):
    part_id = orig_part.get('partId')
    if part_id == 'VIII':
        continue
    # Check that the two parts are identical
    orig_str = json.dumps(orig_part, sort_keys=True, ensure_ascii=False)
    new_str = json.dumps(new_part, sort_keys=True, ensure_ascii=False)
    if orig_str != new_str:
        print(f"ERROR: Part {part_id} has been modified!")
        sys.exit(1)
print("SUCCESS: All other parts (I-VII, IX-XXII) are completely untouched!")

print("\n--- Step 3: Checking Part 8 articles ---")
new_p8 = next(p for p in new_data if p.get('partId') == 'VIII')
articles = new_p8.get('articles', [])
print(f"Total articles in Part 8: {len(articles)}")
if len(articles) != 8:
    print(f"ERROR: Expected 8 articles, found {len(articles)}")
    sys.exit(1)

missing_hindi = 0
missing_hindi_simp = 0
missing_en_simp = 0
incorrect_amendment_bold = 0
incorrect_hindi_simp_prefix = 0

for a in articles:
    art_id = a.get('id')
    h = a.get('hindi', '').strip()
    hs = a.get('hindiSimplified', '').strip()
    s = a.get('simplified', '').strip()
    
    if not h:
        print(f"ERROR: Article {art_id} has empty 'hindi'")
        missing_hindi += 1
    if not hs:
        print(f"ERROR: Article {art_id} has empty 'hindiSimplified'")
        missing_hindi_simp += 1
    if not s:
        print(f"ERROR: Article {art_id} has empty 'simplified'")
        missing_en_simp += 1
        
    # Check bolding for amendment header: should be <strong>संशोधन:</strong> or similar, never containing spaces inside or unbolded
    # Look for unbolded संशोधन with colon
    if 'संशोधन :' in h or ('संशोधन:' in h and '<strong>संशोधन:</strong>' not in h):
        print(f"WARNING: Article {art_id} has संशोधन with colon but not styled as <strong>संशोधन:</strong>. Content: {repr(h)}")
        incorrect_amendment_bold += 1
            
    # Check if hindiSimplified is prepended with <strong>सारांश टिप्पणी:</strong> 
    if hs and not hs.startswith('<strong>सारांश टिप्पणी:</strong> '):
        print(f"ERROR: Article {art_id} does not start with '<strong>सारांश टिप्पणी:</strong> '")
        incorrect_hindi_simp_prefix += 1

print(f"\nInspection summary:")
print(f"  Missing Hindi original: {missing_hindi}")
print(f"  Missing Hindi simplified: {missing_hindi_simp}")
print(f"  Missing English simplified: {missing_en_simp}")
print(f"  Incorrect amendment bold formatting: {incorrect_amendment_bold}")
print(f"  Incorrect Hindi simplified prefix formatting: {incorrect_hindi_simp_prefix}")

def print_art_details(art_id):
    a = next(art for art in articles if art.get('id') == art_id)
    print(f"\n=== Article {a['id']} ===")
    print("Hindi Original:")
    print(repr(a.get('hindi', '')))
    print("Hindi Simplified:")
    print(repr(a.get('hindiSimplified', '')))
    print("English Simplified:")
    print(repr(a.get('simplified', '')))
    print("-" * 60)

print_art_details('239')
print_art_details('239A')
print_art_details('239AA')
print_art_details('239AB')
print_art_details('240')
print_art_details('242')

print("\nVerification completed successfully!")
if (missing_hindi == 0 and missing_hindi_simp == 0 and missing_en_simp == 0 and 
    incorrect_amendment_bold == 0 and incorrect_hindi_simp_prefix == 0):
    print("ALL CHECKS PASSED SUCCESSFULLY FOR PART 8!")
else:
    print("SOME CHECKS FAILED! Check error messages above.")
    sys.exit(1)
