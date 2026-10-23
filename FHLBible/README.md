# FHLBible

信望愛聖經 iOS App（完整版）。整個 repo 的總說明在根目錄的 [`README.md`](../README.md)；這份放在原始碼資料夾內，補充「最近的更新」「怎麼使用」與「SQLite 離線資料的設計」。

# News

最新版本 4.14.x（完整紀錄見 App 內「版本資訊」，原始檔 [`Helps/app_versions.md`](Helps/app_versions.md)）：

- **4.14.2**：設定新增「注腳載入方式」，預設「直接載入」。讀 NET聖經中譯本、中文標準譯本、呂振中譯本時，注腳內容直接顯示在經文裡（紫色【註1：…】，內容中的參照仍可點）；選「點擊載入」則維持藍色【1】，點了才開注腳畫面。
- **4.14.1**：修正閱讀多段經文（從串珠、搜尋進入）時，經文只佔一半寬度。
- **4.13.1**：大部分畫面改用 SwiftUI 重寫（首頁、閱讀、書卷選擇、譯本選擇、譯本比較、搜尋、字典、Parsing、註釋、串珠、有聲聖經…）；可複選經文再複製；搜尋輸入改用系統搜尋列；取不到資料時會說明原因並可重試；最低支援 iOS 改為 17.0。

# 使用者閱讀

- **讀經**：首頁選書卷章進入閱讀。底部可換譯本、上下章；譯本可多選，同時上下排列對照。
- **看原文與字典**：點有 Strong 號碼的字，可開字典（CBOL／浸宣）與原文逐字分析（Parsing）。
- **注腳與參照**：點【n】或參照經文，會開注腳或跳到該處。
- **長按經文**：「更多 → 選取經文」可複選，複製文字或產生圖片分享。
- **搜尋**：閱讀畫面的搜尋按鈕，輸入關鍵字；結果可依分類或書卷篩選，搜尋記錄可左滑刪除。
- **離線使用**：到「資料」下載譯本、字典、Parsing。有下載的譯本不需網路；沒下載的譯本會即時向信望愛伺服器查詢。
- **簡體／繁體**：依 App 內語系設定，簡體會用另一份 `_gb` 資料檔。

# 給開發者閱讀

## SQLite 設計

### 譯本 正規化

信望愛提供的離線譯本檔（`https://ftp.fhl.net/FHL/COBS/data/`）每個譯本的表格格式不一致，書卷用英文縮寫（`engs`，例 `Gen`、`1 Pet`）。下載解壓後，App 會「正規化」成統一格式，讀取程式才能用同一套邏輯處理所有譯本。

流程（`Download/` 與 `SQLiteFHL/`）：

```
download/bible_<xxx>.zip  →  unzip/bible_<xxx>.db  →  offline/<ver>.db 的 <ver>2 表
```

正規化後的表（`SQLBibleTextTransfor` 產生）：

```sql
CREATE TABLE "<ver>2" (id INTEGER, book INTEGER, chap INTEGER, sec INTEGER, txt TEXT);
```

- `book` 是 1–66。轉換方式是 `attach` 來源檔與 `offline/main.db`，用 `engs` 對 `main` 表 join 取得 `book`。所以 **`main.db` 要先存在**，它是其他譯本正規化的前置條件（下載管理會讓譯本排隊，等 `main.db` 好了才開始）。
- `id` 沿用來源順序，查詢時 `order by id` 就是經文順序。
- 簡體 `<ver>_gb` 用另一個來源檔（`bible_gb_*.db`）產生。

檔名與表名由 `SQLNameOfFileAndTableRuler` 決定：

| 情況 | 檔案 | 表 |
|------|------|----|
| 一般譯本 | `offline/<ver>.db` | `<ver>2` |
| 簡體且與繁體內容不同 | `offline/<ver>_gb.db` | `<ver>_gb2` |
| `unv`、`kjv`（有 Strong 號碼） | `offline/sn_<ver>.db` | `sn_<ver>2` |

（`kjv`、`asv` 沒有簡體差異，所以不加 `_gb`。）

來源檔位置：`unv` 的來源是 `bible_little.zip` 內的 `nstrunv` 表，`kjv` 是 `bible_kjv.zip`，其餘譯本是 `bible_<ver>.zip`；Parsing 另有 `bible_parsing.zip`（細節見 [`doc/260927a_離線parsing資料庫_bible_parsing.md`](doc/260927a_離線parsing資料庫_bible_parsing.md)）。所有檔案都在 App 的 Documents 目錄下。

### 串接 閱讀功能

讀經時由 `Read/DataGetter/BibleGetterViaSQLiteOrApi` 決定資料來源：

1. 檢查 `offline/<ver>.db`（依上表命名）是否存在。
2. 存在 → `BibleGetterViaSQLiteFile`：
   - `SQLSelectBibleTextGenerator` 把要查的經文位址（`[DAddress]`）轉成 SQL：依書、章分組，連續節合併成 `sec>=a and sec<=b`，最後 `order by id`。例：`select * from unv2 where (book=40 and ((chap=1 and ((sec>=1 and sec<=5) or sec=9))));`
   - 每列轉成 `DOneLine`（`DAddress` + 一個 `DText` 純文字）。
   - 原文譯本要另外轉碼：`bhs`（舊約希伯來文）用 `umscode`，`fhlwh`、`lxx`（新約／七十士譯本希臘文）用 `gcode2`，因為這些檔的 zip 內只有 ASCII 碼。
   - 最後交給 `BibleText2DText` 解析成含 Strong 號碼、注腳的 `[DText]`。
3. 不存在 → `BibleGetterViaFhlApiQsb`：呼叫信望愛 qsb API，取回後同樣交給 `BibleText2DText`。

兩條路徑最後都產生相同的 `[DOneLine]`，畫面層不需要知道資料從哪來。多譯本時一個譯本一條執行緒（`DispatchGroup` 等全部回來），資料流全貌見根目錄 [`CLAUDE.md`](../CLAUDE.md) 的 Data Flow。

SQLite 讀取一律經 `EasySQLite/EasySQLiteBase`（FMDB 包裝）。查詢失敗時會回傳一列「SQLite 查詢失敗」的文字，不會讓畫面空白。
