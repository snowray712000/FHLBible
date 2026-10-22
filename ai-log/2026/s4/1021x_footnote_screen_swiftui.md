# Footnote screen ("注腳") rewritten in SwiftUI; removed from Main.storyboard

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change with small UX improvements)
- Related logs: 1021v_comment_screen_swiftui.md (same structure: hosting controller + `@Observable` model + `DTextContentView` + `SwipeHelp`), 1021w_read_screen_swiftui.md (Read opens this screen)
- Cross-project: none (FHLCommon's `fhlRt`, `cvtFooter`, `DFoot` are only used, not changed)
- Commit: not committed (working tree also holds earlier uncommitted SwiftUI migrations).
- Release notes: `Helps/app_versions.md` section `## 4.12.14 (2026.10.21n)`.

## Goal / why
Next screen of the UIKit -> SwiftUI migration. A "footnote" is the blue 【23】 marker that some translations put inside verse text: `cnet` (NET聖經中譯本), `csb` (中文標準譯本), `lcc` (呂振中譯本). Tapping it opens this screen with the footnote body. Maintainer's usual test translations: 呂振中譯本, 中文標準譯本, NET聖經中譯本.

## Data format / API
- `DText.foot: DFoot` is created by FHLCommon `SSFoot` for text matching `【(\d+)】`: `DFoot(text: "【180】", book, chap, verse, version, id: 180)`. (Another DFoot shape `{text: "…"}` with no id exists in test data only; this screen requires `foot.id`, falling back to id 1.)
- Footnote ids are numbered PER CHAPTER and per translation, starting at 1.
- Body API (`fhlRt` in FHLCommon): `POST https://bible.fhl.net/json/rt.php` body `engs=<Matt-style English abbrev>&chap=<n>&version=<cnet|csb|lcc>&id=<n>&<ManagerLangSet.s.curQueryParamGb>`. Success: `{status:"success", record_count:1, record:[{id, text}]}`. A NONEXISTENT id (0, or past the last footnote) returns `{status:"success", record_count:0, version, engs}` with NO `record` key, so `DApiRt` JSON decoding throws and `FhlJson` turns it into `DApiRt("exception: …")` (`isSuccess() == false`). An empty `record` array would also be possible; both are treated as "not found".
- `cvtFooter(text, addr, ver)` (FHLCommon, public) converts the raw text to `[DText]`: parentheses, 「」 quotation containers, and for cnet/lcc/csb cross-reference detection (`第2節`, `參約1:3`, `《彌迦書》5:2`) so refs become blue tappable `refDescription`s. Raw API text sometimes contains odd characters (e.g. cnet Gen 1 id 2 starts with `「2「神」。אֱלֹהִים」`); that is source data, not a rendering bug.

## Behavior
- Entry: `FooterDTextClickFlow.mainAsync(dtext, ver, addr)` (called by `VCRead.doWhenContentClicked`, `VCVersionsCompareInOneVerse`, `VCSearchResult`) now does `push(VCFooter(dtext:ver:addr:vers:))`. `ver` is the translation of the tapped column, `addr` the verse, `vers` the reading translations (used when a cross-reference is tapped).
- Screen: inline nav title `注腳 【n】`; a secondary line `<譯本中文名> · <出處>` (name from `BibleVersionConvertor().na2cna(ver)`; place = full `DAddress.toString` e.g. 「創 1:1」 only while showing the tapped id, otherwise just book + chapter e.g. 「創 1」 because the verse of other footnotes is unknown); body in a `ScrollView` via `DTextContentView` (left aligned, `isVisibleSn: true`).
- Navigation: toolbar `arrow.left` / `arrow.right` (prev = id-1, next = id+1) plus one-finger swipe right/left via `SwipeHelp` (also disables the system back swipe). Prev is disabled at id <= 1. When a next/prev request finds nothing, the screen stays on the current footnote and that direction's button is disabled (`isNextUnavailable` / `isPrevUnavailable`) until another footnote loads successfully. Old behavior: popped the whole screen on any failure.
- States: `loading` (ProgressView "取得資料中...", only when there is no content yet), `loaded`, `failed` (first load failed: `ContentUnavailableView` with a 重試 button; old behavior: silent pop).
- Tapping a cross-reference in the body: `StringToVerseRange().main(ref, (book, chap))` -> push `VCRead` with `setInitData(VerseRange(r1), vers)`.

## What changed
- `Read/Footer/VCFooter.swift` rewritten (file name kept to avoid touching pbxproj): `class VCFooter: UIHostingController<FootnoteView>` with `init(dtext:ver:addr:vers:)`; `@Observable final class FootnoteModel` (`id`, `ver`, `addr`, `vers`, `dtexts`, `generation`, `phase`, `isNextUnavailable/isPrevUnavailable`, `goNext/goPrev/reload`, `@ObservationIgnored requestId` stale-response guard so rapid next taps only apply the latest response; network callback hops to main); `struct FootnoteView`.
- `Read/FooterDTextClickFlow.swift`: builds `VCFooter(...)` directly. `VCEasyFunctions.swift`: removed `gVCFooter()`.
- `Base.lproj/Main.storyboard`: removed the `VCFooter` scene (`hgJ-CZ-Y9n`) and its orphan `Navigation Controller` scene (`Lex-jV-yuC`); 18 -> 16 scenes (parsed OK, no dangling ids `VLI-CS-UCN` / `El4-jf-gkn`). Removed the dead `ejc-Si-cJq.title` entries from `zh-Hans/zh-Hant Main.strings`.
- `zh-Hans.lproj/Localizable.strings`: new keys 注腳 (注脚), 上一則注腳, 下一則注腳, 無法取得注腳, 請確認網路連線後再試一次, 重試 (Traditional falls back to the key itself).
- Accessibility: arrow buttons are `Label(…, systemImage:)` so VoiceOver reads 「上一則注腳／下一則注腳」.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination generic/platform=iOS Simulator`: BUILD SUCCEEDED (twice, last after the final padding tweak).
- Ran on the iPhone 13 mini (iOS 27.0) simulator with 呂振中譯本 + 中文標準譯本 + NET聖經中譯本 selected: 創 1 -> tap NET 【1】 -> screen 「注腳【1】」 with 「NET 聖經中譯本 · 創 1:1」, prev disabled; next -> 「注腳【2】」 with 「創 1」; prev -> back to 【1】; tapping the blue 「第 2 節」 ref pushed VCRead at 創 1:2. API probe for id 0 / 9999 confirmed the not-found response above.
- Simulator trap again: the tool reports the 13 mini coordinate space as 360x780 but taps only land correctly when scaled to 375x812 pt (screenshot px / 923 * 375). The iPhone 15 Pro (iOS 17.4) simulator did not react to injected taps at all in this session, so iOS 17.4 was compiled but not exercised.
- NOT verified: `csb` and `lcc` footnotes on screen (same code path; only cnet was opened), the not-found / failed (offline) states on screen, swipe gestures, GB (simplified) strings, iOS 17.4 runtime, dark mode, Dynamic Type, iPad. The 13pt header padding (aligns with the text view's inner inset) was only build-checked. No unit tests.

## Gotchas
- Footnote ids are per chapter: the screen only knows the verse for the footnote that was tapped, so the place line degrades to the chapter after prev/next.
- A hosting controller has `storyboard == nil`; `gVCRead()` falls back to `navigationController?.storyboard`/Main (see 1021t).
- Localizable keys are the literal Chinese source strings (see 1021v).

## Open issues / next steps
- `VCIndex` labelVer/labelDate still show 4.11.1 (release notes sections exist up to 4.12.14).
- Possible follow-up: upper bound of footnote ids is unknown until a request fails; a "n of N" counter would need an API that returns the count.
