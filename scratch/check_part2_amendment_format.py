import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
for a in part2['articles']:
    text = a.get('text', '')
    if 'Amendment:' in text:
        idx = text.find('Amendment:')
        print(f"Article {a['id']} English amendment section:")
        print(repr(text[idx:idx+150]))
    
    hin = a.get('hindi', '')
    if 'संशोधन:' in hin:
        idx = hin.find('संशोधन:')
        print(f"Article {a['id']} Hindi amendment section:")
        print(repr(hin[idx:idx+150]))
