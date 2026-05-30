
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = next(p for p in data if p.get('partId') == 'I')
print('=== All keys in article ===')
print(list(part1['articles'][0].keys()))

for a in part1['articles']:
    if a.get('id') in ['1','2','2A','3','4'] or str(a.get('id')) in ['1','2','2A','3','4']:
        print('\n--- Art', a['id'], '---')
        print('simplified:', repr(a.get('simplified', '(empty)')))
