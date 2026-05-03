import json
import re

with open(r"c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Fix the 'value' wrapper if it exists
if isinstance(data, dict) and "value" in data:
    data = data["value"]

target_articles = {'308', '309', '310', '311', '312', '312A', '315', '316', '317', '318', '320', '323'}

for part in data:
    if part.get("partId") == "XIV":
        for article in part.get("articles", []):
            if article.get("id") in target_articles:
                text = article.get("text", "")
                # Replace digits followed by [ or * that are not preceded by a digit
                text = re.sub(r'(?<!\d)(\d+)(?=\[|\*)', r'<sup>\1</sup>', text)
                article["text"] = text

with open(r"c:\Users\DeLL\Desktop\hiCONSTITUTION\data\articles.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=4)

print("JSON fixed and superscripts applied.")
