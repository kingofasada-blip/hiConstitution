
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = next(p for p in data if p.get('partId') == 'I')
for a in part1['articles']:
    if str(a.get('id')) == '2A':
        print('=== Art 2A English (text) ===')
        print(repr(a.get('text', '')))
        print('\n=== Art 2A Hindi ===')
        print(repr(a.get('hindi', '')))
