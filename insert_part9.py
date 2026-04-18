import json
import re

with open("part9_raw.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()

articles = []
current_art = None

art_pattern = re.compile(r'^(\d{3}[A-Z]*)\.\s+(.*?)(?:—|--|-)\s*(.*)$')
ignore_patterns = [
    r'PART IX THE PANCHAYATS',
    r'As per your instructions',
    r'^Ins\. by the' # e.g. Ins. by the Constitution..
]

def format_text(para):
    # Ensure (1), (2), (a), (b) and "Provided that" get a newline before them if they are in the middle of text
    # But only if preceded by a space or sentence end, to avoid breaking e.g. "article 243(1)"
    para = re.sub(r'(?<=[\.\s])(\(\d+\)|\([a-z]\)|Provided that|Provided further that)', r'`n\1', para)
    return para

for line in lines:
    line = line.strip()
    if not line:
        continue
    
    skip = False
    for pat in ignore_patterns:
        if re.search(pat, line):
            skip = True
    if skip:
        continue
        
    m = art_pattern.match(line)
    if m:
        if current_art:
            articles.append(current_art)
        
        art_id = m.group(1)
        art_title_part = m.group(2).replace("[", "").replace("]", "")
        content = m.group(3)
        
        title_str = f"Article {art_id}: {art_title_part}"
        
        text_val = f"<strong>Article {art_id}. {art_title_part}—</strong>"
        if content:
            formatted_content = format_text(content)
            text_val += f"`n{formatted_content}"
            
        current_art = {
            "id": art_id,
            "title": title_str,
            "preview": content if content else "",
            "text": text_val
        }
    else:
        if current_art:
            amend_match = re.match(r'^(Amendments?|संशोधन):', line)
            if amend_match:
                line_processed = f"<strong>{amend_match.group(1)}:</strong>"
            else:
                line_processed = format_text(line)
            
            # Replace occurrences of 1[ with <sup>1</sup>[
            line_processed = re.sub(r'(\d+)\[', r'<sup>\1</sup>[', line_processed)
            line_processed = re.sub(r'(\d+)\*\*\*', r'<sup>\1</sup>***', line_processed)
            line_processed = re.sub(r'¹\[', r'<sup>1</sup>[', line_processed)

            current_art["text"] += f"`n{line_processed}"
            if not current_art["preview"]:
                current_art["preview"] = line

if current_art:
    articles.append(current_art)

# Truncate previews
for a in articles:
    # In case preview has `n inserted by mistake, remove it
    preview = a["preview"].replace("`n", "")
    if len(preview) > 150:
        preview = preview[:150] + "..."
    a["preview"] = preview

part9 = {
    "partId": "IX",
    "partTitle": "Part IX - The Panchayats",
    "partDesc": "Articles 243 to 243O detailing the constitution, composition, powers, and duration of Panchayats.",
    "articles": articles
}

with open("data/articles.json", "r", encoding="utf-8") as f:
    schema = json.load(f)

# Find Part VIII and insert right after it
insert_index = len(schema)
for i, part in enumerate(schema):
    if part.get("partId") == "VIII":
        insert_index = i + 1
        break

# check if Part IX already exists and remove it
schema = [p for p in schema if p.get("partId") != "IX"]

# Insert again (in case index shifted, find VIII again)
insert_index = len(schema)
for i, part in enumerate(schema):
    if part.get("partId") == "VIII":
        insert_index = i + 1
        break

schema.insert(insert_index, part9)

with open("data/articles.json", "w", encoding="utf-8") as f:
    # Setting ensure_ascii=False avoids escaping unicode to \u... but standard ascii is preserved 
    json.dump(schema, f, ensure_ascii=True, indent=4)

print("Insertion of Part IX done!")
