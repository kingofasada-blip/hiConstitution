import json, sys, io, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
for a in part2['articles']:
    simp = a.get('simplified', '')
    bolds = re.findall(r'<strong>(.*?)</strong>', simp)
    print(f"Article {a['id']}: {bolds}")
