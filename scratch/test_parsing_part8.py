import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

SUPER_MAP = {'¹':'1','²':'2','³':'3','⁴':'4','⁵':'5',
             '⁶':'6','⁷':'7','⁸':'8','⁹':'9','⁰':'0'}
SUPER_CHARS = set(SUPER_MAP.keys())

def get_article_key_from_runs(line, runs_data):
    # regex for match
    heading_pat_art = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*अनुच्छेद\s+(\d+[क-हA-Za-z]*)')
    heading_pat_num = re.compile(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰]*\s*\[?\s*(\d+[क-हA-Za-z]*)\.')
    
    m = heading_pat_art.match(line)
    if m:
        art_num = m.group(1)
        for r in runs_data:
            if art_num in r['text'] and r['bold']:
                return art_num
        for r in runs_data:
            if 'अनुच्छेद' in r['text'] and r['bold']:
                return art_num
                
    m = heading_pat_num.match(line)
    if m:
        art_num = m.group(1)
        for r in runs_data:
            if art_num in r['text'] and r['bold']:
                return art_num
                
    return None

def is_amendment_header_from_runs(line, runs_data):
    cleaned = line.strip().rstrip(':').replace(' ', '')
    return cleaned == 'संशोधन'

# Let's read from the dump file and parse it back to see what matches
with open('scratch/part8_original_hindi_dump.txt', 'r', encoding='utf-8') as f:
    dump_content = f.read()

paras = []
import ast
# We can parse the dump by splitting paragraphs
p_blocks = dump_content.split('\n\n')
for block in p_blocks:
    if not block.strip():
        continue
    lines = block.strip().split('\n')
    if len(lines) < 3:
        continue
    p_num = lines[0]
    raw_line = lines[1].replace('  Raw: ', '')
    runs_line = lines[2].replace('  Runs: ', '')
    try:
        runs_data_list = ast.literal_eval(runs_line)
    except Exception as e:
        print(f"Error parsing runs line: {runs_line}, error: {e}")
        continue
    
    runs_data = [{'text': r[0], 'bold': r[1]} for r in runs_data_list]
    
    art_key = get_article_key_from_runs(raw_line, runs_data)
    is_amend = is_amendment_header_from_runs(raw_line, runs_data)
    
    paras.append({
        'p_num': p_num,
        'raw': raw_line,
        'runs': runs_data,
        'heading_key': art_key,
        'is_amendment': is_amend
    })

print(f"Successfully loaded {len(paras)} paragraphs from dump.")
print("--- Matching Headings ---")
for p in paras:
    if p['heading_key']:
        print(f"{p['p_num']}: Key={p['heading_key']} | Raw: {p['raw']}")
print("--- Matching Amendments ---")
for p in paras:
    if p['is_amendment']:
        print(f"{p['p_num']}: Raw: {p['raw']}")
