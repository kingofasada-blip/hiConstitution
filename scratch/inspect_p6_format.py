import json
import os
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')

with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

part6 = next((p for p in data if p.get('partId') == 'VI'), None)
if part6:
    for a in part6.get('articles', [])[:2]:
        print(f"Article ID: {a.get('id')}")
        print(f"  hindi: {repr(a.get('hindi'))}")
        print(f"  hindiSimplified: {repr(a.get('hindiSimplified'))}")
        print(f"  simplified: {repr(a.get('simplified'))}")
