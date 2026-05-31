import json
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
JSON_PATH = os.path.join(BASE_DIR, "data", "articles.json")

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

part10 = next(p for p in data if p.get('partId') == 'X')
out = []
out.append(f"Part title: {part10.get('title')}")
out.append(f"Part Hindi title: {part10.get('hindiTitle')}\n")

for art in part10.get('articles', []):
    out.append(f"Article ID: {art.get('id')}")
    out.append(f"Title: {art.get('title')}")
    out.append(f"Text (English Original): {art.get('text')}")
    out.append(f"Hindi (Original): {art.get('hindi')}")
    out.append(f"Simplified (English): {art.get('simplified')}")
    out.append(f"Hindi Simplified: {art.get('hindiSimplified')}")
    out.append("=" * 60)

with open(os.path.join(BASE_DIR, "scratch", "part10_current.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("Dumped current Part X database state to scratch/part10_current.txt")
