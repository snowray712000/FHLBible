# FHL Bible — qp API 與 SNParsing 資料格式說明

## 一、API 端點

```
GET https://bible.fhl.net/json/qp.php
參數：
  engs  — 英文書名縮寫，例如 "Gen"、"Matt"、"Rev"
  chap  — 章（從 1 開始）
  sec   — 節（從 1 開始）
  gb    — 0 = 繁體中文，1 = 簡體中文
```

回傳 JSON 的最外層欄位：

| 欄位           | 型別   | 說明                                          |
|----------------|--------|-----------------------------------------------|
| `status`       | string | 成功時為 "success"                             |
| `record_count` | number | 全部 record 數量，包含首筆 header（= 字詞數+1）|
| `N`            | number | 0 = 新約（希臘文）；1 = 舊約（希伯來文）       |
| `record`       | array  | 資料陣列，見下方說明                           |
| `prev`         | object | 上一節的導覽資訊                               |
| `next`         | object | 下一節的導覽資訊                               |

`prev` / `next` 結構：`{ engs, chineses, chap, sec }`

---

## 二、record 結構

### record[0] — Header（wid = 0）

存放整節的原文與中文直譯，**沒有**逐字分析欄位。

| 欄位       | 說明 |
|------------|------|
| `word`     | 整節原文（希臘文或希伯來文）。可能含有 `\n` 將句子分成多個顯示子句；新約部分節次還可能含有 `+ 韋 + 聯 +` 抄本差異標記。 |
| `exp`      | 整節中文直譯。`\n` 的位置與數量和 `word` 完全對應。 |
| `chineses` | 書名縮寫，例如「太」、「創」 |
| `chinesef` | 完整書名，例如「馬太福音」、「創世記」 |

**沒有** `sn`、`pro`、`wform`、`orig`、`remark`。

### record[1+] — 逐字資料（wid ≥ 1）

每筆對應一個字詞（或抄本差異分隔符號 `+`）。

| 欄位     | 說明 |
|----------|------|
| `word`   | 單一希臘文或希伯來文字詞。若為抄本差異邊界，則值為 `"+"` |
| `sn`     | 史特朗號碼（純數字，不含前綴）。`+` 記錄的 sn 為空字串 |
| `pro`    | 詞性（API 回傳中文，離線 DB 為縮寫代碼） |
| `wform`  | 詞形分析描述 |
| `orig`   | 詞典原型（字根形） |
| `exp`    | 中文簡義 |
| `remark` | 補充說明（常為空） |

**沒有** `chineses`、`chinesef`。

---

## 三、新約抄本差異標記

部分新約節次在 **韋氏（Westcott-Hort / 韋）** 與 **聯合聖經公會（UBS / 聯）** 抄本之間有文字差異。

### record[0].word 中的標記方式

差異以內嵌方式呈現：
```
... 前一個字 + 韋氏用字 + 聯合用字 + 後一個字 ...
```

範例 — 太 28:1：
```
Ὠψὲ δὲ σαββάτων, τῇ ἐπιφωσκούσῃ εἰς μίαν σαββάτων ἦλθεν + Μαρία + Μαριὰμ + ἡ Μαγδαληνὴ ...
```
意思：韋氏用「Μαρία」，聯合用「Μαριὰμ」。

### 對應的 word record

`+` 符號也會出現為**真實的 word record**：

| wid | word   | sn  | 說明 |
|-----|--------|-----|------|
| 9   | ἦλθεν  | ... | 正常字詞 |
| 10  | +      | ""  | 抄本差異邊界 |
| 11  | Μαρία  | ... | 韋氏抄本字詞 |
| 12  | +      | ""  | 抄本差異邊界 |
| 13  | Μαριὰμ | ... | 聯合抄本字詞 |
| 14  | +      | ""  | 抄本差異邊界 |
| 15  | ἡ      | ... | 正常字詞 |

即 `+` 記錄的 `sn`、`pro`、`wform`、`orig`、`exp`、`remark` 均為空字串。

### 顯示轉換

`ssDtGreekPlusPlusPlus`（位於 FHLCommon）將顯示文字轉換：

- 輸入：`... ἦλθεν + Μαρία + Μαριὰμ + ἡ ...`
- 輸出：`... ἦλθεν (韋:Μαρία)(聯:Μαριὰμ) ἡ ...`

使用的 regex：`\+([^\+]+)+\+([^\+]+)\+`

---

## 四、Swift 解析流程

### 相關檔案

| 檔案 | 說明 |
|------|------|
| `FHLCommon/.../DApiQp.swift` | `DApiQp`、`DApiQpRecord` Decodable 模型 |
| `FHLBible/.../ConvertorQp2VCParsingData.swift` | 核心轉換器，API 資料 → `[ViewParsing.OneSet]` |
| `FHLBible/.../VCParsingIReloadDataViaQpApi.swift` | API 抓取與 Adapter |
| `FHLBible/.../VCParsingIReloadDataViaOfflineDatabase.swift` | 離線 SQLite Adapter |
| `FHLCommon/.../SSGreekPlusPlushPlsu.swift` | `ssDtGreekPlusPlusPlus` 實作 |

### 解析步驟（以新約為例）

```
record[0].word  →  splitByNewLines()  →  r1（子句字串陣列）
                                               ↓
                              map { [DText($0)] }  →  r2
                                               ↓
                       map { ssDtGreekPlusPlusPlus }  →  r2b（顯示用，抄本差異已合併）

record[0].exp   →  splitByNewLines()  →  r3（中文子句陣列）
                              assert(r1.count == r3.count)
                                               ↓
                              map { [DText($0)] }  →  r4

record[1...]    →  map { ViewParsingDict.OneData }  →  r6（全部字詞資料）

r1.map { countSpaceAndDash($0) }  →  r7（每子句的分隔符數量）

分組迴圈：每個子句從 r6 取 (r7[i]+1) 筆  →  r8
  │  最後一個子句：若 r6 還有剩，全數附加（安全措施）
  └─ 舊約：以 r7.reversed() 迭代

輸出：words=r2b, exps=r4, dicts=r8  →  [ViewParsing.OneSet]
```

### countSpaceAndDash — 計算每子句有幾個字

```swift
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(...)
}
```

這個函式回傳子句字串中**分隔符連續段落**的數量，再加 1 即為字詞數。

**注意：** `[ -]+` 是一個字元範圍類別（ASCII 0x20 到 0x2D），其中**包含 `+` 號（0x2B）**。因此 ` + `（空格＋加號＋空格）整段會被視為**一個**分隔符，而不是兩個。這對含有抄本差異標記的節次有影響（詳見第五節）。

### 舊約的差異

- 強調號前綴為 `"H"`（新約為 `"G"`）
- `self.words = r2.reversed()`（希伯來文從右到左）
- 分組迴圈用 `r7.reversed()` 迭代
- 離線 DB 的 `wform`、`exp`、`remark` 可能含有以 U+0012/U+0021 編碼的希伯來文，需經 `toHebWhen1221InParsing()` 處理

### 離線資料庫的差異

使用 `parsing.db` / `parsing_gb.db` 時：

| 項目 | 差異 |
|------|------|
| 舊約資料表 | `lparsing2` |
| 新約資料表 | `fhlwhparsing2` |
| NT `pro`/`wform` | 含縮寫代碼（如 "ngsm"），經 `SNParsingDealProXForm` 解碼 |
| `record[0].word` | 可能有前置空白，已用 `trimmingCharacters` 去除 |
| `record[0].word` 或 `.exp` | 少數舊約節次可能為 nil，Fallback 為錯誤提示訊息 |
| `isOldTestment()` | 依 `addr.book < 40` 判斷（不依 `N` 欄位） |
| `prev`/`next` | 由 `addr.goNextVerse()` / `addr.goPrevVerse()` 合成 |

---

## 五、輸出型別

### ViewParsing.OneSet

```swift
typealias OneSet = (words: [DText], exp: [DText], dict: [ViewParsingDict.OneData])
```

一個 OneSet 對應**一個顯示子句**（一行原文 + 一行中文 + 該行的逐字分析列表）。

### ViewParsingDict.OneData

| 屬性      | 型別          | 說明 |
|-----------|---------------|------|
| `word`    | `DText`       | 顯示的字詞 |
| `sn`      | `DText`       | 強調號（含前綴 G/H） |
| `pro`     | `String`      | 詞性 |
| `wform`   | `[DText]`     | 詞形分析 |
| `orig`    | `DText`       | 字根原型 |
| `exp`     | `[DText]`     | 中文簡義 |
| `remark`  | `[DText]`     | 補充說明 |

---

## 六、已知注意事項

1. **`+` record 會被納入 r6**：目前 `+` 邊界記錄（sn 為空）也被轉換成 `ViewParsingDict.OneData` 放入逐字分析列表，顯示時會出現空白的強調號條目。

2. **`countSpaceAndDash` 與 `+` 的交互**：因為 `[ -]+` 包含 `+`，含有抄本差異標記的子句，其字詞數計算可能不準確，造成分組錯位。

3. **assert 會在 debug 模式崩潰**：若 API 回傳的 `word` 與 `exp` 換行數不相等，`assert(r1.count == r3.count)` 會在 debug build 觸發。

4. **`record_count` 欄位**：等於 `record` 陣列長度，包含 header。Swift 模型直接從 `record[]` 讀取，不依賴此欄位。
