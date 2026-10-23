# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案定位、Git、最低版本（優先閱讀）

- **FHLBible 是「完整版」主程式**（沒有 TW）；台語精簡版是兄弟專案 `../FHLBibleTW`，共用元件在 `../FHLCommon`（Framework，`import FHLCommon`）。三者在 `../FHLWorkSpace.xcworkspace` 中並列，**各自是獨立 git repo**（GitHub：`snowray712000/FHLBible`、`FHLBibleTW`、`FHLCommon`）。
- 本 repo 的 commit 只放 FHLBible 的改動。若需改 FHLCommon，到 `../FHLCommon` 改並另外 commit（先 FHLCommon，再這裡）。回報時列出每個 repo 各改了什麼。
- 只有使用者要求時才 commit / push。不要 stage `xcuserdata/`、`.DS_Store`、`.claude/`（目前 `xcuserdata` 仍被追蹤，`git status` 常顯示已修改，請略過）。Commit 訊息用繁體中文簡短描述（參考 `git log`）。目前所在 branch 可能不是 main，不要擅自切換。
- 不要動 `../FHLBible_Temp`、`../IJNSwift_Temp`（過時／實驗副本）。搜尋程式碼時排除它們。
- **最低支援版本：17.0（2026-10-21 起，使用者決定）**：實測 `xcodebuild -showBuildSettings` 為 17.0；pbxproj 內所有 `IPHONEOS_DEPLOYMENT_TARGET` 皆已明確寫成 `17.0` 並 commit（使用者 2026-10-21 確認），不要再寫成 `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`。**不要自行調整 `IPHONEOS_DEPLOYMENT_TARGET`、不要手改 pbxproj、不要接受 Xcode 的「Update to recommended settings」**，要動先問使用者，也不要還原使用者未 commit 的設定。可直接用 iOS 17 以前的 API（含 SwiftUI、`NavigationStack`、`@Observable`）；iOS 18 以後必須 `if #available` 並保留退路。新增第三方套件前先問。此環境有 iOS 17.4 與 27.0 模擬器，回報時說明實際驗證的版本。三個專案現況見 `../CLAUDE.md`。
- **用詞（2026-10-21 使用者決定）**：UI 文字一律稱「譯本」（translation），不要用「版本」，因為「版本」會和 App 版本搞混（「版本資訊」指 App 版本，沒問題）。程式裡的 `version`／`vers`（FHL API 的譯本代碼）維持原樣。
- **UI 技術（2026-10-21 起）**：UIKit 為主；簡單畫面**逐個**改 SwiftUI（以 `UIHostingController` push 進現有導覽），不再新增 storyboard scene。已改：「版本資訊」（`Helps/VCVersionInfo.swift` 內的 `VersionInfoView`）、「設定」（`VCSetting/VCSettings.swift` 內的 `SettingsView`）、「教學」（`Helps/VCHelps.swift` 內的 `HelpsView`／`HelpPagesView`）、「資料」（`Download/VCData.swift` 內的 `DataListView`，只換畫面層，下載邏輯維持原樣）、「串珠」（`FHLTools/Tsk/VCTsk.swift` 內的 `TskView`；經文內容用 `UIViewRepresentable` 包 `ViewDisplayCell`，已從 `Main.storyboard` 移除，改以 `VCTsk(addr:)` 建立）、「有聲文字速度」（`VCAudioTextBible/VCAudioTextSpeed.swift` 內的 `AudioTextSpeedView`，已從 `Main.storyboard` 移除，改以 `VCAudioTextSpeed()` 建立）、「閱讀記錄」（`History/VCReadHistory.swift` 內的 `ReadHistoryView`，已從 `Main.storyboard` 移除，改以 `VCReadHistory()` 建立）、「有聲文字」（`VCAudioTextBible/VCAudioTextBible.swift` 內的 `AudioTextBibleView`，已從 `Main.storyboard` 移除，改以 `VCAudioTextBible(addr:vers:)` 建立；播放核心 `AudioTextBibleTTSCore` 不變）、「有聲聖經」（`VCAudioBible/VCAudioBible.swift` 內的 `AudioBibleView`，已從 `Main.storyboard` 移除，改以 `VCAudioBible(book:chap:)` 建立；播放核心 `EasyAVPlayer`／`AudioBibleSetter`／`DAudioBible` 不變）、「譯本比較」（`VCVersionsCompareInOneVerse/VCVersionsCompareInOneVerse.swift` 內的 `VersionsCompareView`，已從 `Main.storyboard` 移除，改以 `VCVersionsCompareInOneVerse(addr:)` 建立；類別／檔名沿用舊名以免動 pbxproj；經文用 `DTextContentView`）、「書卷選擇」（`BookChapPicker/VCBookChapPicker.swift` 內的 `BookChapPickerView`，已從 `Main.storyboard` 移除，改以 `BookChapPickerViewController(book:chap:)` 建立、`onClick$` 契約不變；**只依賴 FHLCommon 公開 API，預定整份搬進 FHLCommon 給 FHLBibleTW 共用**，搬移清單見 `ai-log/2026/s4/1021u_*`；檔名沿用舊名以免動 pbxproj）；「註釋」（`FHLTools/Comment/VCComment.swift` 內的 `CommentView`／`CommentModel`，已從 `Main.storyboard` 移除，改以 `VCComment(addr:)` 建立；UI 一律寫「註釋」，不要寫「注釋」；`IReloadData` 等資料型別仍在 `VCComment*IReloadData*.swift`，串珠共用）；`VCVersionInfo`／`VCSettings`／`VCHelps`／`VCData`／`VCTsk`／`VCAudioTextSpeed`／`VCReadHistory`／`VCAudioTextBible`／`VCAudioBible`／`VCVersionsCompareInOneVerse`／`BookChapPickerViewController`／`VCComment` 是包它們的 `UIHostingController`。首頁那顆「教學」按鈕本身仍在 `Main.storyboard`。「閱讀」（`Read/VCRead.swift` 內的 `ReadView`／`ReadModel`，已從 `Main.storyboard` 移除，改以 `VCRead()` + `setInitData(addr, vers)` 建立；一節一列、多譯本上下排、底部列放譯本與上下章、`Menu` 取代 `VCReadMore`、複選以 `ReadCellKey` 逐格記錄；細節見 `ai-log/2026/s4/1021w_*`）；`VCRead` 也是包它的 `UIHostingController`。「注腳」（`Read/Footer/VCFooter.swift` 內的 `FootnoteView`／`FootnoteModel`，已從 `Main.storyboard` 移除，改以 `VCFooter(dtext:ver:addr:vers:)` 建立；細節見 `ai-log/2026/s4/1021x_*`）也是 `UIHostingController`。「字典」（`FHLTools/SNDict/VCSnDict.swift` 內的 `SnDictView`／`SnDictModel`，已從 `Main.storyboard` 移除，改以 `VCSnDict(dtext:addr:vers:)` 建立；上方 CBOL／浸宣分段選單、工具列彙編與上下一字；`VCSnDictMore.swift` 已不用但仍在 pbxproj，留空殼；細節見 `ai-log/2026/s4/1021y_*`）也是 `UIHostingController`。「Parsing」（原文逐字分析；`FHLTools/SNParsing/VCParsing.swift` 內的 `ParsingView`／`ParsingModel`，已從 `Main.storyboard` 移除，改以 `VCParsing(addr:vers:)` 建立，取代 `gVCParsing()`／`set`；一個分句一個區段、一個字一張卡片，資料層 `ReloadDataAutoUseOfflineOrScApi`／`ConvertorQp2VCParsingData` 不變；舊的 `ViewParsing*`／`ViewSNDictCell` 四個 swift 只剩註解空殼、四個 xib 成了孤兒，需要在 Xcode 內移除；細節見 `ai-log/2026/s4/1022c_*`）也是 `UIHostingController`。「搜尋ing」（關鍵字輸入 + 搜尋記錄；`Search/ViewSearching.swift` 內的 `SearchingView`／`SearchingModel`，`.searchable` 系統搜尋列，已從 `Main.storyboard` 移除，改以 `VCSearching()` 建立、`onClickSearching$` 契約不變）與「搜尋結果」（`Search/VCSearchResult.swift` 內的 `SearchResultView`／`SearchResultModel`，`Search/ViewSearchFilter.swift` 內的 `SearchFilterBar` 篩選列，已從 `Main.storyboard` 移除，改以 `VCSearchResult(keyword:vers:addr:)` 建立，取代 `setInitData`／`gVCSearchResult()`；經文捲到才用既有 `DataForDrawTable` 一次取附近 40 節；細節見 `ai-log/2026/s4/1022b_*`）也是 `UIHostingController`；舊的 `ViewSearching`／`ViewSearchFilter` 兩個 xib 還在 pbxproj，成了孤兒，需要在 Xcode 內移除。`ViewDisplayCell`（`UITextView` 逐字點擊）留在 UIKit，經文內容在 SwiftUI 以 `DTextContentView` 包 `ViewDisplayCell`；`ViewDisplayTable2`／`ViewDisplayRow`（表格）已沒有任何畫面使用（只剩 `ViewDisplayTable2.OneRow` 型別別名與 `IViewDisplayTable2DataQ` 協定被借用），仍留在專案內，不要主動刪。SwiftUI 的 `Menu` 在父 view 重畫時會自己關閉：每 0.5～1 秒更新的值（進度、倒數）要放在獨立的子 view 讀取（範例：`AudioBibleProgressView`、`AudioTimerTile`）。既有可運作的 UIKit／`IjnEvent` 程式一次改一個、先問使用者。
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
  → ReadModel.setAddr()  (ManagerAddress, history, reload)
  → ReadDataQ.qDataForReadAsync()  → BibleReadDataGetter.queryAsync()
      ├─ parallel: one thread per Bible version
      ├─ BibleGetterViaSQLiteOrApi decides: SQLite file OR FHL API
      └─ merges results → BibleText2DText.main() → [DOneLine]
  → main thread: ReadModel.rows (stale responses dropped by requestId)
  → ReadView (SwiftUI List) → DTextContentView → ViewDisplayCell (UITextView)
```

(`ViewDisplayTable2` and `TpOneRow` are no longer used by any screen; Search moved to SwiftUI too, see `ai-log/2026/s4/1022b_*`.)

### Key Types

| Type | Role |
|------|------|
| `VerseRange` | Bible address range (book/chapter/verse) |
| `DAddress` | Single verse with multilingual book name support |
| `DOneLine` | One verse from one translation; contains `DText[]` |
| `DText` | Rich text node — may carry Strong's number, notes, or plain text |
| `ReadRow` / `SearchRow` | Row of the SwiftUI Read / Search-result screen (`TpOneRow` belongs to the now-unused `ViewDisplayTable2`) |

### Event System

The Read and Search screens no longer use `IjnEvent` for their own state; `ReadModel` / `SearchResultModel` (`@Observable`) hold it and `VCRead` / `VCSearchResult` handle pushes. `IjnEvent` is still used by pickers (`onClick$`, `onClickOkay$`, `onClickAddr$`, `onClickSearching$`) and by the unchanged data layer (`SearchQ`, `DataForDrawTable`, `ReadDataQ`).

### Shared Display Core

`ViewDisplayCell` (UITextView, per-character taps) is the only UIKit display piece left; SwiftUI screens embed it through `DTextContentView` (`FHLTools/Tsk/VCTsk.swift`). `ViewDisplayTable2` / `ViewDisplayRow` are no longer instantiated by any screen (Read moved to SwiftUI in `ai-log/2026/s4/1021w_*`, Search in `1022b_*`); keep them, do not delete without asking. `DataForDrawTable` (Search/SearchQ) is still the lazy batch loader for search results.

### Data Sources

- **SQLite** (`BibleGetterViaSQLiteFile`): local `.sqlite` files downloaded per version
- **FHL API** (`BibleGetterViaFhlApiQsb`): remote HTTP API, used as fallback when SQLite not present
- Both paths funnel through `BibleText2DText` to produce `DText[]`

### Search Flow

`VCRead` search button → `VCSearching` (SwiftUI `SearchingView`: system search bar + history) → pops itself, fires `onClickSearching$` → `VCRead` pushes `VCSearchResult(keyword:vers:addr:)`.

In `SearchResultModel`: `SearchQ` result stored in `searchResult` (all addresses + counts) → `applyFilter()` makes `rows` (addresses only) and a fresh `DataForDrawTable` for the selected book/classor → `rowAppeared(i)` batch-queries rows i-10..i+30 → `absorb()` copies the verses (keyword already coloured) into `rows[i].cells` on the main thread. Changing the filter re-creates `DataForDrawTable` (the old one is marked `isAlreadyNoUse`). SN toggle is local to the result screen (`isSnVisible`), not the global Read one.

### Dependencies

- `FHLCommon` — shared framework imported by most files
- `FMDB` — SQLite wrapper
- `ZIPFoundation` — downloading/unzipping Bible version files
- `AVFoundation` — audio playback
