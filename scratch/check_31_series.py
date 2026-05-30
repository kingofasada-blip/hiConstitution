import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
for a in part3['articles']:
    if '31' in a['id']:
        print(f"Article {a['id']}:")
        print("  has text:", bool(a.get('text', '').strip()))
        print("  has simplified:", bool(a.get('simplified', '').strip()))
        print("  simplified preview:", repr(a.get('simplified', ''))[:150])
        print("  has hindi:", bool(a.get('hindi', '').strip()))
        print("  has hindiSimplified:", bool(a.get('hindiSimplified', '').strip()))
