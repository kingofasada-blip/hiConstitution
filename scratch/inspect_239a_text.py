import json
import os
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')

with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

part8 = next((p for p in data if p.get('partId') == 'VIII'), None)
if part8:
    a = next((art for art in part8.get('articles', []) if art.get('id') == '239A'), None)
    if a:
        print(f"Article 239A text: {repr(a.get('text'))}")
