# Parsing screen (original-language word analysis) rewritten in SwiftUI; removed from Main.storyboard

- Date: 2026-10-22
- Project: FHLBible
- Type: refactor (UI technology change with UX redesign)
- Related logs: 1021y_sn_dict_screen_swiftui.md (hosting controller + `@Observable` model + stale-response guard + scene-removal procedure), 1021u_book_chap_picker_screen_swiftui.md (the title opens this picker), 1022b_search_screens_swiftui.md (address dialog opens Parsing)
- Cross-project: none (FHLCommon only used: `DText`, `DApiQpRecord`, `SnDTextClickFlow` deps, `BibleBookNames`)
- Commit: not committed.
- Release notes: `Helps/app_versions.md` section `## 4.12.18 (2026.10.22c)`.

## Goal / why
Next screen of the UIKit -> SwiftUI migration. "Parsing" shows, for one verse, the original text (Greek NT / Hebrew OT), the Chinese gloss line, and a word-by-word analysis list (Strong's number, word, lemma, short meaning, grammar, remark). It opens from the verse-number dialog (譯本比較 / Parsing / 註釋 / 串珠) in Read and in search results, and from the SN action picker (彙編 / Parsing / CBOL / 浸宣).

## Behavior (new)
- Entry: `VCParsing(addr:vers:)` (a `UIHostingController<ParsingView>`) pushed by `VCRead`, `VCSearchResult`, `OneVerseFunctionsClickFlow` (`.InfoParsing`) and `SnDTextClickFlow._doWhenUsingParsing`. `gVCParsing()` and `set(_:_:)` no longer exist. `vers` is only kept to hand to `SnDTextClickFlow` when an SN button is tapped.
- Nav bar: principal = tappable title `羅1:1 ⌄` (same look as Read) -> pushes `BookChapPickerViewController(book:chap:)`, a pick loads `verse 1` of that chapter; trailing = prev / next verse arrows (icon-only labels 上一節 / 下一節).
- Prev/next: **computed locally** with `DAddress.goPrevVerse()/goNextVerse()` (`Common/Address/NextPrevVerse.swift`, wraps Rev 22 -> Gen 1:1 like 譯本比較), always enabled. The old code used the `prev`/`next` of the qp response (kept in `DReloadData`, now ignored).
- Body (`List`, `.insetGrouped`): one `Section` per clause (a clause = one `\n`-separated line of `record[0].word`). Row 1 of a section: original text line + Chinese line (both via `DTextContentView`, because the original may contain DText styling such as `(韋:…)(聯:…)` variant markers); for Hebrew both lines are right-aligned (as before). Then one row per word: SN capsule button (bordered, small) + word (headline) on the first line, then `原型 / 簡義 / 分析 / 備註` rows (label column width is a `@ScaledMetric`, content is native `Text` with `.textSelection(.enabled)`; empty fields are hidden — before, only 備註 was hidden when empty). Content of 簡義/分析/備註 is plain strings (`DText(String)`), so native `Text` is used instead of `ViewDisplayCell`; `分析` = `pro` + `wform` concatenated with no separator (same as the old single text view).
- Tapping the SN capsule -> `SnDTextClickFlow(vc:addr:vers:).mainAsync(snDText)` -> SN action picker (unchanged). Note: the picker's own "Parsing" option pushes another Parsing screen for the same verse (pre-existing quirk, left alone).
- States: `.loading` (`ProgressView("取得資料中...")`), `.loaded`, `.failed` (`ContentUnavailableView` 「沒有 Parsing 資料」 + 重試). Old code showed a blank screen on failure and crashed (`pData!.data!`) when the API returned zero records.
- **Swipe gesture dropped on purpose.** The old screen installed `SwipeHelp` left/right with *no-op* handlers (260413h: users with large fonts scrolled sideways and accidentally changed verse). A side effect was that the system back-swipe was disabled (SwipeHelp does that). The new layout wraps text and never scrolls horizontally, so no interception is needed and the system right-swipe-to-go-back works again.
- **SN number display fix.** The offline DB (`parsing.db`) stores `sn` with leading zeros (`02532`); the old UI showed `G02532` and handed `02532` to the dictionary (title `G02532`). `ConvertorQp2VCParsingData` now strips leading zeros (`trimLeadingZeros`, keeps one `0` for an all-zero value) in both OT and NT branches, so the button shows `G2532` and the dictionary / 彙編 receive `2532`. Verified: dictionary screen for the pill opened and loaded CBOL content (screenshot taken before the fix showed `G02532` title and still loaded; after the fix the pill shows `G2532`; dictionary after the fix not re-opened).

## Data / threading (unchanged core)
- Source selection: `VCParsing.ReloadDataAutoUseOfflineOrScApi` (extension in `VCParsingIReloadData*.swift`): offline `Documents/offline/parsing.db` (`parsing_gb.db` for GB) when the file exists (tables `lparsing2` for book < 40 else `fhlwhparsing2`; query `WHERE book/chap/sec ORDER BY wid`), else `qp.php` API. Both produce `DReloadData` -> `ConvertorQp2VCParsingData(data).main()` -> `(clauses: [ParsingClause], isHebrew: Bool)`.
- `ParsingModel.reload()`: `requestId += 1`, phase = loading, callback (background thread) converts, then `DispatchQueue.main.async` applies only if `requestId` still matches (fast prev/next drops stale answers). `generation` increments per successful load so `DTextContentView` redraws only on new data. Errors are logged through `Logger(subsystem: "com.FHLBible", category: "VCParsing")`.
- New data types live at the top of `ConvertorQp2VCParsingData.swift`: `final class ParsingWord: Identifiable` (sn, word, orig, wform, exp, remark; replaces `ViewParsingDict.OneData`) and `struct ParsingClause: Identifiable` (w, cht, words; replaces the `ViewParsing.OneSet` tuple). The converter's algorithm (clause splitting by `\n`, `countSpaceAndDash`, OT reversed order, variant markers) is untouched — see the legacy docs `doc/260413b_parsing_format_for_ai.md` / `260413c_parsing_format.md`.

## What changed
- `FHLTools/SNParsing/VCParsing.swift` rewritten: `VCParsing`, `ParsingView`, private `ParsingClauseRow` / `ParsingWordRow`, `@Observable ParsingModel`.
- `FHLTools/SNParsing/ConvertorQp2VCParsingData.swift`: new types, retyped output, `trimLeadingZeros`.
- `ViewParsing.swift`, `ViewParsingWord.swift`, `ViewParsingDict.swift`, `ViewSNDictCell.swift` are now comment-only stubs (they are listed in `project.pbxproj`; rules forbid hand-editing it). Their four xibs (`ViewParsing.xib`, `ViewParsingWord.xib`, `ViewParsingDict.xib`, `ViewSNDictCell.xib`) are orphans. **Remove the 4 swift stubs and 4 xibs in Xcode** (also drops two `@IBDesignable` classes, which may help Interface Builder speed).
- Call sites: `Read/OneVerseFunctionsClickFlow.swift`, `Read/SnDTextClickFlow.swift`, `Read/VCRead.swift`, `Search/VCSearchResult.swift` build `VCParsing(addr:vers:)`; `VCEasyFunctions.swift` lost `gVCParsing()`.
- `Base.lproj/Main.storyboard`: removed the VCParsing scene (`2oP-Wd-Wep`, controller `Ang-Mk-Vo7`) and its orphan Navigation Controller scene (`T6k-QO-3P0`); 10 -> 8 scenes (xmllint OK, no dangling ids). Removed the now-dead `FhJ-Ph-xk7.normalTitle` entries from `zh-Hans/zh-Hant Main.strings`.
- `zh-Hans.lproj/Localizable.strings`: 沒有 Parsing 資料, the empty-state sentence, 原型, 簡義 (简义), 分析, 備註 (备注). Traditional falls back to the key. (`上一節 下一節 聖經目錄 重試 取得資料中...` already existed.)
- `Helps/app_versions.md`: new section 4.12.18.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'generic/platform=iOS Simulator' build`: BUILD SUCCEEDED (deployment target 17.0, so 17.0 APIs only; `ContentUnavailableView`, `@Observable`, `.textSelection` are iOS 17).
- Ran on the iPhone 13 mini (iOS 27.0) simulator with the offline DB present: 徒 28:1 (Greek, three clauses, variant marker `(韋:…)(聯:…)` rendered), tapped SN pill -> action picker -> CBOL -> dictionary loaded; title -> book picker -> 創 21 -> Parsing for 創 21:1 (Hebrew, right-aligned lines, long 分析/備註 wrapping, Hebrew in native `Text` renders fine); next arrow -> loading spinner then 創 21:2.
- NOT verified: failure/empty state and retry (needs the offline DB removed and no network), the online qp API path (only the offline DB was used), GB (simplified) strings, dark mode, Dynamic Type at accessibility sizes, iPad, VoiceOver, the system back-swipe, prev arrow, iOS 17.4 runtime (compiled only), unit tests (not run; no test references the removed types).
- Simulator tool: screenshots lag one frame behind taps (take two); a popover/sheet that is still animating swallows the next tap (e.g. a tap meant for the book chapter grid landed on 創 21 because of the sheet's rising animation — wait one more screenshot before tapping inside sheets). Tap coordinates for the iPhone 13 mini: screenshot px * 0.406.

## Gotchas
- `UITextView` (inside `DTextContentView`) has a 5 pt `lineFragmentPadding` on each side, so the clause lines are given `.padding(.horizontal, -5)` to align with the word cards.
- Putting a `DTextContentView` in an `HStack(alignment: .firstTextBaseline)` next to a label misaligns it (baseline of an `UIViewRepresentable`); this is why 簡義/分析/備註 are native `Text`.
- The generic `VCParsing.IReloadData`, `DReloadData`, `ReloadDataVia*` nested classes are extensions of `VCParsing` in `VCParsingIReloadData*.swift`; keeping the class name `VCParsing` for the hosting controller preserves them.

## Open issues / next steps
- Remove the 4 stub swift files + 4 xibs from the Xcode project.
- Consider hardening `ConvertorQp2VCParsingData` (force unwraps of `sn!`, `wform!`, `remark!`, `assert` on mismatched `\n` counts) — a NULL column in the offline DB would still crash.
- Consider hiding the "Parsing" option in the SN picker when already inside Parsing.
