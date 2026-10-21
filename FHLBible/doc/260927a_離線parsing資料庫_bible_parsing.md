# 離線 Parsing 資料庫 bible_parsing.db：來源、結構、轉碼

> 2026-09-27 整理。研究目的：FHLNUI (網頁版) 要用同一份檔案重新產生 `bible_fhlwh.json.gz`（新約原文嵌 SN），不再打大量 qp.php。
> 本文件描述 iOS 目前怎麼取用、資料庫長什麼樣、哪些欄位要轉碼、以及實測發現的坑。

## 一、來源

- 公開目錄：<https://ftp.fhl.net/FHL/COBS/data/>
- 繁體 `bible_parsing.zip`、簡體 `bible_gb_parsing.zip`，約 40 MB，解開是一個 SQLite (`bible_parsing.db`，約 136 MB)
- 同目錄還有各譯本 `bible_<ver>.zip`（例如 `bible_fhlwh.zip`、`bible_bhs.zip`），iOS 離線讀經就是用這些
- 資料版本：`SELECT dt FROM version`（例 `2026-09-24 05:50:02`）。比對這個值即可判斷是否要重新產生，不必靠 abv.php

## 二、iOS 的取用流程

| 步驟 | 檔案 | 說明 |
|---|---|---|
| 下載、解壓 | `Download/DoOneDownload_bible_parsing.swift` (`DoOneDownload_parsing`) | 下載到 `/download/bible_parsing.zip` → 解壓到 `/unzip/bible_parsing.db` |
| 正規化 | 同檔 `SQLNormalize_parsing` | 建 `/offline/parsing.db` 的 `fhlwhparsing2`、`lparsing2`：`engs` 經 `main.db` 的 `main` 表 join 成 `book` (1–66)；**`word` 取 `uword`、`orig` 取 `uorig`**（UTF-8），其餘欄位原樣搬 |
| 查詢 | `FHLTools/SNParsing/VCParsingIReloadDataViaOfflineDatabase.swift` (`DBParsing.queryParsingAsync`) | `SELECT * FROM fhlwhparsing2/lparsing2 WHERE book,chap,sec ORDER BY wid` |
| 後處理 | 同上 | wid0 的 `word` trim 空白（創1:2 前面多空白、創1:6 為 nil）；新約 `pro`/`wform` 經 `SNParsingDealProXForm` 展開成中文；舊約 `wform`/`exp`/`remark` 經 `toHebWhen1221InParsing` 把 `12…21` 夾住的希伯來 ASCII 轉 Unicode；wid0 的 `word` 或 `exp` 為 nil 時放保護字串（彼前3:20） |
| 顯示 | `ConvertorQp2VCParsingData` 等 | 與線上 qp.php 共用同一套 `DApiQpRecord` → 畫面，線上版是 `VCParsingIReloadDataViaQpApi.swift` |

讀經文（非 parsing）的離線路徑在 `Read/DataGetter/BibleGetterViaSQLiteFile.swift`：`bhs` 走 `umscode`，`fhlwh`/`lxx` 走 `gcode2`，因為那些譯本的 zip 只有 ASCII 碼。

## 三、資料庫結構

```sql
CREATE TABLE fhlwhparsing (      -- 新約，152,227 筆，7,959 節
  id integer, engs character(8), chap smallint, sec smallint, wid smallint,
  word text, sn character(5), pro varchar(40), wform text, orig varchar(100),
  exp text, remark text, username character(12), modtime character(30),
  osn character(5),              -- 只有新約有
  uword text, uorig text);
CREATE TABLE lparsing ( ... 同上，沒有 osn ... );   -- 舊約，331,802 筆，23,145 節
CREATE TABLE version (dt timestamp);
```

- `engs` 是 `'1 Pet'`、`'Gen'` 這種（中間有空白），需自行對到 book id
- `wid = 0`：整節。`word`/`uword` 是整節原文（含 `\n` 分行，新約還有 `+ 韋 + 聯 +` 異文標記），`exp` 是整節中文直譯（`\n` 位置與 word 對應）
- `wid ≥ 1`：逐字。`sn` 為五碼（`02526`，少數帶字母 `0031a`）

### 各欄位是否要轉碼

| 欄位 | 新約 fhlwhparsing | 舊約 lparsing |
|---|---|---|
| `word` / `orig` | ASCII 碼（gcode） | ASCII 碼（mscode） |
| `uword` / `uorig` | UTF-8，可直接用（見四之 1） | 逐字可直接用；**wid0 多行時不可信**（見四之 2） |
| `pro` / `wform` | 代碼：`c`、`v`、`n`… / `pai2p`、`gsm`… → `SNParsingDealProXForm` 展開 | 已是中文，但可能含 `12…21` 包住的希伯來 ASCII |
| `exp` | 中文 | 中文，可能含 `12…21` |
| `remark` | 中文，可能含 `<!…!>` 包住的希臘 ASCII（529 筆） | 中文，可能含 `12…21` |
| `sn` / `osn` | `sn` 是現行編號；`osn` 是舊式編號（10,616 筆不同，例：ἡμῶν `sn`=01473、`osn`=02257）。qp.php 回傳的是 `sn` | 只有 `sn` |

## 四、實測發現（用 FHLNUI 的 `gcode2.es2023.js`、`hebCode.es2023.js` 驗證）

1. **新約 `uword` = `gcode_2(word)`**：152,227 筆只差 2 筆（徒2:24、帖前5:24 的 wid0，上游資料本身不一致），可直接用 `uword`。oxia（ά U+1F71）而非 tonos。
2. **舊約 wid0 的 `uword` 行序顛倒**：`umscode` 會把整個字串反轉（希伯來 ASCII 是以視覺順序、左到右存），對整節多行字串一次轉換，行的順序也被反過來。例 創1:1：
   - `uword`：`בָָּרָא … הָָאָָרֶץ׃\n\rבְּרֵאשִׁית`（第一個字跑到最後，且 `\n\r`、qamets 重複 `ָָ`）
   - 正確：對 `word` **逐行** `umscode` → `בְּרֵאשִׁית\nבָּרָא … הָאָרֶץ׃`
   - 23,145 節中 22,142 節是多行，逐字 (wid≥1) 的 `uword` 則與 `umscode(word)` 308,657 筆完全一致
   - qp.php / qb.php 的 bhs 整節文字也有同樣行序問題，iOS 離線 parsing 的 wid0 標題列應也受影響
3. **新約 `remark` 的 `<!…!>`**：裡面是希臘 ASCII，qp.php 會轉成 Unicode 但**保留 `<!` `!>` 記號**；放進 HTML 會被當成註解吃掉（FHLNUI 彼前4:13 SN 2526 的 bug）。正確處理：`remark.replace(/<!(.*?)!>/g, (_, a) => gcode_2(a))`。例：`<!ejp# ajlhqeivas!>` → `ἐπ᾽ ἀληθείας`。iOS 離線目前是原樣顯示 ASCII（例 `<!kaqov!>= <! kaq# o&!>`），同樣需要處理
4. **逐字與整節不完全一致**：新約逐字 `uword` 依序在 wid0 裡找，7,929 節對得上，30 節對不上：
   - 逐字有錯字：太10:3 `Θμᾶς`（wid0 為 `Θωμᾶς`）、太16:23 `εὶ`（應 `εἶ`）、路9:1 `Ευγκαλεσάμενος`
   - 異文寫法不同：wid0 `+ κατακαίεται + (κατα)καίεται +`，逐字各自展開
   - 所以要組「整節嵌 SN」的文字時，**文字以 wid0 為準，逐字只提供 SN**，對齊需忽略重音、容許括號異文，對不上要回報
5. FHLNUI 舊的 `index/bible_fhlwh.json.gz`（2025-04 手動產生）與 API 比對有 180 節不同（缺標點、`ἦ`→`ὴ` 等），推測當時是由逐字資料拼出，錯字與缺標點都帶進來了

## 五、轉碼函式對照

| 用途 | iOS (Swift) | FHLNUI (JS) | 備註 |
|---|---|---|---|
| 希臘 ASCII → Unicode | `FHLTools/SNParsing/gcode2.swift` `gcode2()` | `index/gcode2.es2023.js` `gcode_2()` | 對應 PHP `gcode($t,2)`；先把字尾 `s` 換成 `"`（→ ς），再查表 |
| 希伯來 ASCII → Unicode | `FHLTools/SNParsing/umscode.swift` `umscode()` | `index/hebCode.es2023.js` `umscode()` | 對應 PHP `code.php`；逐字元查表並**反轉**，多行要逐行呼叫 |
| `12…21` 夾希伯來 | `toHebWhen1221InParsing.swift` | （尚無） | 對應 PHP `hebpar()`，先把全形 １２ ２１ 轉半形 |
| 新約 pro / wform 代碼 | `SNParsingDealProXForm.swift` | （尚無，網頁用 qp.php 已展開的中文） | 測試：`FHLBibleTests/SNParsingOffLineTests.swift` |
| gcode2 驗證 | `FHLBibleTests/fhlwh_bug/`（py + swift，比對本機 API 與 `bible_fhlwh.sqlite`） | `tests/gcode2.test.js` | |
