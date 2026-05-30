import shutil, os

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
TMP_JSON_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_tmp.json')
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')

shutil.copy2(TMP_JSON_PATH, JSON_PATH)
print("Database updates successfully applied to data/articles.json!")
