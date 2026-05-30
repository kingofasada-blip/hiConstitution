import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part5 = next((p for p in data if p.get('partId') == 'V'), None)
if part5:
    print("Part V Articles:")
    ids = [a['id'] for a in part5['articles']]
    print(len(ids), "articles found. Range:", ids[0], "to", ids[-1])
    print("All IDs:", ids)
else:
    print("Part V not found!")
