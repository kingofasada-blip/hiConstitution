import json
import os

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')

with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

part8 = next((p for p in data if p.get('partId') == 'VIII'), None)
if part8:
    print(f"Part ID: {part8.get('partId')}, Part Name: {part8.get('partName')}")
    print(f"Number of articles: {len(part8.get('articles', []))}")
    for a in part8.get('articles', []):
        print(f"Article ID: {a.get('id')}, Title: {a.get('title')}, Fields: {list(a.keys())}")
        # print first few chars of each field
        for key in ['title', 'simplified', 'hindi', 'hindiSimplified']:
            val = a.get(key, '')
            print(f"  {key}: {repr(val[:100])}")
else:
    print("Part VIII not found")
