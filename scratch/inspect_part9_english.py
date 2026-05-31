import json
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
JSON_PATH = os.path.join(BASE_DIR, "data", "articles.json")

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

out = []
target_parts = ["IX", "IXA", "IXB"]

for part in data:
    part_id = part.get("partId")
    if part_id in target_parts:
        out.append(f"\n==================== Part {part_id} English ====================\n")
        for art in part.get("articles", []):
            out.append(f"Article ID: {art.get('id')}")
            out.append(f"Title: {art.get('title')}")
            out.append(f"Text (English Original): {art.get('text')}\n")

with open(os.path.join(BASE_DIR, "scratch", "part9_english_text.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("Dumped English text to scratch/part9_english_text.txt")
