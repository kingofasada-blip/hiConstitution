import json
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
JSON_PATH = os.path.join(BASE_DIR, "data", "articles.json")

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

target_parts = ["IX", "IXA", "IXB"]

for part in data:
    part_id = part.get("partId")
    if part_id in target_parts:
        print(f"Part ID: {part_id}")
        print(f"Title: {part.get('title')}")
        print(f"Hindi Title: {part.get('hindiTitle', 'N/A')}")
        print("Articles:")
        for art in part.get("articles", []):
            print(f"  - ID: {art.get('id')} | Title: {art.get('title')} | Hindi present: {bool(art.get('hindi'))} | Simplified present: {bool(art.get('simplified'))} | HindiSimplified present: {bool(art.get('hindiSimplified'))}")
        print("-" * 50)
