import json
import os
import sys
import re

# Set stdout to UTF-8
sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf8', closefd=False)

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_BACKUP_PATH = os.path.join(BASE_DIR, 'scratch', 'schedules_backup.json')
JSON_TMP_PATH = os.path.join(BASE_DIR, 'data', 'schedules.json')

STATES_EN = ["Andhra Pradesh", "Assam", "Bihar", "Gujarat", "Kerala", "Madhya Pradesh", 
             "Tamil Nadu", "Maharashtra", "Karnataka", "Odisha", "Punjab", "Rajasthan", 
             "Uttar Pradesh", "West Bengal", "Nagaland", "Haryana", "Himachal Pradesh", 
             "Manipur", "Tripura", "Meghalaya", "Sikkim", "Mizoram", "Arunachal Pradesh", 
             "Goa", "Chhattisgarh", "Uttarakhand", "Jharkhand", "Telangana"]

UTS_EN = ["Delhi", "The Andaman and Nicobar Islands", "Lakshadweep", 
          "Dadra and Nagar Haveli and Daman and Diu", "Puducherry", "Chandigarh", 
          "Jammu and Kashmir", "Ladakh"]

STATES_HI = ["आंध्र प्रदेश", "असम", "बिहार", "गुजरात", "केरल", "मध्य प्रदेश", 
             "तमिलनाडु", "महाराष्ट्र", "कर्नाटक", "ओडिशा", "पंजाब", "राजस्थान", 
             "उत्तर प्रदेश", "पश्चिमी बंगाल", "नागालैंड", "हरियाणा", "हिमाचल प्रदेश", 
             "मणिपुर", "त्रिपुरा", "मेघालय", "सिक्किम", "मिजोरम", "अरुणाचल प्रदेश", 
             "गोवा", "छत्तीसगढ़", "उत्तराखंड", "झारखंड", "तेलंगाना"]

UTS_HI = ["दिल्ली", "अंदमान और निकोबार द्वीप", "लक्षद्वीप", 
          "दादरा और नागर हवेली और दमण और दीव", "पुडुचेरी", "चंडीगढ़", 
          "जम्मू-कश्मीर", "लद्दाख"]

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
        print(f"ERROR: Schedule count mismatch! Backup: {len(backup_data)}, Tmp: {len(tmp_data)}")
        sys.exit(1)

    errors = 0

    for i in range(len(backup_data)):
        s_backup = backup_data[i]
        s_tmp = tmp_data[i]
        sch_id = s_backup.get('id')
        
        if sch_id != "1":
            if json.dumps(s_backup, ensure_ascii=False) != json.dumps(s_tmp, ensure_ascii=False):
                print(f"ERROR: Schedule {sch_id} was modified but it is not First Schedule!")
                errors += 1
            continue

        print(f"\nVerifying First Schedule...")
        
        # Check details (English)
        details = s_tmp.get('details')
        if not details or not isinstance(details, str):
            print("  ERROR: 'details' field is empty or not string!")
            errors += 1
        else:
            if '`n' in details:
                print("  ERROR: English details contain literal `n!")
                errors += 1
            if '\n' not in details:
                print("  ERROR: English details have no newlines!")
                errors += 1
                
            first_line = details.split('\n')[0]
            if not first_line.startswith('<sup>1</sup>[<strong>FIRST SCHEDULE</strong>'):
                print(f"  ERROR: English heading format is incorrect: {repr(first_line)}")
                errors += 1
                
            # Verify bolding of States and UTs in English
            paragraphs = details.split('\n')
            states_and_uts_found = 0
            
            # States are at indices 2 to 30, UTs are at indices 32 to 42
            target_indices = list(range(2, 31)) + list(range(32, 43))
            for idx in target_indices:
                p = paragraphs[idx]
                # Skip if it is a deleted entry
                if '*' in p:
                    continue
                    
                found = False
                for name in STATES_EN + UTS_EN:
                    pos = p.find(name)
                    if pos != -1:
                        prefix = p[:pos]
                        if re.match(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰\d\.\s\[\]\*\-\—<>supstrong/]*$', prefix):
                            # Ensure it is bolded
                            bold_regex = rf'<strong>{re.escape(name)}</strong>'
                            if not re.search(bold_regex, p):
                                print(f"  ERROR: Name '{name}' is not bolded in paragraph: {repr(p[:100])}")
                                errors += 1
                            states_and_uts_found += 1
                            found = True
                            break
                if not found:
                    print(f"  ERROR: No bolded State/UT name found at the start of paragraph {idx}: {repr(p[:100])}")
                    errors += 1
                    
            print(f"  Verified {states_and_uts_found} bolded English State/UT entries.")
                
            if '<details>' not in details or '</details>' not in details:
                print("  ERROR: English details are missing collapsible <details> tag!")
                errors += 1
            if 'Amendments (Click to expand)' not in details:
                print("  ERROR: English details are missing 'Amendments (Click to expand)' summary!")
                errors += 1
            
            idx_amend = details.find('<details>')
            if idx_amend != -1:
                amend_part = details[idx_amend:]
                footnotes = re.findall(r'<sup><strong>\d+</strong></sup>', amend_part)
                print(f"  Found {len(footnotes)} English footnotes.")
                if len(footnotes) != 58:
                    print(f"  ERROR: Expected 58 English footnotes, found {len(footnotes)}!")
                    errors += 1
            else:
                print("  ERROR: Could not locate <details> tag in English details!")
                errors += 1
                    
        # Check hindi
        hindi = s_tmp.get('hindi')
        if not hindi or not isinstance(hindi, str):
            print("  ERROR: 'hindi' field is empty or not string!")
            errors += 1
        else:
            if '`n' in hindi:
                print("  ERROR: Hindi field contains literal `n!")
                errors += 1
            if '\n' not in hindi:
                print("  ERROR: Hindi field has no newlines!")
                errors += 1
                
            first_line_hi = hindi.split('\n')[0]
            if not first_line_hi.startswith('<sup>1</sup>[<strong>पहली अनुसूची</strong>'):
                print(f"  ERROR: Hindi heading format is incorrect: {repr(first_line_hi)}")
                errors += 1
                
            # Verify bolding of States and UTs in Hindi
            paragraphs_hi = hindi.split('\n')
            states_and_uts_found_hi = 0
            
            # Hindi states are at indices 2 to 30, UTs are at indices 32 to 42
            for idx in target_indices:
                p = paragraphs_hi[idx]
                if '*' in p:
                    continue
                    
                found = False
                for name in STATES_HI + UTS_HI:
                    pos = p.find(name)
                    if pos != -1:
                        prefix = p[:pos]
                        if re.match(r'^[¹²³⁴⁵⁶⁷⁸⁹⁰\d\.\s\[\]\*\-\—<>supstrong/]*$', prefix):
                            bold_regex = rf'<strong>{re.escape(name)}</strong>'
                            if not re.search(bold_regex, p):
                                print(f"  ERROR: Hindi name '{name}' is not bolded in paragraph: {repr(p[:100])}")
                                errors += 1
                            states_and_uts_found_hi += 1
                            found = True
                            break
                if not found:
                    print(f"  ERROR: No bolded Hindi State/UT name found at the start of paragraph {idx}: {repr(p[:100])}")
                    errors += 1
                    
            print(f"  Verified {states_and_uts_found_hi} bolded Hindi State/UT entries.")
                
            if '<details>' not in hindi or '</details>' not in hindi:
                print("  ERROR: Hindi field is missing collapsible <details> tag!")
                errors += 1
            if 'संशोधन (विस्तार के लिए क्लिक करें)' not in hindi:
                print("  ERROR: Hindi field is missing 'संशोधन (विस्तार के लिए क्लिक करें)' summary!")
                errors += 1
                
            idx_amend_hi = hindi.find('<details>')
            if idx_amend_hi != -1:
                amend_part_hi = hindi[idx_amend_hi:]
                footnotes_hi = re.findall(r'<sup>\d+</sup>', amend_part_hi)
                print(f"  Found {len(footnotes_hi)} Hindi footnotes.")
                if len(footnotes_hi) != 58:
                    print(f"  ERROR: Expected 58 Hindi footnotes, found {len(footnotes_hi)}!")
                    errors += 1
            else:
                print("  ERROR: Could not locate <details> tag in Hindi original!")
                errors += 1

    if errors == 0:
        print("\nSUCCESS: All verifications passed successfully! No errors found.")
        sys.exit(0)
    else:
        print(f"\nFAILURE: Verification failed with {errors} errors.")
        sys.exit(1)

if __name__ == '__main__':
    verify()
