
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

json_path = r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json'

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = next(p for p in data if p.get('partId') == 'I')
for a in part1['articles']:
    if str(a.get('id')) == '2A':
        old = a['hindi']
        # Remove "<sup>1</sup> " from before the amendment note line
        new = old.replace('<sup>1</sup> संविधान', 'संविधान')
        a['hindi'] = new
        print('Old:', repr(old))
        print('\nNew:', repr(new))
        break

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nDone!')
