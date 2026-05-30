import shutil, os

BASE_DIR = r'c:\Users\DeLL\Desktop\hiCONSTITUTION'
JSON_PATH = os.path.join(BASE_DIR, 'data', 'articles.json')
BACKUP_PATH = os.path.join(BASE_DIR, 'scratch', 'articles_backup_before_parts_3_4_5.json')

shutil.copy2(JSON_PATH, BACKUP_PATH)
print(f"Backup created at: {BACKUP_PATH}")
