import json
import sys
import io
import os
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

TMP_JSON_PATH = os.path.join(r'c:\Users\DeLL\Desktop\hiCONSTITUTION', 'scratch', 'articles_tmp.json')

with open(TMP_JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

new_p8 = next(p for p in data if p.get('partId') == 'VIII')
articles = new_p8.get('articles', [])

print("Running error checks...")
for a in articles:
    art_id = a.get('id')
    h = a.get('hindi', '').strip()
    
    if 'संशोधन' in h:
        if '<strong>संशोधन:</strong>' not in h:
            print(f"FAILED AMENDMENT BOLD: Article {art_id} has 'संशोधन' but not styled as '<strong>संशोधन:</strong>'")
            print(f"  Content: {repr(h[:150])}")
            
    # Check if we have other संशोधन occurrences that might be different
    # Let's count them
    matches = re.findall(r'संशोधन', h)
    strong_matches = re.findall(r'<strong>संशोधन:</strong>', h)
    print(f"Article {art_id}: count of 'संशोधन'={len(matches)}, '<strong>संशोधन:</strong>'={len(strong_matches)}")
