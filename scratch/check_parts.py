
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for i, part in enumerate(data):
    pid = part.get('partId', '')
    ptitle = part.get('partTitle', '')[:60]
    arts = part.get('articles', [])
    print(str(i) + ' | partId=' + str(pid) + ' | title=' + ptitle + ' | articles=' + str(len(arts)))

# Show Part 1 first article structure
print('\n--- PART 1 DETAIL ---')
part1 = data[0]
arts = part1.get('articles', [])
if arts:
    a = arts[0]
    print('Article keys:', list(a.keys()))
    print('number:', a.get('number', a.get('articleNumber', '')))
    print('title_hi:', str(a.get('title_hi', a.get('titleHi', '')))[:100])
    print('text_hi:', str(a.get('text_hi', a.get('textHi', a.get('hindi', ''))))[:300])
    print('text_en:', str(a.get('text_en', a.get('textEn', a.get('english', ''))))[:200])
