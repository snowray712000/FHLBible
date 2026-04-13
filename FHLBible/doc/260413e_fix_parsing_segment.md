# FHL Bible — SNParsing 分段錯誤修復說明

## 一、問題描述

### 症狀（以太 28:4 為例）

Parsing 畫面中，此節有 2 個換行，顯示為 3 段：

1. `ἀπὸ δὲ τοῦ φόβου αὐτοῦ` / 因對他的恐懼
2. `ἐσείσθησαν οἱ τηροῦντες` / 守衛的人們被刺激顫抖
3. `καὶ ἐγενήθησαν ὡς νεκροί.` / 變成如同死人一樣。

**Bug**：G04579（ἐσείσθησαν）本應在第 2 段的逐字分析列表，卻出現在第 1 段底部。

---

## 二、根本原因

### 原因一：API 回傳的換行前有空格

qp API 在 `record[0].word` 的 `\n` 前帶有一個空格：

```
"ἀπὸ δὲ τοῦ φόβου αὐτοῦ \nἐσείσθησαν οἱ τηροῦντες \nκαὶ ἐγενήθησαν ὡς νεκροί."
                        ↑ 空格                      ↑ 空格
```

### 原因二：`splitByNewLines` 不修剪空白

```swift
// FHLBible/Tools/SplitByNewLines.swift
public func splitByNewLines(str: String) -> [String] {
    return str.components(separatedBy: CharacterSet.newlines).filter({ !$0.isEmpty })
}
```

切分後，第 0 子句 = `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "` — **結尾的空格被保留下來**。

### 原因三：`countSpaceAndDash` 把結尾空格算進去了

```swift
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(...)
}
```

Regex `[ -]+` 是 ASCII 0x20（空格）到 0x2D（dash）的字元範圍，包含空格本身。

對於 `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "`：
- 4 個內部空格 + **1 個結尾空格** = 5 次匹配（正確應為 4）

### 原因四：字詞分組多取一個

每個子句從 r6 取 `countSpaceAndDash(子句) + 1` 個字詞記錄。

| 子句 | 字串（split 後） | 正確取法 | 實際取法 | 結果 |
|------|-----------------|---------|---------|------|
| 0 | `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "` | 4+1=5 個 | **5+1=6 個** ← Bug | wid 1–6，多取了 ἐσείσθησαν |
| 1 | `"ἐσείσθησαν οἱ τηροῦντες "` | 2+1=3 個 | 3+1=4 個（但 r6 不夠） | wid 7–8，少了一個 |
| 2 | `"καὶ ἐγενήθησαν ὡς νεκροί."` | 3+1=4 個 | 3+1=4 個 | wid 9–12 |

---

## 三、修正方式

**修改檔案**：`FHLBible/FHLTools/SNParsing/ConvertorQp2VCParsingData.swift`

在 `countSpaceAndDash` 計數前先 trim 空白：

```swift
// 修改前
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
}

// 修改後
func countSpaceAndDash(_ str: String) -> Int {
    let trimmed = str.trimmingCharacters(in: .whitespaces)
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
}
```

### 為何選擇在此處修改

- `countSpaceAndDash` 的語義是「計算子句有幾個字」，忽略首尾空白是正確行為
- 不影響顯示路徑（r2/r4 在此函式之前就已建立）
- 一個函式同時修正 `mainNewTestment` 與 `mainOldTestment`

---

## 四、影響範圍

- 任何 `record[0].word` 中有「空格接換行」的節次均受此 Bug 影響
- 線上 API 與離線資料庫路徑都經過 `ConvertorQp2VCParsingData`，一併修正
- 抄本差異 `+` 記錄的相關問題（詳見 `260413c_parsing_format.md` 第六節）屬於另一個已知問題，本次未修正
