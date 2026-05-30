
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = None
for p in data:
    if p.get('partId') == 'I':
        part1 = p
        break

print('Part I articles:')
for a in part1['articles']:
    h = a.get('hindi', '')
    print('\n=== Art', a['id'], '===')
    print(h)
