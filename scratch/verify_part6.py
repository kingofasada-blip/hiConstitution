import json, sys, io, os

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
    if part_id == 'VI':
        continue
    # Check that the two parts are identical
    orig_str = json.dumps(orig_part, sort_keys=True, ensure_ascii=False)
    new_str = json.dumps(new_part, sort_keys=True, ensure_ascii=False)
    if orig_str != new_str:
        print(f"ERROR: Part {part_id} has been modified!")
        sys.exit(1)
print("SUCCESS: All other parts are completely untouched!")

print("\n--- Step 3: Checking Part 6 articles ---")
new_p6 = next(p for p in new_data if p.get('partId') == 'VI')
articles = new_p6.get('articles', [])
print(f"Total articles in Part 6: {len(articles)}")
if len(articles) != 90:
    print(f"ERROR: Expected 90 articles, found {len(articles)}")
    sys.exit(1)

missing_hindi = 0
missing_hindi_simp = 0
missing_en_simp = 0

for a in articles:
    art_id = a.get('id')
    h = a.get('hindi', '').strip()
    hs = a.get('hindiSimplified', '').strip()
    s = a.get('simplified', '').strip()
    
    if not h:
        print(f"WARNING: Article {art_id} has empty 'hindi'")
        missing_hindi += 1
    if not hs:
        print(f"WARNING: Article {art_id} has empty 'hindiSimplified'")
        missing_hindi_simp += 1
    if not s:
        print(f"WARNING: Article {art_id} has empty 'simplified' (English simplified)")
        missing_en_simp += 1

print(f"Inspection summary:")
print(f"  Missing Hindi original: {missing_hindi}")
print(f"  Missing Hindi simplified: {missing_hindi_simp}")
print(f"  Missing English simplified: {missing_en_simp}")

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

print_art_details('152')
print_art_details('153')
print_art_details('168')
print_art_details('213')
print_art_details('226')
print_art_details('233A')
print_art_details('237')

print("\nVerification completed successfully!")
if missing_hindi == 0 and missing_hindi_simp == 0 and missing_en_simp == 0:
    print("ALL FIELDS COMPLETED FOR ALL 90 ARTICLES!")
else:
    print("Some fields are missing! Check warnings above.")
