import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
for a in part2['articles']:
    print(f"Article {a['id']}:")
    print("  English contains 'amend':", 'amend' in a.get('text', '').lower())
    print("  Hindi contains 'संशोधन':", 'संशोधन' in a.get('hindi', '').lower())
