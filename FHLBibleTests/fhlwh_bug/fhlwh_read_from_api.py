#%%
# api 的使用
# http://bible.fhl.net/json/qsb.php?version=fhlwh&qstr=太1:1&strong=0&gb=0
import requests

if __name__ == "__main__":
    url = "http://bible.fhl.net/json/qsb.php?version=fhlwh&qstr=太1:1&strong=0&gb=0"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        print(data)
        print(data['record'][0]['bible_text'])
    else:
        print(f"Request failed with status code: {response.status_code}")
#%%
# book id 轉 name
# 使用 ../bible_constants.py ... 要先前處理，才能 import 上一層的檔案
import requests

# 讓 Python 找得到上一層（專案根目錄）的模組
if __name__ == "__main__":
    from pathlib import Path
    import sys
    PROJECT_ROOT = Path(__file__).resolve().parents[1]
    if str(PROJECT_ROOT) not in sys.path:
        sys.path.insert(0, str(PROJECT_ROOT))
        
from bible_constants import CHINESE_BOOK_ABBREVIATIONS

# %%
# 寫成函式
def read_txt_from_fhlwh_api(book: int, chap: int, sec: int) -> str:
    # 39 < book < 67
    if book < 40 or book > 66:
        raise ValueError('book id must be between 40 and 66, you are ' + str(book))
    
    book_name = CHINESE_BOOK_ABBREVIATIONS[book - 1]
    
    domain = "http://127.0.0.1:5600"
    url = f"{domain}/json/qsb.php?version=fhlwh&qstr={book_name}{chap}:{sec}&strong=0&gb=0"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        if 'record' in data and len(data['record']) > 0:
            return data['record'][0]['bible_text']
    return ""

if __name__ == "__main__":
    print(read_txt_from_fhlwh_api(40, 1, 1))