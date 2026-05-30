import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
for a in part3['articles'][:5]:
    text = a.get('text', '')
    if 'Amendment:' in text:
        idx = text.find('Amendment:')
        print(f"Article {a['id']} amendment section:")
        print(repr(text[idx:idx+150]))
