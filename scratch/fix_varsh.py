
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

json_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

part2 = next(p for p in data if p.get('partId') == 'II')
for a in part2['articles']:
    if str(a.get('id')) == '5':
        old = a['hindiSimplified']
        # Fix: "पांच वर्ष</strong>ों" -> "पांच वर्षों</strong>"
        new = old.replace('<strong>पांच वर्ष</strong>ों', '<strong>पांच वर्षों</strong>')
        a['hindiSimplified'] = new
        print('Old snippet:', old[old.find('पांच')-5 : old.find('पांच')+30])
        print('New snippet:', new[new.find('पांच')-5 : new.find('पांच')+30])
        break

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone!')
