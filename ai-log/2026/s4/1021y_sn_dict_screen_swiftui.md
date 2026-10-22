# Strong's dictionary screen ("字典") rewritten in SwiftUI; removed from Main.storyboard

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change with small UX improvements)
- Related logs: 1021v_comment_screen_swiftui.md and 1021o_tsk_screen_swiftui.md (same structure: hosting controller + `@Observable` model + `DTextContentView` + `SwipeHelp`), 1021x_footnote_screen_swiftui.md (scene-removal procedure)
- Cross-project: none (FHLCommon's `SnDictDataQ`, `SQLCBOLDict`, `DText.SnAction` are only used, not changed)
- Commit: not committed (working tree also holds earlier uncommitted SwiftUI migrations).
- Release notes: `Helps/app_versions.md` section `## 4.12.15 (2026.10.21o)`.

## Goal / why
Next screen of the UIKit -> SwiftUI migration. The "字典" screen shows the dictionary entry of one Strong's number (SN). It opens from the SN action picker (`VCSnActionPicker`: 彙編 / Parsing / CBOL / 浸宣) when the user taps an SN in verse text and chooses CBOL or 浸宣, and also from tapping an SN inside a dictionary entry itself.

## Behavior
- Entry: `SnDTextClickFlow._doWhenSnDTextClickedForDicts` now does `push(VCSnDict(dtext:addr:vers:))` (dtext carries `sn`, `tp` = "G"/"H", and `snAction` = `.cbol` / `.twcb`; `addr`/`vers` are only kept so that taps inside the content can open Read / search with the right context).
- Screen: inline nav title = `tp + sn` (e.g. `H430`; deliberately NOT `dtext.w`, which can be `<G3212>`). Under the nav bar (pinned via `.safeAreaInset(edge: .top)` with `.bar` background) a segmented `Picker` CBOL | 浸宣 switches the dictionary for the same SN without going back (new; old UI required returning to the picker). It is shown only when the action is `.cbol` or `.twcb`; for `.cbole` / `.dict` (not offered by the picker) a plain caption with the dictionary name is shown instead. Content in a `ScrollView` via `DTextContentView` (default justified alignment, `isVisibleSn: true` because a dictionary always shows SNs), with a `ProgressView("取得資料中...")` while loading.
- Toolbar (trailing): magnifier (彙編: push `VCSearchResult.setInitData(key, vers, addr)` — "all places where this SN occurs"), left arrow (previous number), right arrow (next number). Replaces the old right bar buttons "彙編" and "⋯"; the "⋯" menu (`VCSnDictMore`) only contained prev/next, so it was dropped. Prev is disabled when the number would drop below 1. Swipe right/left = prev/next via `SwipeHelp` (also disables the system back swipe).
- Prev/next number: first run of digits in `sn` +/- 1 (`2532a` -> `2531`, letter suffix dropped, same as before); new `DText(tp + s, sn: s, tp: tp, tp2: "")` carrying the current `snAction`. There is no upper bound; a nonexistent number just shows whatever error text the data layer returns.
- Taps inside the content: ref (`refDescription`) -> `VCRead.setInitData(VerseRange(StringToVerseRange().main(ref, nil)), ManagerBibleVersions.s.cur)` pushed; SN -> `dtext.clone()` with `snAction` = current action -> push another `VCSnDict` (same as before).
- Data: `SnDictDataQ(iFromSQL, iFromSQL)` (FHLCommon) with `iFromSQL = MySQLCbol2` (a `SQLCBOLDict` subclass adding `ISQLCBOLDictIsExist`; now a `private class` at file scope in `VCSnDict.swift`). `main(dtext)` queries CBOL (offline SQLite when present, else API) and/or 浸宣 (API) on a `DispatchGroup`, then `onFinishedQ$` fires on the main queue; `resultContent: [DText]` is shown. `IjnEventOnce` holds the callback strongly, so no extra retention was needed.

## What changed
- `FHLTools/SNDict/VCSnDict.swift` rewritten (name kept so pbxproj is untouched): `class VCSnDict: UIHostingController<SnDictView>` with `init(dtext:addr:vers:)` (the old `setInitData(_:_:_:)` is gone); `@Observable final class SnDictModel` (`dtext`, `action`, `addr`, `vers`, `dtexts`, `generation`, `isLoading`, `key`, `isSwitchable`, `actionName`, `hasPrev`, `goNext/goPrev/setAction/reload`; `@ObservationIgnored requestId` stale-response guard so fast prev/next or segment switching only applies the latest response); `struct SnDictView`.
- `Read/SnDTextClickFlow.swift`: builds `VCSnDict(...)` directly. `VCEasyFunctions.swift`: removed `gVCSnDict()`.
- `Base.lproj/Main.storyboard`: removed the VCSnDict scene (`uJK-lM-uYq`, view controller `ZOk-eZ-pSw`) and its orphan Navigation Controller scene (`ij2-v0-SSP`); 16 -> 14 scenes (xmllint OK, no dangling ids). Removed the dead `0vP-iP-wrq.title` entries from `zh-Hans/zh-Hant Main.strings`.
- `FHLTools/SNDict/VCSnDictMore.swift` is now a 2-line comment stub. It is still referenced by `project.pbxproj` (groups are not synchronized folders) and the rules forbid hand-editing pbxproj, so it can be removed from the project in Xcode later (same trick as `_EmptyFileA.swift`).
- `zh-Hans.lproj/Localizable.strings`: new keys 上一字, 下一字, 字典, 原文字典, 浸宣字典, cbol字典 (identity values; Traditional falls back to the key). `彙編` and `取得資料中...` already existed.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination generic/platform=iOS Simulator`: BUILD SUCCEEDED.
- Ran on the iPhone 13 mini (iOS 27.0) simulator with FHL和合本 (the translation that carries SNs): 創 2 -> SN toggle -> tap `<H430>` -> action picker -> 浸宣 -> screen `H430` shows the 浸宣 entry with Hebrew text; switching to CBOL showed the loading spinner then content; next arrow -> `H431` (CBOL entry "'aluw"); magnifier -> pushed the search-result screen ("搜尋中..."). Simulator trap again: tool coordinate space is 360x780 but taps land correctly only when scaled to 375x812 pt (screenshot px / 923 * 375), and screenshots lag one frame behind taps, so take a second screenshot before concluding a tap did nothing.
- NOT verified: prev arrow and the disabled-at-1 state, swipe gestures, taps on refs / SNs inside the entry, GB (simplified) strings, CBOL-offline-database path, `.cbole` / `.dict` caption variant (not reachable from the picker), iOS 17.4 runtime, dark mode, Dynamic Type, iPad. No unit tests.

## Gotchas
- `SnDictDataQ.main` resets its converters and mutates `_dtext`'s action logic from `snAction`, so the query DText must have `snAction` set; the model keeps `action` as its own observable property because `DText` is a reference type and mutating `dtext.snAction` would not notify SwiftUI.
- A hosting controller has `storyboard == nil`; `gVCRead()` / `gVCSearchResult()` fall back to the navigation controller's storyboard / Main (see 1021t).
- Localizable keys are the literal Chinese source strings (see 1021v).

## Open issues / next steps
- `VCSnActionPicker` and `VCParsing` (Parsing screen) are still UIKit/storyboard.
- Remove `VCSnDictMore.swift` from the Xcode project (needs Xcode, not done here).
- `VCIndex` labelVer/labelDate still show 4.11.1 (release notes sections exist up to 4.12.15).
