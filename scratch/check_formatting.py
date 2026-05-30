import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for part in data:
    if part.get('partId') in ['I', 'II']:
        print(f"=== Part {part.get('partId')} ===")
        for art in part.get('articles', [])[:2]:
            print(f"Article {art.get('id')}:")
            print("Hindi:", repr(art.get('hindi', ''))[:300])
            print("Hindi Simplified:", repr(art.get('hindiSimplified', ''))[:300])
