# FHL Bible — SNParsing Segment Mismatch Bug Fix (AI Reference)

## SUMMARY

A word-grouping bug caused the first word of clause 2 to be incorrectly assigned to clause 1's dict list in the SNParsing view. The fix is a one-line trim in `countSpaceAndDash`.

**Affected file**: `FHLBible/FHLTools/SNParsing/ConvertorQp2VCParsingData.swift`  
**Symptom**: In verses with 2+ newlines (e.g. Matt 28:4), the first word of clause N+1 appears at the bottom of clause N's word analysis list.  
**Root cause**: Trailing space before `\n` in API response, not trimmed before counting separators.

---

## 1. Bug Description

### Observed symptom (Matt 28:4)

The verse has 3 display clauses:
1. `ἀπὸ δὲ τοῦ φόβου αὐτοῦ` / 因對他的恐懼
2. `ἐσείσθησαν οἱ τηροῦντες` / 守衛的人們被刺激顫抖
3. `καὶ ἐγενήθησαν ὡς νεκροί.` / 變成如同死人一樣。

**Bug**: G04579 (ἐσείσθησαν) appeared in clause 1's word analysis dict instead of clause 2.

---

## 2. Root Cause

### Step 1 — API data has trailing spaces before `\n`

The qp API returns `record[0].word` with a **space before each newline**:

```
"ἀπὸ δὲ τοῦ φόβου αὐτοῦ \nἐσείσθησαν οἱ τηροῦντες \nκαὶ ἐγενήθησαν ὡς νεκροί."
                        ↑ space                     ↑ space
```

### Step 2 — `splitByNewLines` does not trim whitespace

```swift
// FHLBible/Tools/SplitByNewLines.swift
public func splitByNewLines(str: String) -> [String] {
    return str.components(separatedBy: CharacterSet.newlines).filter({ !$0.isEmpty })
}
```

After splitting, clause 0 = `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "` (trailing space preserved).

### Step 3 — `countSpaceAndDash` counts the trailing space

```swift
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(...)
}
```

The regex `[ -]+` is a character class from ASCII 0x20 (space) to 0x2D (dash). It matches runs of: space, !, ", #, $, %, &, ', (, ), *, +, comma, -.

For `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "`:
- 4 inner spaces + **1 trailing space** = **5 matches** (correct answer: 4)

### Step 4 — Off-by-one in word grouping

Each clause gets `countSpaceAndDash(clause) + 1` word records from the pool.

| Clause | String (after split) | Expected count | Actual count | Words assigned |
|--------|----------------------|----------------|--------------|----------------|
| 0 | `"ἀπὸ δὲ τοῦ φόβου αὐτοῦ "` | 4 → 5 words | **5 → 6 words** ← bug | wid 1–6 (steals ἐσείσθησαν) |
| 1 | `"ἐσείσθησαν οἱ τηροῦντες "` | 2 → 3 words | 3 → 4 words (but pool runs out) | wid 7–8 only |
| 2 | `"καὶ ἐγενήθησαν ὡς νεκροί."` | 3 → 4 words | 3 → 4 words | wid 9–12 |

---

## 3. Fix

**Location**: `countSpaceAndDash` in `ConvertorQp2VCParsingData.swift`

Trim whitespace from the input string before counting separator runs.

```swift
// Before
func countSpaceAndDash(_ str: String) -> Int {
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
}

// After
func countSpaceAndDash(_ str: String) -> Int {
    let trimmed = str.trimmingCharacters(in: .whitespaces)
    let regSpace = try! NSRegularExpression(pattern: "[ -]+", options: [])
    return regSpace.numberOfMatches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
}
```

**Why this location:**
- Semantically correct: "count words in this clause" should ignore leading/trailing whitespace
- Does not touch the display path (r2/r4 built from r1/r3 directly, before `countSpaceAndDash` is called)
- Fixes both `mainNewTestment` and `mainOldTestment` with one change

---

## 4. Scope

- This bug affects **any verse** where `record[0].word` has a space before `\n`
- Both online API and offline DB paths go through `ConvertorQp2VCParsingData`, so both are fixed
- The `+` manuscript variant records (see `260413b_parsing_format_for_ai.md`) are a separate known issue and are **not** addressed by this fix
