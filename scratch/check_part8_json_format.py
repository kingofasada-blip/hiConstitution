import json
import os

BASE_DIR = r"c:\Users\DeLL\Desktop\hiCONSTITUTION"
JSON_PATH = os.path.join(BASE_DIR, "data", "articles.json")

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

part8 = next(p for p in data if p.get('partId') == 'VIII')
out = []
for art in part8['articles'][:3]:
    out.append(f"Article ID: {art.get('id')}")
    out.append(f"Hindi (Original): {art.get('hindi')}")
    out.append(f"Simplified (English): {art.get('simplified')}")
    out.append(f"Hindi Simplified: {art.get('hindiSimplified')}")
    out.append("=" * 60)

with open(os.path.join(BASE_DIR, "scratch", "part8_format_output.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(out))
