import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

part1 = next(p for p in data if p.get('partId') == 'I')
art3 = next(a for a in part1['articles'] if a.get('id') == '3')

print("English Art 3 text:")
print(repr(art3.get('text', '')))
print("\nHindi Art 3 text:")
print(repr(art3.get('hindi', '')))
