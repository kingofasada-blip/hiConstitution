import json
import os

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_TMP_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')

with open(JSON_TMP_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

check_ids = ["243", "243A", "243M", "243ZH", "243ZT"]
out = []

for part in data:
    for art in part.get('articles', []):
        art_id = art['id']
        if art_id in check_ids:
            out.append(f"==================== Article {art_id} ====================")
            out.append(f"Title: {art.get('title')}")
            out.append(f"Hindi (Original): {art.get('hindi')}")
            out.append(f"Simplified (English): {art.get('simplified')}")
            out.append(f"Hindi Simplified: {art.get('hindiSimplified')}")
            out.append("\n")

with open(os.path.join(BASE_DIR, 'scratch', 'manual_inspection.txt'), 'w', encoding='utf-8') as f:
    f.write("\n".join(out))

print("Dumped manual inspection details to scratch/manual_inspection.txt")
