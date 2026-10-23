# Feature: Read screen paragraph grouping (單節 / 段落) + merged-verse ("併入上節") handling (4.14.5)

- Date: 2026-10-23
- Project: FHLBible
- Type: feature
- Related logs: 2026/s4/1023j_read_arrangement_interleaved_side_by_side_4_14_4.md (arrangement axis; this adds the second axis), 2026/s4/1021w_read_screen_swiftui.md
- Cross-project: none (FHLCommon untouched). Reference: FHLNUI `docs/z260930d(經文區table化-考量與CSS Grid規畫).md` section 三/四, `index/grouping_by_paragraph.js`, `index/lecture/FhlLecture_render_core.js` `build_view_model`, `index/ParagraphData_es2023.js`, `index/Show_mode.es2023.js`
- Commit: uncommitted at the time of writing

## Goal / why
Roadmap item from the maintainer: Read gets 「分段」 in addition to 交錯/並排 (done in 4.14.4). In FHLNUI `show_mode` is 1..4 = {單節, 段落} x {併排, 交錯}; iOS now has the same two independent axes (`ReadGrouping` x `ReadArrangement`). Merged verses had to be handled in the same step because FHLNUI says it must happen before grouping (a merged verse can sit in a different paragraph than the verse it is merged into).

## Behavior
- 「⋯」 menu: second inline `Picker` 「分段」 (單節 / 段落), below the arrangement picker. Disabled unless `canGroup` = paragraph data available (app resource present) AND the page is a single chapter (`isSingleChap`: all rows same book+chapter; composite reads such as 串珠 `出18:10;創9:26` never group) AND there are verses. Stored in UserDefaults `ReadGrouping` (Int 0 verse default, 1 paragraph). `isGroupedByParagraph = setting == .paragraph && canGroup`; when it can't group the screen silently shows 單節 (the menu shows 單節 checked).
- 單節 = unchanged (one row per verse, verse-number button column on the left; merged verses still show the "(併入上節)" placeholder in their own row — a List row cannot span rows like FHLNUI's grid rowspan).
- 段落: one row per paragraph. No verse-number column (`labelWidth = 0`, gap 0, so the text gets the full width); the paragraph title (small semibold, wraps at the screen width even when side-by-side content is wider/scrolling) sits above the row; each translation's cell = for every verse in the paragraph `number + content` concatenated; the number is a blue `DText("20 ")` (blue because `refDescription` is set; the tap is intercepted). Tapping a number → `confirmationDialog` for that verse (譯本比較 / Parsing / 註釋 / 串珠; title = `VerseRangeToString` of that verse). Works in both arrangements (interleaved: each translation = caption + paragraph text; side-by-side: header + columns, row height = tallest paragraph).
- Paragraph source: ONE list for all translations (FHLNUI does the same: it loads only `paragraphs_ncv.json.gz`, "ncv 新譯本"). Title text comes from it (Traditional; converted with `StringTransform("Hant-Hans")` when `ManagerLangSet.s.curIsGb`).
- Merged verse handling (paragraph mode only): per translation, a verse whose cell text is "(併入上節)" is not emitted; the previous real verse's number DText is mutated to `"<first>-<this> "` (e.g. 西2:20 + 21 → "20-21", and "20-22" if 21 and 22 both merged — loop keeps `lastFirstVerse`). The previous verse may be in an earlier paragraph; this works because the number is an object mutated before the rows are used. If a translation's cell for a whole paragraph is empty because everything was merged, the cell stays empty (interleaved skips that translation's block); if it is empty because the translation lacks the verses, it shows "(此譯本無)".
- Row selection/copy: `ReadRow.address` of a paragraph row is the range string (`創1:1-2`), `makeSelections()` parses it like before; cells contain the number DTexts. 圖片產生 (`ReadSnapshotRenderer`) prints the title above the address label.

## Data format / resource
- `FHLBible/FHLBible/Read/paragraphs_ncv.json` (143,556 bytes) = FHLNUI `index/paragraphs_ncv.json.gz` decompressed: `{"paragraphs":[[book,chap,sec,"title"], ...]}`, 3381 entries, book 1..66, sorted ascending by (book, chap, sec), all start keys unique (checked). Each entry is the start of a paragraph; it lasts until the next entry. FHLNUI also has `paragraphs_csb` (1007) and `paragraphs_rcuv` (1468) but uses only ncv; they were not copied.
- `ReadParagraphData.s` (singleton, loads `Bundle.main.url(forResource: "paragraphs_ncv", withExtension: "json")` once on first use, `JSONSerialization`): `starts` = `book*1_000_000 + chap*1_000 + sec` per entry, `titles`; `index(book,chap,sec)` = binary search for the last start <= hash, -1 before the first entry; `isAvailable = !starts.isEmpty`.
- **The file is NOT in the Xcode target yet.** Only `Helps/` is a synchronized group; `Read/` is explicit, and pbxproj must not be hand-edited, so the maintainer has to add `paragraphs_ncv.json` to the FHLBible target (Copy Bundle Resources). Until then `isAvailable` is false and 「分段」 is disabled (verified path: it falls back gracefully). For testing in this session the file was copied by hand into the built `.app` (`cp … FHLBible.app/`), which is equivalent to Copy Bundle Resources for `Bundle.main`.

## Implementation (all in `Read/VCRead.swift` + 1 key; no pbxproj edit)
- `FHLUserDefaults.keys.ReadGrouping`.
- New: `enum ReadGrouping`, `final class ReadParagraphData`. `ReadRow` gained `var title: String?`, `var verseMarks: [ObjectIdentifier: DAddress]`, `with(addr:)`. `ReadColumnsLayout` gained `viewWidth` and an instance `labelGap` (`labelWidth > 0 ? 8 : 0`; `labelGapWhenLabel` static).
- `ReadModel`: `verseRows` (raw per-verse rows, what `setRows` builds) vs `rows` (what the view shows; `rebuildRows()` = `isGroupedByParagraph ? buildParagraphRows() : verseRows`, then `labelWidth`, `updateAutoWeights()`, `generation += 1`, clears selection and `verseActionRow/Addr`). `setGrouping`, `canGroup`, `isGroupedByParagraph`, `verseActionAddr`. `reload()` also clears `verseRows`.
- `buildParagraphRows()`: paragraph index per verse row (`ReadParagraphData.index`), consecutive rows with the same index form a group (NUI `grouping_by_paragraph`; -1 = before the first paragraph = untitled group), then per column the concatenation + merge logic above. Merged/“此譯本無” detection uses `plainText` (all `w` incl. `children` joined) because BibleText2DText turns "a" into "(併入上節)" and then `addParentheses` splits it into several DTexts — comparing a single `w` did not match (first attempt showed `21 (併入上節)22`).
- `ReadRowView`: outer `VStack { title; content }` with a `confirmationDialog` for paragraph rows (`row.label.isEmpty`); the label button keeps its own dialog for verse rows; both use `verseActionButtons` (`row.with(addr: model.verseActionAddr ?? row.addr)`).
- `VCRead.doWhenContentClicked`: before SN/ref/footnote handling, `row.verseMarks[ObjectIdentifier(dtext)]` → set `verseActionAddr/Row` and return. Identity works because `ViewDisplayCell` hands back the same DText objects it was given (`mainConvertWithSource` returns the source DText).
- zh-Hans strings 分段 / 單節 / 段落. `Helps/app_versions.md`: `## 4.14.5 (2026.10.23h)` (detail version).

## Decisions / rejected
- One shared paragraph list for all translations (like FHLNUI), not per-translation paragraphs (csb/rcuv files exist but unused there).
- No grouping on composite pages: hash-based lookup would give nonsense across non-adjacent chapters.
- Number as a DText in the text instead of a separate SwiftUI element: only way to inline it with the UITextView text; refDescription is just the cheapest way to get the blue colour (no new FHLCommon style). Tap is intercepted before the normal ref flow.
- Verse-mode merged placeholder left as is (no rowspan in List); FHLNUI's interleaved mode hides the placeholder and extends the label — possible later: caption "和合本 20-21".
- Unzipped JSON instead of .gz: no gzip decoder without a new dependency; size is small.

## Gotchas
- Simulator: after an unexplained device rotation (screenshots rotated 90°, both `rotate` directions only toggled between two landscape states) the fix was `simctl shutdown` + `boot`; the input connection needs ~10–20 s after boot ("input connection is still starting up").
- A tap on a tiny verse number must hit the right line; the first attempt hit the line above and nothing happened (read the glyph position from the screenshot at the 923-px scale, multiply by 0.406).
- Verified side effect of 4.14.4: custom column weights survive relaunch (saw a saved custom layout after restart).

## Verification
- Built `FHLBible` for iPhone 13 mini (iOS 27.0) and iPhone 15 Pro (iOS 17.4, compile only): BUILD SUCCEEDED.
- Ran on iPhone 13 mini (iOS 27.0), 3 translations (和合本 + 中文標準譯本 + NET聖經中譯本): 太1 paragraph mode, side-by-side: title wraps within the screen width, inline blue numbers, columns aligned; tapping the "2" opened the dialog titled 太 1:2; 西2 paragraph mode: titles per paragraph, 和合本 shows "20-21 …" then "22", other translations show 20, 21, 22 separately; interleaved + paragraph for 西2:20-23 looks right (title, caption, text); the grouping setting persisted across relaunch.
- NOT verified: iPad, 17.4 runtime, dark mode, GB (title conversion), Hebrew/Greek columns (bhs/fhlwh) in paragraph mode, multi-select / 圖片產生 in paragraph mode, tapping SN/ref/footnote inside paragraph text, Ps 119 (176 verses) performance, books where the data has `-1` (before first paragraph), chapters whose merged verse is the first of a paragraph with the previous verse in the previous paragraph (logic exists, not seen), disabled state when the resource is missing (read from code only; the resource was present in the test bundle).

## Not done / next steps
- Add `paragraphs_ncv.json` to the Xcode target (maintainer).
- Verse-mode merged verses (caption/label), share `ReadColumnsLayout` with Search/譯本比較 (still open from 1023j), image generation following arrangement/grouping, optional per-translation paragraph files, a paragraph "title hidden" option.
