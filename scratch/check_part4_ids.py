import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part4 = next((p for p in data if p.get('partId') == 'IV'), None)
if part4:
    print("Part IV Articles:")
    for a in part4['articles']:
        print(a['id'])
else:
    print("Part IV not found!")
