# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案定位、Git、最低版本（優先閱讀）

- **FHLBible 是「完整版」主程式**（沒有 TW）；台語精簡版是兄弟專案 `../FHLBibleTW`，共用元件在 `../FHLCommon`（Framework，`import FHLCommon`）。三者在 `../FHLWorkSpace.xcworkspace` 中並列，**各自是獨立 git repo**（GitHub：`snowray712000/FHLBible`、`FHLBibleTW`、`FHLCommon`）。
- 本 repo 的 commit 只放 FHLBible 的改動。若需改 FHLCommon，到 `../FHLCommon` 改並另外 commit（先 FHLCommon，再這裡）。回報時列出每個 repo 各改了什麼。
- 只有使用者要求時才 commit / push。不要 stage `xcuserdata/`、`.DS_Store`、`.claude/`（目前 `xcuserdata` 仍被追蹤，`git status` 常顯示已修改，請略過）。Commit 訊息用繁體中文簡短描述（參考 `git log`）。目前所在 branch 可能不是 main，不要擅自切換。
- 不要動 `../FHLBible_Temp`、`../IJNSwift_Temp`（過時／實驗副本）。搜尋程式碼時排除它們。
- **最低支援版本：盡量低、不追新（目前 15.0）**：為了讓舊手機／無法更新的使用者也能用，刻意不追逐最新 iOS 開發方式。Xcode 27 的模擬器 SDK 不支援 14.0，使用者於 2026-10-21 手動把 app target 改為 15.0（尚未 commit；project 層級與 Tests 仍寫 14.0）。**不要自行調整 `IPHONEOS_DEPLOYMENT_TARGET`、不要手改 pbxproj、不要接受 Xcode 的「Update to recommended settings」、不要設成 `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`（Xcode 27 = 17.0，只是建議值）**，要動先問使用者，也不要還原使用者未 commit 的設定。只用下限以前的 API；更新的（`NavigationStack`、`@Observable`、SwiftData…）必須 `if #available` 並保留退路；iOS 15 API 非必要不引入，引入時註解標明「iOS 15+」。不要為現代化改寫既有 UIKit／`IjnEvent` 程式；新增第三方套件前先問。此環境無法實測 iOS 14，回報時說明實際驗證的版本。三個專案現況見 `../CLAUDE.md`。
- **與 FHLCommon 有約 25 個同名重複檔**（`DAddress`、`DText`、`BibleText2DText`、`IjnEvent`、`StringToVerseRange`、`VCBookChapPicker`、`SN_DICT` 相關…，內容已不同）。遷移進行中：改之前先確認 target 實際用哪一份（本地型別會遮蔽 import 進來的）；新的共用邏輯放 FHLCommon（標 `public`）；不要擅自刪除／合併重複檔。
- 其他共通守則（改動最小化、不手改 `project.pbxproj`、UI 回主執行緒、沿用繁中註解與 `$` 事件命名、回報時說明是否真的編譯／測試過）見 `../CLAUDE.md`。
- 建置可用 workspace（`xcodebuild -workspace ../FHLWorkSpace.xcworkspace -scheme <scheme> …`），改了 FHLCommon 後兩個 App 都要能編譯。

## ai-log（給未來 AI 的開發紀錄，必須遵守）

- 位置：`ai-log/`（本 repo 內；與 FHLBibleTW、FHLCommon 的 ai-log 各自獨立）。規則與範本見 `ai-log/README.md`，索引見 `ai-log/index.md`。
- **開始非瑣碎任務前**：先讀 `ai-log/index.md`，再只讀相關的 log。
- **完成有意義的工作單元後**：寫一份 `ai-log/<年>/s<季>/<MMDD><序號>_<english_title>.md`（s1=1–3 月、s2=4–6、s3=7–9、s4=10–12；序號 a…z、aa、ab…；日期用系統當天），並更新 `index.md`。例：`ai-log/2026/s4/1021a_xxx.md`。
- **英文撰寫**；目標是只靠 log 就能大致重現程式（行為、資料格式、API、演算法、決策與踩雷），不是只列改了哪些檔。
- 舊 log 不改寫；不寫入金鑰／密碼；跨專案的工作各專案各寫一份並互相指向（`Cross-project:`）。

## Build & Test

This is an Xcode iOS project. All building and testing is done through Xcode or `xcodebuild`.

```bash
# Run all tests
xcodebuild test -project FHLBible.xcodeproj -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test -project FHLBible.xcodeproj -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FHLBibleTests/BibleReadDataGetterTests
```

Some tests in `FHLBibleTests/fhlwh_bug/` require a local server at `192.168.0.116:5600`. They use `XCTSkip` if the server is unavailable.

## Architecture Overview

**FHLBible** is a Bible reader iOS app supporting multiple translations, full-text search, audio playback, Strong's numbers (Hebrew/Greek), and scripture notes.

### Module Structure

- **`FHLBible/Read/`** — Bible reading view and data pipeline (core module)
- **`FHLBible/Search/`** — Full-text search (keyword input + results)
- **`FHLBible/FHLTools/`** — SNParsing (Strong's/Hebrew analysis), SNDict (word lookup), Tsk (scripture notes)
- **`FHLBible/VCAudioBible/`** — Audio Bible playback with rate control
- **`FHLBible/Download/`** — Bible version downloading and SQLite file management
- **`FHLBible/SQLiteFHL/`** — SQLite operations and FMDB wrappers
- **`FHLBible/Common/`** — Shared types: `DAddress`, `VerseRange`, `DOneLine`, `DText`
- **`FHLBible/Helps/`** — In-app help/tutorial (paginated images via `VCHelps`)

### Data Flow (Read Module)

```
User picks address (DAddress/VerseRange)
  → VCRead._addrsCurChanged$ event fires
  → BibleReadDataGetter.queryAsync()
      ├─ parallel: one thread per Bible version
      ├─ BibleGetterViaSQLiteOrApi decides: SQLite file OR FHL API
      └─ merges results → BibleText2DText.main() → [DOneLine]
  → VCRead._dataChanged$ event fires → drawData()
  → ViewDisplayTable2 renders TpOneRow[] as UITableView
```

### Key Types

| Type | Role |
|------|------|
| `VerseRange` | Bible address range (book/chapter/verse) |
| `DAddress` | Single verse with multilingual book name support |
| `DOneLine` | One verse from one translation; contains `DText[]` |
| `DText` | Rich text node — may carry Strong's number, notes, or plain text |
| `TpOneRow` | Row for `ViewDisplayTable2`; first row = translation labels (title), rest = verse content |

### Event System

`VCRead` uses `IjnEventOnce`-based callbacks wired in `viewDidLoad`:
- `_addrsCurChanged$` → `updateData()` (fetch new data)
- `_dataChanged$` → `drawData()` (re-render table)
- `_versChanged$` → `updateData()` (translation selection changed)
- `_isSnOnChanged$` → `drawData()` (Strong's numbers toggle)

### Shared Display Core

`ViewDisplayTable2` (`v2` in `VCRead`) is reused by both **Read** and **Search** modes (`.ModeOrig` vs search mode). The key method is `_tryQueryDataThenUpdate` — it batch-queries multiple verses when cells come into view. Data is passed via a `DataForDrawTable` instance (`iQ`).

### Data Sources

- **SQLite** (`BibleGetterViaSQLiteFile`): local `.sqlite` files downloaded per version
- **FHL API** (`BibleGetterViaFhlApiQsb`): remote HTTP API, used as fallback when SQLite not present
- Both paths funnel through `BibleText2DText` to produce `DText[]`

### Search Flow

`VCRead.doSearch()` → `VCSearching` (keyword + history picker) → back to `VCRead` → `VCSearchResult`

In `VCSearchResult`: API result stored in `_searchResult` → `DataForDrawTable` transforms it → `_dataForTable` → `ViewDisplayTable2`. Changing filter/translation options requires re-creating `DataForDrawTable`.

### Dependencies

- `FHLCommon` — shared framework imported by most files
- `FMDB` — SQLite wrapper
- `ZIPFoundation` — downloading/unzipping Bible version files
- `AVFoundation` — audio playback
