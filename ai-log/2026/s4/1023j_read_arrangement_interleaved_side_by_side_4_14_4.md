# Feature: Read screen arrangement switch (interleaved / side-by-side) + adjustable column widths (4.14.4)

- Date: 2026-10-23
- Project: FHLBible
- Type: feature
- Related logs: 2026/s4/1021w_read_screen_swiftui.md, 2026/s4/1022b_search_screens_swiftui.md, 2026/s4/1023g_fix_read_composite_verses_narrow_width_4_14_1.md
- Cross-project: none (FHLCommon untouched). Reference design: FHLNUI at /Users/snow/coding/FHLNUI (web), `docs/z260930d(經文區table化-考量與CSS Grid規畫).md`, `index/ColWidth.es2023.js`, `index/VerseGrid.es2023.js`, `index/Show_mode.es2023.js`
- Commit: uncommitted

## Goal / why
Maintainer's direction (very abstract, "see FHLNUI"): the Read screen shows several translations only "interleaved" (per verse, translations stacked). The roadmap is: switchable 「交錯」/「併排」(side-by-side), adjustable column widths (drag; long-press = auto width), and later 「分段」 (paragraph grouping). Scope agreed for 4.14.4: arrangement switch + adjustable widths. 分段 is only left as an extension point (see "Not done").

## FHLNUI model that was mirrored (so a future AI does not have to re-read it)
- `ps.show_mode` 1..4 = {verse, paragraph} x {side-by-side, interleaved}; two independent axes. iOS now has the "arrangement" axis only (`ReadArrangement`); paragraph grouping must become a second enum, not a third case.
- Side-by-side: header row with translation names + shared column widths; rows align by verse (CSS grid there, one `HStack` per List row here). Auto width = measured text length per translation, clamped to 0.6–1.8x of the mean; custom width = drag the divider between header cells, stored **per translation combination** (key = sorted codes joined by ","), double-click (touch: long-press 600 ms) on a divider returns to auto. Merged-verse (`bible_text == "a"`) rowspan and paragraph data (`paragraphs_ncv/csb/rcuv.json.gz`) exist there; neither is in iOS.

## Behavior
- 「⋯」 menu (Read) gets an inline `Picker` 「經文排列」: 交錯 / 並排, plus 「自動欄寬」 (only when side-by-side and a custom width exists). Disabled with <2 translations (one translation is always rendered "interleaved" = no header). Setting stored in UserDefaults `ReadArrangement` (Int 0 interleaved, 1 side-by-side); **key absent = never chosen → iPhone interleaved, iPad (regular size class) side-by-side**. (Before this, iPad showed per-verse side-by-side without header; that code path is gone, replaced by the new side-by-side.)
- Interleaved: unchanged (verse number button left, translations stacked with a small caption).
- Side-by-side: top header (translation names, tap = translation picker, same as the bottom bar button) + one column per translation; verse-number column of fixed width on the left (34 pt when the whole page is one chapter, else 84 pt for full addresses such as 羅1:2), thin vertical separators between columns, tallest cell sets the row height. All cell features (taps on SN/ref/footnote, long-press to select, multi-select overlay) are the same `cellView`; only the caption is dropped.
- Column widths: `ReadColumnsLayout` (pure struct). `avail` = view width − 2×12 (row insets) − label width − 8 gap. If `avail >= n × 130` (min column) the columns fill the view, widths proportional to weights; a column that would be narrower than 130 is pinned to 130 and the rest are shrunk proportionally (`distribute`, iterative). Otherwise (phone with 3+ translations) total = `n × 160` and the content is wider than the screen → horizontal scroll (header scrolls with it). Total width depends only on n, so dragging a divider (which keeps the pair's sum) never changes the total.
- Weights priority: `dragWeights` (live while dragging) > `customWeights` (saved) > `autoWeights`. Auto: for each translation, sum over all verses of `NSAttributedString.size().width` of the real attributed string from `DTextDrawToAttributeString(isSnVisible, isFontOpenHan).mainConvertWithSource` (so SN on/off and fonts are counted; recomputed in `setRows` and in `toggleSn`), divided by the mean, clamped 0.6–1.8. Main thread, cheap for a chapter (not measured for Ps 119).
- Divider handle (`ReadColumnHandle`, header only, 28x32 pt hit area, a 3x18 capsule at the column's trailing edge; tint when a custom width exists): `DragGesture(minimumDistance: 2)` changes only the two adjacent columns in pixels (min 130 each), `dragWeights = px`; on end `commitWidths(px)` saves weights normalised to mean 1 (so it works on any screen width). `LongPressGesture(0.6 s, maxDistance 8)` simultaneously → `resetWidths()` (deletes the saved entry) + haptic. After a long press the drag's `onEnded` must not re-save: `resetWidths` clears `dragWeights` and `onEnded` only commits when `dragWeights != nil`.
- UserDefaults `ReadColumnWeights`: `{ "<sorted,codes>": { "<code>": weight } }`, weights rounded to 3 decimals, loaded in `setRows` for the current `vers`.
- Swipe guard: the page-level `SwipeHelp` one-finger left/right swipe (next/prev chapter) is ignored while the content is horizontally scrollable (`model.isHScrollable`, reported by the view with `.onChange(of: scrolls, initial: true)`); two/three-finger swipes and the bottom prev/next buttons still work.

## Implementation (all in `Read/VCRead.swift` + 1 key file; no pbxproj edit — new files in `Read/` would need adding in Xcode, so everything stays in this file; the types are self-contained and can be split out / reused by `VCSearchResult` later)
- `Common/Managers/FHLUserDefaults.swift`: keys `ReadArrangement`, `ReadColumnWeights`.
- `VCRead.swift`: `enum ReadArrangement` (+ `loadSaved/save`), `enum ReadColumnWeightsStore`, `struct ReadColumnsLayout`, `ReadModel` additions (`arrangementSetting`, `labelWidth`, `dragWeights/customWeights/autoWeights`, `weights`, `arrangement(isRegular:)`, `setArrangement`, `commitWidths`, `resetWidths`, `updateAutoWeights`, `isHScrollable`), `ReadView` (`GeometryReader` → `ScrollView(.horizontal)` containing `VStack { ReadColumnHeader (side only); List }.frame(width:height:)`), `ReadColumnHeader`, `ReadColumnHandle`, `ReadRowView(layout:)` (nil layout = interleaved).
- The horizontal `ScrollView` wrapper is used in **both** arrangements (content width = view width when interleaved, `.scrollBounceBehavior(.basedOnSize, axes: .horizontal)`), so toggling arrangement keeps the same `List` and its scroll position (verified: toggled back at ~verse 4, no jump to top). The List needs an explicit height because it sits inside a ScrollView (`size.height` from the `GeometryReader`).
- `zh-Hans.lproj/Localizable.strings`: 經文排列 / 交錯 / 並排 / 自動欄寬 / 調整欄寬 / 拖曳調整，長按回到自動欄寬. `Helps/app_versions.md`: `## 4.14.4 (2026.10.23g)` (detail version, hidden by default; roll into 4.15.1; there is no 4.14.3 entry). `VCIndex.labelVer` not bumped.
- Not changed: `ReadSnapshotRenderer` (圖片產生 is still the stacked layout regardless of arrangement), selection/`makeSelections`, Search results (`SearchRowView` still has its own `isWide` HStack), 譯本比較.

## Decisions / rejected
- Per-row `HStack` with explicit `.frame(width:)` computed from one shared `ReadColumnsLayout` instead of a custom SwiftUI `Layout` or `Grid`: `List` rows are independent, the width is known from the `GeometryReader`, and `DTextContentView.sizeThatFits` already depends on the proposed width. A custom `Layout` was considered first and dropped (zero/infinite width probes for `UIViewRepresentable`).
- Phone with many translations: scroll horizontally (user's choice) rather than force 2 columns or fall back to interleaved. First attempt kept the auto ratio (0.6–1.8) with min 120 and made the first column fill the whole screen with the others off-screen; replaced by "average column 160, min 130, redistribute".
- Auto width measured from real attributed strings rather than character counts (same reason as FHLNUI: CJK/Latin/Hebrew widths differ, hidden SN must not count).
- Weights are saved as ratios, not points, so they survive device/orientation changes.

## Gotchas
- Simulator tool: screenshot taken right after a tap/swipe often shows the previous state; sleep 3–5 s. Taps are in 375x812 pt for the iPhone 13 mini (multiply 923-px-wide screenshot coordinates by 0.406). A blind second tap earlier landed on the next screen and an SN word.
- Writing `defaults write IJN.FHLBible BibleVersions ...` through `simctl spawn` did not change the app's translations (the storage is not that plain key); use the in-app 譯本選擇 instead.
- `ReadColumnsLayout` must not set `labelWidth` twice in `init` (`let`).

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible`: BUILD SUCCEEDED for iPhone 13 mini (iOS 27.0) and for iPhone 15 Pro (iOS 17.4, compile only; not run).
- Ran on iPhone 13 mini, iOS 27.0, 太 1 with 和合本(SN on) + 中文標準譯本, then + NET聖經中譯本: menu shows 交錯 ✓ / 並排; switching to 並排 → header + two aligned columns, separators, SN tap opens the SN action picker; drag divider moves it (handle turns tint), long press resets to auto; with 3 translations the content scrolls horizontally with the header, vertical scroll works, one-finger swipe does not change chapter; switching back to 交錯 keeps scroll position and restores the old layout; the side-by-side choice persisted across relaunch.
- NOT verified: iPad (regular size class default = side-by-side), iOS 17.4 runtime, dark mode, Dynamic Type at large sizes, multi-select in side-by-side, ref/footnote taps in side-by-side, Hebrew (RTL alignment per column), very long chapters (Ps 119) performance of `updateAutoWeights`, whether a saved custom width survives relaunch (code path read, not exercised), VoiceOver, `ReadSnapshotRenderer` unchanged.

## Not done / next steps
- 分段 (paragraph grouping): needs FHLNUI's `paragraphs_ncv/csb/rcuv.json.gz` ported (`[[book, chap, startVerse, title], …]`), a `ReadGrouping` axis (verse | paragraph), rows = paragraphs, one cell per translation, titles, and merged-verse handling before grouping (FHLNUI `docs/z260930d` section 三 "段落").
- Merged verses (`bible_text == "a"`, e.g. 和合本 西 2:21 into 20): FHLNUI uses rowspan; iOS Read has no special handling in either arrangement.
- Share `ReadColumnsLayout` / header / handle with Search results and 譯本比較 (FHLNUI shares one core across reading, cross-reference dialog and search; widths record is shared there). Would need the types moved to their own file (add in Xcode) or FHLCommon.
- Image generation could follow the arrangement.
