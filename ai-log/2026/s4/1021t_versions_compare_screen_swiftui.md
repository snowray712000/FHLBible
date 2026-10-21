# 「譯本比較」(compare translations of one verse) rewritten in SwiftUI, renamed from 「版本比較」

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (SwiftUI rewrite + redesign + UI-term rename)
- Related logs: 1021o_tsk_screen_swiftui.md (same hosting pattern, `DTextContentView`), 1021s_audio_bible_screen_swiftui.md, 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none
- Commit: uncommitted
- Release notes: `## 4.12.10 (2026.10.21j)` in `Helps/app_versions.md`

## Goal / why
User asked to move the compare screen to SwiftUI (free to redesign if it is more iOS-guideline-like) and to stop calling it 「版本比較」: 「版本」 is confusing because it means the app version. UI term is now **「譯本」** everywhere (decision recorded in `FHLBible/CLAUDE.md`, "用詞"). Code identifiers (`vers`, `version=` API param, `ManagerBibleVersionsForCompare`, class name) are unchanged.

Entry point: Read -> tap a verse address on the left of a row -> action sheet (`VCVerseActionPicker`, first item) -> 「譯本比較」 -> `OneVerseFunctionsClickFlow._doWhenClickedVerseAddressCell` pushes `VCVersionsCompareInOneVerse(addr:)`.

## Old behavior (kept unless noted)
- Shows ONE verse in several translations. Title = address (`addr.toString(ManagerLangSet.s.curTpBookNameLang)`). Body was a `ViewDisplayTable2` (header row "版本", one row per translation: name + verse DTexts, per-translation font (`BibleVersionFonts.mainIsOpenHanBibleTCs`: ttvh/thv12h/ttvhl2021 use OpenHanBibleTC) and alignment (`getTpTextAlignmentsViaBibleVersions`: bhs right; kjv/esv/... left; else justified)). SN numbers hidden (`_isSn = false`).
- Translations chosen = `ManagerBibleVersionsForCompare.s.cur` (UserDefaults key `BibleVersionsForCompare`, default `["unv","esv","cbol"]`), independent from the reading translations. Changed by tapping the table header cell (col -1) -> pushes `VCVersionsPicker` with `isUpdateCurVersWhenOkay: false`; on OK the screen stores the new list via `updateCur` and re-queries.
- Data: `ReadDataQ().qDataForReadAsync(addrString, vers)` -> `qDataForRead$` gives `(header, [OneRow])`; the compare screen uses `.first.datas` = one `[DText]` per translation (when no translation has the verse, ReadDataQ returns one row of "(此譯本無)" DTexts).
- Taps on content: SN -> `SnDTextClickFlow`, `refDescription` -> `RefDTextClickFlow` (push VCRead), `foot` -> `FooterDTextClickFlow(vers: ManagerBibleVersions.s.cur).mainAsync(dtext, ver, addr)`.
- Prev/next verse: two bar buttons + one-finger swipe (right = previous, left = next) through `SwipeHelp`.

## What changed
- `VCVersionsCompareInOneVerse/VCVersionsCompareInOneVerse.swift` rewritten (file and class name kept because renaming needs a pbxproj edit, which is off limits):
  - `class VCVersionsCompareInOneVerse: UIHostingController<VersionsCompareView>`, `init(addr: DAddress)`; root view first built with no-op closures then replaced with `[weak self]` closures (same trick as `VCTsk`). Owns `SwipeHelp` exactly like VCTsk. `doWhenClicked(dtext, ver)` dispatches SN/ref/foot as before; `doPickVersions()` pushes `VCVersionsPicker`.
  - `@Observable VersionsCompareModel`: `addr`, `vers`, `rows: [VersionsCompareRow]` (id = index, ver, name = `BibleVersionConvertor().na2cna`, dtexts, isFontOpenHan, alignment), `isLoading`, `generation`, `requestId` (`@ObservationIgnored`, drops stale responses — the old code could draw an older response when switching fast; it guarded only by `vers.count != datas.count`). `reload()` clears rows, sets `isLoading`, runs `ReadDataQ`, applies on the main queue. `setVers` ignores an unchanged list, otherwise persists via `ManagerBibleVersionsForCompare.s.updateCur` then reloads. Rows are built by index with a "(此譯本無)" fallback if a translation's data is missing.
  - `VersionsCompareView`: `List` (`.insetGrouped`), one `Section` per translation (header = translation name, `.textCase(nil)`), content = `DTextContentView` (the `ViewDisplayCell` wrapper). Overlay: `ProgressView("取得資料中...")` while loading, `ContentUnavailableView` ("尚未選擇譯本" + 「選擇譯本」 button) when there are no rows. Toolbar: `.principal` two-line title (small 「譯本比較」 caption over the address), trailing group: 「選擇譯本」 (`books.vertical`), prev (`arrow.left`), next (`arrow.right`).
  - Redesign vs old: translation name is a section header instead of a table column; a visible 「選擇譯本」 button replaces the hidden "tap the 版本 header" gesture; loading and empty states; screen name shown in the title.
- `FHLTools/Tsk/VCTsk.swift`: `DTextContentView` got three defaulted properties — `isFontOpenHan: Bool?`, `alignment: NSTextAlignment`, `onTapAny: ((DText) -> Void)?`. With `onTapAny == nil` behavior is identical to before (only `refDescription` taps forwarded to `onTapRef`), so TskView is unchanged; with it set every tapped DText is forwarded.
- `VCEasyFunctions.swift`: `gEasyGetViewCtrlFromXibCore` now uses `self.storyboard ?? self.navigationController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)`. Needed because `SnDTextClickFlow`/`RefDTextClickFlow`/`FooterDTextClickFlow` and the picker call `gVCSnActionPicker()/gVCRead()/gVCFooter()/gVCVersionsPicker()` on the calling controller, which for a code-created hosting controller has `storyboard == nil` (would crash on `storyboard!`). `gVCVersionsCompareInOneVerse()` removed (only user was the click flow, which now calls the initializer).
- Rename 版本比較 -> 譯本比較: `VCVerseActionPicker` (title, subtitle 「此節，比較多個譯本」, enum comment), `VCReadMore` row title 「譯本比較 註釋 Parsing 串珠」, zh-Hans `Localizable.strings` keys renamed (+ new keys 「選擇譯本」「尚未選擇譯本」「上一節」「下一節」「(此譯本無)」). The help topic was already named 「譯本比較」 (VCHelps).
- `Main.storyboard`: removed scene `FhF-3Z-0od` (VCVersionsCompareInOneVerse + ViewDisplayTable2 + 2 bar buttons) and its orphan `Navigation Controller` scene `ce3-Gw-iqk` (only a relationship segue to it). 26 -> 24 scenes. Removed the dead `yyd-62-yyW.title` entries from zh-Hans/zh-Hant `Main.strings`. Verified: no remaining reference to the removed ids, XML parses, build passes.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination iPhone 13 mini (iOS 27.0 simulator, target 17.0)`: BUILD SUCCEEDED, no errors. FHLBibleTW/FHLCommon not rebuilt (untouched; only FHLBible files changed).
- Ran in the simulator: 閱讀 -> tap 詩 5:2 address -> sheet shows 「譯本比較 / 此節，比較多個譯本」 -> screen shows FHL 和合本 / ESV / 原文直譯 sections with title 「譯本比較 詩 5:2」; next arrow twice -> 詩 5:4 (with the loading overlay in between); 「選擇譯本」 pushes the existing picker, deselect one + select another + OK -> the list reloaded with the new translation and was persisted.
- NOT verified: swipe left/right on this screen, prev arrow alone, tapping SN/reference/footnote inside the compare text (SN is hidden here; reference/footnote need a translation that has them, e.g. cnet/csb footnotes), OpenHan font translations (ttvh…), Hebrew right alignment (bhs), the empty-selection state, GB (簡體) strings, iOS 17.4 runtime, dark mode, Dynamic Type, iPad, unit tests.

## Gotchas
- A code-created controller has `storyboard == nil`; every `g…()` helper in `VCEasyFunctions.swift` crashed from one before this change; now it falls back to the Main storyboard.
- Simulator screenshots through the control tool sometimes lag one tap behind; take a second screenshot before concluding a tap failed.
- `ViewDisplayCell` has generous built-in padding, so each section card looks taller than its text; left as is (cell not modified).
- The picker's `viewDidDisappear` auto-confirms ("Back" == OK), so going back from the picker also calls `onClickOkay$` — `setVers` ignoring an unchanged list avoids a pointless reload.

## Open issues / next steps
- Class/file name still contains "VersionsCompare"; rename (and `VCVersionsPicker`, which is the 「譯本選擇」 screen) needs a pbxproj change — ask the user first.
- Arrows are never disabled at the ends of the Bible (same as old).
- `VCVersionInfo` release notes show the last release (4.11.1) on the home screen; unchanged policy.
