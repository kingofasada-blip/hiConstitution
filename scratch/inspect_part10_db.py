import json
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
JSON_PATH = os.path.join(BASE_DIR, "data", "articles.json")

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

part10 = next(p for p in data if p.get('partId') == 'X')
print(f"Part X details:")
print(f"Part title: {part10.get('title')}")
print(f"Part Hindi title: {part10.get('hindiTitle')}")

for art in part10.get('articles', []):
    print(f"Article ID: {art.get('id')}")
    print(f"Title: {art.get('title')}")
    print(f"Text (English Original): {repr(art.get('text'))}")
    print(f"Hindi (Original): {repr(art.get('hindi'))}")
    print(f"Simplified (English): {repr(art.get('simplified'))}")
    print(f"Hindi Simplified: {repr(art.get('hindiSimplified'))}")
    print("=" * 60)
