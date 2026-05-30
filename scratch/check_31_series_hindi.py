import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
for a in part3['articles']:
    if a['id'] in ['31', '31A', '31B', '31C', '31D']:
        print(f"Article {a['id']}:")
        print("  Hindi:", repr(a.get('hindi', ''))[:150])
        print("  Hindi Simplified:", repr(a.get('hindiSimplified', ''))[:150])
