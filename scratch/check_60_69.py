import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part5 = next(p for p in data if p.get('partId') == 'V')
for art_id in ['60', '69']:
    a = next(art for art in part5['articles'] if art.get('id') == art_id)
    print(f"=== Article {a['id']} ===")
    print("Hindi Original:")
    print(repr(a.get('hindi', '')))
    print("Hindi Simplified:")
    print(repr(a.get('hindiSimplified', '')))
    print("-" * 60)
