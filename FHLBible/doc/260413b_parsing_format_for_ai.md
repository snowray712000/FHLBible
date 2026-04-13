# FHL Bible — qp API & SNParsing Data Format (AI Reference)

## SUMMARY

This document describes the data format returned by the FHL Bible `qp.php` API and how the iOS app parses it into display structures for the SNParsing (Strong's Number / word-by-word analysis) feature.

**Key facts for AI agents:**
- API endpoint: `https://bible.fhl.net/json/qp.php?engs=<book>&chap=<chapter>&sec=<verse>&gb=<0|1>`
- `record[0]` is a **header record** (wid=0); `record[1+]` are **word records**
- `N=0` → New Testament (Greek); `N=1` → Old Testament (Hebrew)
- `record[0].word` and `record[0].exp` may contain `\n` to split verse into display clauses; the newline count is always equal between the two fields
- NT only: some verses have **manuscript variant markers** `+ [WH] + [UBS] +` embedded in `record[0].word`, and `+` also appears as real word records (wid with `word="+"`)
- The Swift parser is in `FHLBible/FHLTools/SNParsing/ConvertorQp2VCParsingData.swift`
- The model types are in `FHLCommon/FHLCommon/FHLApi/DApiQp.swift`

---

## 1. API Endpoint

```
GET https://bible.fhl.net/json/qp.php
Parameters:
  engs  — English book abbreviation, e.g. "Gen", "Matt", "Rev"
  chap  — chapter number (1-based)
  sec   — verse number (1-based)
  gb    — 0 = Traditional Chinese, 1 = Simplified Chinese
```

Top-level response fields:

| Field          | Type    | Description                                      |
|----------------|---------|--------------------------------------------------|
| `status`       | string  | "success" on success                             |
| `record_count` | number  | Total records including header (= word count +1) |
| `N`            | number  | 0 = NT (Greek), 1 = OT (Hebrew)                  |
| `record`       | array   | Array of records; see below                      |
| `prev`         | object  | Previous verse navigation reference              |
| `next`         | object  | Next verse navigation reference                  |

`prev` / `next` structure: `{ engs, chineses, chap, sec }`

---

## 2. Record Structure

### 2a. record[0] — Header Record (wid = 0)

Contains the full verse text and translation. **Does NOT have word-analysis fields.**

| Field      | Type   | Notes                                                      |
|------------|--------|------------------------------------------------------------|
| `id`       | number | Record identifier                                          |
| `engs`     | string | Book abbreviation                                          |
| `chap`     | number | Chapter                                                    |
| `sec`      | number | Verse                                                      |
| `wid`      | number | Always 0                                                   |
| `word`     | string | Full verse in original language (Greek/Hebrew). May contain `\n` to split into display clauses. NT: may contain `+ WH + UBS +` manuscript variant markers. |
| `exp`      | string | Full Chinese translation. Contains `\n` at same positions as `word`. |
| `chineses` | string | Chinese book abbreviation, e.g. "太", "創"                |
| `chinesef` | string | Full Chinese book name, e.g. "馬太福音", "創世記"         |

**Absent fields:** `sn`, `pro`, `wform`, `orig`, `remark`

### 2b. record[1+] — Word Records (wid ≥ 1)

Each record corresponds to one word (or manuscript-variant marker) in the original text.

| Field    | Type   | Notes                                                                |
|----------|--------|----------------------------------------------------------------------|
| `id`     | number | Record identifier                                                    |
| `engs`   | string | Book abbreviation                                                    |
| `chap`   | number | Chapter                                                              |
| `sec`    | number | Verse                                                                |
| `wid`    | number | Sequential word index starting at 1                                  |
| `word`   | string | Individual Greek/Hebrew word. For manuscript-variant boundary records, this is `"+"`. |
| `sn`     | string | Strong's number (digits only, no prefix). Empty `""` for `+` records. |
| `pro`    | string | Part of speech in Chinese (NT API) or short code (offline DB)       |
| `wform`  | string | Grammatical form description                                         |
| `orig`   | string | Lexical base form of the word                                        |
| `exp`    | string | Chinese gloss / definition                                           |
| `remark` | string | Additional notes (often empty)                                       |

**Absent fields:** `chineses`, `chinesef`

---

## 3. Manuscript Variant Markers (NT Only)

Some NT verses have textual differences between the **Westcott-Hort (WH / 韋氏)** and **UBS (聯合聖經公會)** Greek manuscripts.

### Encoding in record[0].word

The variant is encoded inline as:
```
... preceding_word + WH_word + UBS_word + following_word ...
```

Example — Matt 28:1:
```
Ὠψὲ δὲ σαββάτων, τῇ ἐπιφωσκούσῃ εἰς μίαν σαββάτων ἦλθεν + Μαρία + Μαριὰμ + ἡ Μαγδαληνὴ ...
```
Here `+ Μαρία + Μαριὰμ +` means: WH has "Μαρία", UBS has "Μαριὰμ".

### Encoding in word records

The `+` characters also appear as **actual word records**:

| wid | word     | sn  | Notes                        |
|-----|----------|-----|------------------------------|
| 9   | ἦλθεν    | ... | Normal word                  |
| 10  | +        | ""  | Manuscript variant boundary  |
| 11  | Μαρία    | ... | WH variant word              |
| 12  | +        | ""  | Manuscript variant boundary  |
| 13  | Μαριὰμ   | ... | UBS variant word             |
| 14  | +        | ""  | Manuscript variant boundary  |
| 15  | ἡ        | ... | Normal word                  |

So `+` records have empty `sn`, `pro`, `wform`, `orig`, `exp`, `remark`.

### Display transformation

The Swift function `ssDtGreekPlusPlusPlus` (in `FHLCommon`) transforms the display text:

Input:  `... ἦλθεν + Μαρία + Μαριὰμ + ἡ ...`  
Output: `... ἦλθεν (韋:Μαρία)(聯:Μαριὰμ) ἡ ...`

Regex used: `\+([^\+]+)+\+([^\+]+)\+`

---

## 4. Swift Parsing Pipeline

### Key files

| File | Role |
|------|------|
| `FHLCommon/FHLCommon/FHLApi/DApiQp.swift` | `DApiQp` and `DApiQpRecord` Decodable models |
| `FHLBible/FHLTools/SNParsing/ConvertorQp2VCParsingData.swift` | Core converter: API data → `[ViewParsing.OneSet]` |
| `FHLBible/FHLTools/SNParsing/VCParsingIReloadDataViaQpApi.swift` | API fetcher and adapter |
| `FHLBible/FHLTools/SNParsing/VCParsingIReloadDataViaOfflineDatabase.swift` | Offline SQLite adapter |
| `FHLCommon/FHLCommon/BibleText_To_DText/SplitString/SSGreekPlusPlushPlsu.swift` | `ssDtGreekPlusPlusPlus` implementation |
| `FHLBible/FHLTools/SNParsing/VCParsing.swift` | View controller; calls `ConvertorQp2VCParsingData` |

### Data flow

```
API / SQLite
  └─ DApiQp { record: [DApiQpRecord], N, prev, next }
       └─ ConvertorQp2VCParsingData.main()
            ├─ isOldTestment() ? mainOldTestment() : mainNewTestment()
            │
            ├─ r1 = splitByNewLines(record[0].word)     // clause strings (Greek/Hebrew)
            ├─ r2 = r1.map { [DText($0)] }
            ├─ r2b = r2.map { ssDtGreekPlusPlusPlus($0, nil) }  // merge variant markers for display
            ├─ r3 = splitByNewLines(record[0].exp)      // clause strings (Chinese)
            ├─ r4 = r3.map { [DText($0)] }
            │    assert(r1.count == r3.count)
            │
            ├─ r6 = record[1...].map { ViewParsingDict.OneData }   // all word records
            │
            ├─ r7 = r1.map { countSpaceAndDash($0) }   // separator count per clause
            │    // determines how many word records belong to each clause
            │
            └─ r8 = grouping loop: for each clause, take (r7[i]+1) records from r6
                 // last clause gets any remaining records as safety fallback
                 // OT: r7 is iterated in reversed() order
                 
Output: words=[r2b], exps=[r4], dicts=[r8]  →  [ViewParsing.OneSet]
  where OneSet = (words: [DText], exp: [DText], dict: [ViewParsingDict.OneData])
```

### countSpaceAndDash — word count per clause

```swift
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(...)
}
```

Returns the number of **word separator runs** in a clause string.  
`[ -]+` is a character class ranging from ASCII 0x20 (space) to 0x2D (dash), which includes: space, !, ", #, $, %, &, ', (, ), *, **+**, comma, -.

**Important:** The `+` character (ASCII 0x2B) falls within this range. Therefore ` + ` between two words is counted as **one** separator run, not two. This interacts with the manuscript variant `+` records.

### Hebrew (OT) differences

- `r6` word records use prefix `"H"` for Strong's: `DText("H\(sn)", ...)`
- `self.words = r2.reversed()` — display order is right-to-left
- The grouping loop iterates `r7.reversed()` to assign word records in correct visual order
- `wform` and `exp` values from offline DB may contain Hebrew encoded as U+0012/U+0021 escape sequences, processed by `toHebWhen1221InParsing()`

### Offline database differences

When offline DB (`parsing.db` / `parsing_gb.db`) is used instead of the API:
- OT table: `lparsing2`; NT table: `fhlwhparsing2`
- NT `pro` and `wform` fields contain encoded strings (e.g., "ngsm") processed by `SNParsingDealProXForm`
- `record[0].word` may have leading whitespace (trimmed with `trimmingCharacters(in: .whitespaces)`)
- `record[0].word` or `.exp` may be nil for some OT verses (fallback: `"."` / error message)
- `isOldTestment()` is determined by `addr.book < 40` (not by `N` field)
- `prev`/`next` are synthesized from `addr.goNextVerse()` / `addr.goPrevVerse()`

---

## 5. Output Types

### ViewParsing.OneSet
```
typealias OneSet = (words: [DText], exp: [DText], dict: [ViewParsingDict.OneData])
```
One element per display clause (one line of original text + translation + word analysis list).

### ViewParsingDict.OneData
Fields: `word: DText`, `sn: DText`, `pro: String`, `wform: [DText]`, `orig: DText`, `exp: [DText]`, `remark: [DText]`

---

## 6. Notes & Known Observations

- `record_count` in the API response equals `record.count` (header + words). The Swift model reads `record[]` directly via `Decodable`.
- The `+` boundary records (empty `sn`) are currently included in `r6` and mapped to `ViewParsingDict.OneData` entries with empty/meaningless Strong's data.
- `countSpaceAndDash` uses `[ -]+` which treats `+` as part of the separator class. This interacts with the manuscript variant encoding. See section 3 for details.
- The `assert(r1.count == r3.count)` will crash in debug builds if the API returns mismatched newline counts between `word` and `exp`.
