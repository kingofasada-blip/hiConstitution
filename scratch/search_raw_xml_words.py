import zipfile, sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with zipfile.ZipFile(r'c:\Users\DeLL\Desktop\hiCONSTITUTION\part 5 - hindi original.docx', 'r') as z:
    xml_content = z.read('word/document.xml').decode('utf-8')

# Search for some terms
terms = ['अमुक', 'ईश्वर', 'शपथ', 'प्रतिज्ञान', 'श्रद्धापूर्वक', 'सत्यनिष्ठा']
for term in terms:
    print(f"Term '{term}': count = {xml_content.count(term)}")

# Let's print snippet around first occurrence of 'ईश्वर' or 'शपथ'
idx = xml_content.find('60. राष्ट्रपति')
if idx != -1:
    print("\nSnippet around Article 60:")
    print(xml_content[idx:idx+1500])
