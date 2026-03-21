#%%
#
# bible_fhlwh.sqlite
# select engs from main where id=1
# select txt from fhlwh where engs=剛剛的結果 and chap=2 and sec=3

# e.g. 取得 book, chap, sec 為 40, 1, 1 的 txt 
# SQL 指令為

# SELECT f.txt
# FROM fhlwh f
# JOIN main m ON f.engs = m.engs
# WHERE m.id = 40
#   AND f.chap = 1
#   AND f.sec = 1;

#%%
# 要 read .sqlite 檔案，純 read 沒有要 update 的話，在 python 要怎麼作是最簡單快速的
import sqlite3

if __name__ == "__main__":
    db_path = r"./bible_fhlwh.sqlite"
    conn = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)

    cur = conn.cursor()
    cur.execute("select engs from main where id=40")
    print(cur.fetchall())

    conn.close()
# %%
# 單筆可以用 LIMIT 1 與 fetchone()
if __name__ == "__main__":
    db_path = r"./bible_fhlwh.sqlite"
    conn = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)

    cur = conn.cursor()
    cur.execute("select engs from main where id=40 limit 1")
    print(cur.fetchone())

    conn.close()

# %%
# 綜合
def gen_command(book: int, chap: int, sec: int) -> str:
    return f"""
SELECT f.txt
FROM fhlwh f
JOIN main m ON f.engs = m.engs
WHERE m.id = {book}
  AND f.chap = {chap}
  AND f.sec = {sec}
LIMIT 1;"""

if __name__ == "__main__":
    db_path = r"./bible_fhlwh.sqlite"
    conn = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)

    cur = conn.cursor()
    cur.execute(gen_command(40, 1, 1))
    print(cur.fetchone())

    # 讓 其 result 是 str 而不是 tuple
    cur.execute(gen_command(40, 1, 1))
    result = cur.fetchone()
    if result:
        print(result[0])

    conn.close()
# %%
def read_txt_from_fhlwh_sqlite_file(book: int, chap: int, sec: int, path_bible_db: str = './bible_fhlwh.sqlite') -> str:
    # 39 < book < 67
    if not (39 < book < 67):
        raise ValueError(f"Invalid book number: {book}. Must be between 40 and 66.")
    
    import os
    if not os.path.exists(path_bible_db):
        raise FileNotFoundError(f"Database file not found: {path_bible_db}")
    
    conn = sqlite3.connect(f"file:{path_bible_db}?mode=ro&immutable=1", uri=True)
    cur = conn.cursor()
    cur.execute(gen_command(book, chap, sec))
    result = cur.fetchone()
    conn.close()
    if result:
        return result[0]
    else:
        return ""
    
if __name__ == "__main__":
    print(read_txt_from_fhlwh_sqlite_file(40, 1, 1))
