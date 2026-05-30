import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
art12 = next(a for a in part3['articles'] if a.get('id') == '12')
print(json.dumps(art12, ensure_ascii=False, indent=2))
