import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
for a in part3['articles']:
    text = a.get('text', '')
    if 'Amendment' in text or 'amendment' in text or 'Amended' in text:
        # Print the last 200 chars or so containing "amendment"
        idx = text.lower().find('amendment')
        if idx != -1:
            start = max(0, idx - 100)
            end = min(len(text), idx + 300)
            print(f"Article {a['id']}:")
            print(repr(text[start:end]))
            print("-" * 50)
