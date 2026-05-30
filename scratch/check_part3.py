
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part3 = next(p for p in data if p.get('partId') == 'III')
print('Part III articles:', len(part3['articles']))
print('Keys:', list(part3['articles'][0].keys()))
print()
for a in part3['articles']:
    print('id=' + str(a['id']) + ' | ' + str(a.get('title',''))[:70])
