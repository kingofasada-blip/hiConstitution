import json, sys, io, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
for a in part3['articles']:
    simp = a.get('simplified', '')
    bolds = re.findall(r'<strong>(.*?)</strong>', simp)
    if bolds:
        print(f"Article {a['id']}: {bolds}")
