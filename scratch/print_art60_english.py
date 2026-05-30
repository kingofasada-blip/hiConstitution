import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part5 = next(p for p in data if p.get('partId') == 'V')
art60 = next(a for a in part5['articles'] if a.get('id') == '60')
print("English Article 60 Text:")
print(repr(art60.get('text', '')))
