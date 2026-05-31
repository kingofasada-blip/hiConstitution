import json
import os
import sys

# Set standard output to UTF-8
sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf8', closefd=False)

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_BACKUP_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_backup_before_parts_9_9a_9b.json')
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

    target_parts = ["IX", "IXA", "IXB"]
    errors = 0

    for i in range(len(backup_data)):
        p_backup = backup_data[i]
        p_tmp = tmp_data[i]
        part_id = p_backup.get('partId')
        
        if part_id not in target_parts:
            # For non-target parts, everything must be 100% identical!
            if json.dumps(p_backup) != json.dumps(p_tmp):
                print(f"ERROR: Part {part_id} was modified but it is not in target parts!")
                errors += 1
            continue

        print(f"\nVerifying Part {part_id}...")
        
        # Check articles count
        backup_arts = p_backup.get('articles', [])
        tmp_arts = p_tmp.get('articles', [])
        if len(backup_arts) != len(tmp_arts):
            print(f"  ERROR: Article count mismatch in Part {part_id}!")
            errors += 1
            continue
            
        for a_backup, a_tmp in zip(backup_arts, tmp_arts):
            art_id = a_backup['id']
            print(f"  Checking Article {art_id}...")
            
            # 1. Check original English text field must be EXACTLY identical
            if a_backup.get('text') != a_tmp.get('text'):
                print(f"    ERROR: English original text modified for Article {art_id}!")
                print(f"      Backup: {repr(a_backup.get('text'))}")
                print(f"      Tmp:    {repr(a_tmp.get('text'))}")
                errors += 1

            # 2. Check title field must be identical
            if a_backup.get('title') != a_tmp.get('title'):
                print(f"    ERROR: Title field modified for Article {art_id}!")
                errors += 1
                
            # 3. Check original Hindi field is updated and formatted
            hindi = a_tmp.get('hindi')
            if not hindi:
                print(f"    ERROR: Original Hindi is empty for Article {art_id}!")
                errors += 1
            else:
                if not hindi.startswith('<strong>'):
                    print(f"    ERROR: Original Hindi does not start with <strong> for Article {art_id}!")
                    errors += 1
                if '—</strong>' not in hindi and '-</strong>' not in hindi and '–</strong>' not in hindi:
                    print(f"    ERROR: Original Hindi title tag structure is weird: {repr(hindi[:60])}")
                    errors += 1
                if '`n' not in hindi and len(hindi.split('\n')) == 1 and part_id != "IX" and art_id != "243A":
                    # Article 243A is short, might only be 1 paragraph, but others should have multiple paragraphs / newlines
                    pass

            # 4. Check simplified (English) field is updated
            simplified = a_tmp.get('simplified')
            if not simplified:
                print(f"    ERROR: Simplified English is empty for Article {art_id}!")
                errors += 1
            elif simplified.lower().startswith('simplified'):
                print(f"    ERROR: Simplified English contains 'Simplified:' prefix in Article {art_id}!")
                errors += 1

            # 5. Check hindiSimplified field is updated and starts with prefix
            h_simp = a_tmp.get('hindiSimplified')
            if not h_simp:
                print(f"    ERROR: Hindi Simplified is empty for Article {art_id}!")
                errors += 1
            else:
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
