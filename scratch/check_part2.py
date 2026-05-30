
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
print('Part II - articles:', len(part2['articles']))
print('Keys in article:', list(part2['articles'][0].keys()))
print()
for a in part2['articles']:
    print('id=' + str(a['id']) + ' | ' + str(a.get('title',''))[:70])
