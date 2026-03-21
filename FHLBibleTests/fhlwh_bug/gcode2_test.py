#%%
#
# 讓 Python 找得到上一層（專案根目錄）的模組
if __name__ == "__main__":
    from pathlib import Path
    import sys
    PROJECT_ROOT = Path(__file__).resolve().parents[1]
    if str(PROJECT_ROOT) not in sys.path:
        sys.path.insert(0, str(PROJECT_ROOT))
    
from fhlwh_read_from_api import read_txt_from_fhlwh_api
from fhlwh_read_from_file import read_txt_from_fhlwh_sqlite_file
from gcode2 import gcode_2
if __name__ == "__main__":
    txt1 = read_txt_from_fhlwh_api(40, 1, 1)
    txt2 = read_txt_from_fhlwh_sqlite_file(40, 1, 1)
    txt2b = gcode_2(txt2)
    if txt1 != txt2b:
        print("txt1 != txt2b")
        print(txt1)
        print(txt2b)
    else:
        print(txt2b)
#%%
# 試試 /gcode2/swift_test

import requests
if __name__ == "__main__":
    url = "http://127.0.0.1:5600/gcode2/swift_test.php?book=40&chap=10&sec=16"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        print(data)
    else:
        print(f"Request failed with status code: {response.status_code}")
    

# %%
# 連續測試

def first_diff(a: str, b: str):
    # 另外，先用「第一個差異碼位」確認是不是這類問題（建議加在 test）
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            return i, a[i], b[i]
    if len(a) != len(b):
        return n, a[n:n+1], b[n:n+1]
    return -1, "", ""

from bible_constants_functions import getNextAddress
import re

# 40 16 25
# 40 18 21,25,31,
# 40 19 3,4,7, 9, 10
# 40 25 5,10,35,36,37,38,40
# 40 27 22
# txt1 != txt2b at 45:3:2
# txt1 != txt2b at 45:4:22
# txt1 != txt2b at 45:5:15
# txt1 != txt2b at 45:5:19
# txt1 != txt2b at 45:11:25
# txt1 != txt2b at 45:14:5

if __name__ == "__main__":
    book = 40
    chap = 1
    sec = 1
    count_max = 200
    count = 0
    while True and count < count_max:
        txt1 = read_txt_from_fhlwh_api(book, chap, sec)
        # txt1 relace all \r?\n\r? with \n
        txt1 = re.sub(r'\r?\n\r?', '\n', txt1)
        
        txt2 = read_txt_from_fhlwh_sqlite_file(book, chap, sec)
        txt2b = gcode_2(txt2)
        
        # txt2b relace all \r?\n\r? with \n
        txt2b = re.sub(r'\r?\n\r?', '\n', txt2b)
        # just collect error
        isJustCollectError = False
        
        # 把\n,空白拿掉來比
        if txt1.replace('\n', '').replace(' ', '') != txt2b.replace('\n', '').replace(' ', ''):
        # if txt1 != txt2b:
        
            if isJustCollectError:
                print(f"txt1 != txt2b at {book}:{chap}:{sec}")
            else:
                print(f"input:\n")
                
                print(txt2)
                
                print("\nexcpected:\n")
                
                print(txt1)
                
                print("\nresult:\n")
                
                print(txt2b)

                idx, ca, cb = first_diff(txt1, txt2b)
                print("\nfirst diff index:", idx)
                if idx >= 0:
                    print("expected:", repr(ca), f"U+{ord(ca):04X}" if ca else "EOF")
                    print("result  :", repr(cb), f"U+{ord(cb):04X}" if cb else "EOF")
                # break            
                break
        else:
            if not isJustCollectError:
                print(f"{book}:{chap}:{sec} ok")
        count += 1
        
        next_address = getNextAddress({"book": book, "chap": chap, "verse": sec})
        if next_address is None:
            print("no more address")
            break
        
        book = next_address['book']
        chap = next_address['chap']
        sec = next_address['verse']
    print(f"done. count={count}, at {book}:{chap}:{sec}")
# %%
