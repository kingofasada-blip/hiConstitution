import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\scratch\articles_tmp.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Find articles by ID
def print_article(art_id, part_id):
    part = next(p for p in data if p.get('partId') == part_id)
    a = next(art for art in part['articles'] if art.get('id') == art_id)
    print(f"=== Article {a['id']} (Part {part_id}) ===")
    print("Hindi Original:")
    print(repr(a.get('hindi', '')))
    print("Hindi Simplified:")
    print(repr(a.get('hindiSimplified', '')))
    print("-" * 60)

# Check target articles
print_article('19', 'III')
print_article('33', 'III')
print_article('31A', 'III')
print_article('31B', 'III')
print_article('31C', 'III')
print_article('39A', 'IV')
print_article('52', 'V')
print_article('124A', 'V')
print_article('150', 'V')
