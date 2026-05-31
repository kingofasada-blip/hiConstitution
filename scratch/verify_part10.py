import json
import os
import sys
import re

# Set standard output to UTF-8
sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf8', closefd=False)

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_BACKUP_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_backup_before_part10.json')
JSON_TMP_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')

def verify():
    if not os.path.exists(JSON_BACKUP_PATH):
        print("ERROR: Backup file not found!")
        sys.exit(1)
        
    if not os.path.exists(JSON_TMP_PATH):
        print("ERROR: Temporary updated file not found!")
        sys.exit(1)

    with open(JSON_BACKUP_PATH, 'r', encoding='utf-8') as f:
        backup_data = json.load(f)
        
    with open(JSON_TMP_PATH, 'r', encoding='utf-8') as f:
        tmp_data = json.load(f)

    if len(backup_data) != len(tmp_data):
        print(f"ERROR: Part count mismatch! Backup: {len(backup_data)}, Tmp: {len(tmp_data)}")
        sys.exit(1)

    errors = 0

    for i in range(len(backup_data)):
        p_backup = backup_data[i]
        p_tmp = tmp_data[i]
        part_id = p_backup.get('partId')
        
        if part_id != "X":
            # For non-target parts, everything must be 100% identical!
            if json.dumps(p_backup, ensure_ascii=False) != json.dumps(p_tmp, ensure_ascii=False):
                print(f"ERROR: Part {part_id} was modified but it is not Part X!")
                errors += 1
            continue

        print(f"\nVerifying Part X...")
        
        tmp_arts = p_tmp.get('articles', [])
        if len(tmp_arts) != 2:
            print(f"  ERROR: Article count mismatch in Part X! Expected 2, found {len(tmp_arts)}")
            errors += 1
            continue
            
        for art in tmp_arts:
            art_id = art['id']
            print(f"  Checking Article {art_id}...")
            
            # Check all keys exist and are string and non-empty
            expected_keys = ['id', 'title', 'preview', 'text', 'simplified', 'hindi', 'hindiSimplified']
            for k in expected_keys:
                if k not in art:
                    print(f"    ERROR: Key '{k}' is missing in Article {art_id}!")
                    errors += 1
                elif not isinstance(art[k], str) or not art[k].strip():
                    print(f"    ERROR: Key '{k}' is empty or not string in Article {art_id}!")
                    errors += 1
            
            if errors > 0:
                continue

            # 1. Check title field format
            title = art['title']
            if not title.startswith(f"Article {art_id}:"):
                print(f"    ERROR: Title field '{title}' does not start with 'Article {art_id}:'!")
                errors += 1
            if re.search(r'[\.\[\]\-\—]$', title):
                print(f"    ERROR: Title field '{title}' ends with trailing punctuation or bracket!")
                errors += 1
                
            # 2. Check preview field format
            preview = art['preview']
            if not preview.endswith('...'):
                print(f"    ERROR: Preview '{preview}' does not end with '...'!")
                errors += 1
            if '<' in preview or '>' in preview:
                print(f"    ERROR: Preview '{preview}' contains HTML tags!")
                errors += 1
            if len(preview) > 160:
                print(f"    ERROR: Preview '{preview}' is too long ({len(preview)} chars)!")
                errors += 1

            # 3. Check English text field
            text = art['text']
            # English should use standard newlines \n, not literal `n
            if '`n' in text:
                print(f"    ERROR: English text contains literal `n!")
                errors += 1
            if '\n' not in text:
                print(f"    ERROR: English text has no standard newlines!")
                errors += 1
                
            # Check English heading
            first_line_en = text.split('\n')[0]
            if not first_line_en.startswith('<strong>'):
                print(f"    ERROR: English text does not start with <strong>!")
                errors += 1
            if not first_line_en.endswith('.-</strong>'):
                print(f"    ERROR: English heading does not end with .-</strong>: {repr(first_line_en)}")
                errors += 1
            if art_id == '244' and '<sup>' in first_line_en:
                print(f"    ERROR: Article 244 English heading should not have superscript!")
                errors += 1
            if art_id == '244A' and '<sup>1</sup>[' not in first_line_en:
                print(f"    ERROR: Article 244A English heading should have <sup>1</sup>[ at start!")
                errors += 1

            # Check English amendments
            if '<strong>Amendments:</strong>' not in text:
                print(f"    ERROR: English text is missing Amendments section!")
                errors += 1
            else:
                idx_amend = text.index('<strong>Amendments:</strong>')
                amend_part = text[idx_amend:]
                # Check for superscript bold footnotes like <sup><strong>1</strong></sup>
                footnote_matches = re.findall(r'<sup><strong>\d+</strong></sup>', amend_part)
                if not footnote_matches:
                    print(f"    ERROR: English amendments are missing bold superscript footnote numbers!")
                    errors += 1

            # 4. Check Hindi original field
            hindi = art['hindi']
            # Hindi should use literal `n, not standard newlines \n
            if '\n' in hindi:
                print(f"    ERROR: Hindi original contains standard newlines \\n!")
                errors += 1
            if '`n' not in hindi:
                print(f"    ERROR: Hindi original has no literal `n separators!")
                errors += 1
                
            # Check Hindi heading
            first_line_hi = hindi.split('`n')[0]
            if not first_line_hi.startswith('<strong>'):
                print(f"    ERROR: Hindi original does not start with <strong>!")
                errors += 1
            if not first_line_hi.endswith('—</strong>'):
                print(f"    ERROR: Hindi heading does not end with —</strong>: {repr(first_line_hi)}")
                errors += 1
            if art_id == '244' and '<sup>' in first_line_hi:
                print(f"    ERROR: Article 244 Hindi heading should not have superscript!")
                errors += 1
            if art_id == '244A' and '<sup>1</sup>[' not in first_line_hi:
                print(f"    ERROR: Article 244A Hindi heading should have <sup>1</sup>[ at start!")
                errors += 1

            # Check Hindi amendments
            if '<strong>संशोधन:</strong>' not in hindi:
                print(f"    ERROR: Hindi original is missing संशोधन: section!")
                errors += 1
            else:
                idx_amend_hi = hindi.index('<strong>संशोधन:</strong>')
                amend_part_hi = hindi[idx_amend_hi:]
                # Check for standard superscript footnotes like <sup>1</sup>
                footnote_matches_hi = re.findall(r'<sup>\d+</sup>', amend_part_hi)
                if not footnote_matches_hi:
                    print(f"    ERROR: Hindi amendments are missing superscript footnote numbers!")
                    errors += 1

            # 5. Check English simplified field
            simplified = art['simplified']
            if simplified.lower().startswith('simplified'):
                print(f"    ERROR: English simplified contains 'Simplified:' prefix in Article {art_id}!")
                errors += 1

            # 6. Check Hindi simplified field
            h_simp = art['hindiSimplified']
            if not h_simp.startswith('<strong>सारांश टिप्पणी:</strong>'):
                print(f"    ERROR: Hindi Simplified does not start with prefix for Article {art_id}: {repr(h_simp[:40])}")
                errors += 1
            if h_simp.startswith('<strong>सारांश टिप्पणी:</strong> सारांश टिप्पणी'):
                print(f"    ERROR: Double prefix detected in Article {art_id}!")
                errors += 1

    if errors == 0:
        print("\nSUCCESS: All verifications passed successfully! No errors found.")
        sys.exit(0)
    else:
        print(f"\nFAILURE: Verification failed with {errors} errors.")
        sys.exit(1)

if __name__ == '__main__':
    verify()
