# Fix: tapping text in a ViewDisplayCell hit the wrong DText, or nothing (Hebrew text)

- Date: 2026-10-22
- Project: FHLBible
- Type: fix (user-reported, "serious")
- Related logs: 1021y_sn_dict_screen_swiftui.md (the dictionary screen where it was noticed; not SwiftUI-specific)
- Cross-project: FHLCommon `ai-log/2026/s4/1022a_dtext_tap_ranges_from_attributed_string.md` (new `mainConvertWithSource`). FHLCommon must be committed first.
- Commit: not committed.
- Release notes: `Helps/app_versions.md` section `## 4.12.16 (2026.10.22a)`.

## Symptom
In the 浸宣/CBOL dictionary entry (e.g. H8064, H430) the blue cross-reference `#創1:1|` after `<神出> 2407a` could only be tapped by hitting a spot several characters to the LEFT of it (the number `2407a`); tapping the link text itself did nothing. Same for every `ViewDisplayCell` user (Read, Tsk, Comment, Footnote, versions compare, dictionary, search results through `ViewDisplayTable2`).

## Root cause
`ViewDisplayCell.tapResponse`: `FindIndexOfCharInTextView` returns the UTF-16 character index in the text view (this part is right); `FindWhichDTextFromIndexOfChar` then walked the `[DText]` summing `DText.cntChar` until the sum exceeded that index. `cntChar` does not equal what the converter actually emitted:
1. `DTextDrawToAttributeString.cvt` prepends an invisible 2-char `"H:"` to every `isHebrew == 1` DText (`gHebrewAttributeSmall`, it breaks bidi runs) - never counted -> +2 per Hebrew word.
2. `cntChar` used `w.count` (grapheme clusters); Hebrew with niqqud/cantillation marks and CRLF have more UTF-16 units than graphemes -> a few more per word.
Result: the DText-side running sum is smaller than the real index, so by the time the cursor reaches a link its tap target has slid left; drift grows with the amount of Hebrew above it (a dictionary entry starts with the Hebrew headword, so every ref was shifted ~6+ chars).

## Second root cause (found after the first fix): taps ignored entirely
User report after the first fix: in the H776 浸宣 entry (reached 創1:1 -> tap `<H776>` -> 浸宣) tapping `#創1:1|` did nothing, while the same link in H430 worked. A temporary NSLog in `tapResponse` showed `idx=-1` (text length 2277), i.e. rejected before DText lookup, by `FindIndexOfCharInTextView.isNotInFirstAndEndCharacter`: it asked `layoutManager.boundingRect(forGlyphRange: NSRange(location: textLength-1, length: 1))` for the last character, but that API takes GLYPH indices and Hebrew with niqqud/cantillation yields fewer glyphs than UTF-16 characters, so the range is past the end, the rect is empty/zero, `yy.max()` collapses to the first line's maxY, and every tap below the first line counts as "outside the text". Whether it fails depends on the ratio of marks in the entry (H430 passed, H776 failed).
Fix: `DisplayCellClick/FindIndexOfCharInTextView.swift` rewritten: `ensureLayout`, `glyphIndex(for:in:)` for the tapped point, `lineFragmentUsedRect(forGlyphAt:)` of that glyph's line; reject (-1) if the point is above/below that line rect (line rect includes line spacing) or more than 4pt left/right of it; otherwise `characterIndexForGlyph(at:)`. Taps below the last line / beyond a short last line still return -1 (original intent kept); taps right of a short middle line no longer snap to its last character.

## Fix part 1 (approach: record real ranges, never recompute)
- FHLCommon: `DTextDrawToAttributeString.mainConvertWithSource` (see the FHLCommon log).
- `Read/ViewDisplayTable/ViewDisplayCell.swift`: `cvtForTextView` now uses it and builds `_charRanges: [DTextCharRange]` (`(range: NSRange, dtext: DText)`), `location = running attributedString.length`, `length = piece.length`, so hidden SN pieces (empty) get length 0 and the Hebrew `H:` belongs to its own DText. `typealias DTextCharRange` and the protocol `IFindWhichDTextFromIndexOfChar.findWhichDText(_ ranges:, _ idxChar:)` changed signature accordingly.
- `DisplayCellClick/FindWhichDTextFromIndexOfChar.swift`: rewritten to `ranges.first { NSLocationInRange(idx, $0.range) }?.dtext`; idx < 0 or no hit -> nil. Old behavior returned `dtexts.last` for a tap past the end; callers all treat nil as "nothing tapped" (`onClicked$` payload is optional), now actually nil.
- `FindIndexOfCharInTextView`: see "Second root cause" above (the glyph-bounds guard was itself wrong and is replaced).
- Alternative considered and rejected: storing the DText as an attributed-string attribute (attribute lookup at the index). A non-archivable object value in the attributed string can break pasteboard/RTF export in UITextView; a parallel range table has no such risk. Rewriting the screens (SwiftUI `Text`) would not have helped: the problem was the mapping, and SwiftUI `Text` cannot do per-character taps anyway.

## Verification
- `xcodebuild` FHLBible scheme and FHLBibleTW scheme (generic iOS Simulator): both BUILD SUCCEEDED.
- iPhone 13 mini (iOS 27.0) simulator, FHL和合本: opened H430 浸宣 entry; tapping directly on the text `#創1:1|` opened Read at 創 1:1; tapping on `#出 15:26|` (several Hebrew headwords above it, largest old drift) opened 出 15:26. 
- After the second fix (iPhone 13 mini, iOS 27.0, FHL和合本): 創1:1 -> `<H776>` -> 浸宣 -> tap `#創1:1|` in the H776 entry now opens 創1:1 (before: no response, idx=-1). Both schemes built again (FHLBible; FHLBibleTW was built after part 1, FindIndexOfCharInTextView is FHLBible-only).
- NOT verified: Read screen SN/footnote/ref taps, long-press multi-select, search results, TW app at runtime, iOS 17.4, RTL Hebrew text taps, taps on `(`/`)` of parent-wrapped DTexts, VCWhenLongPress (separate code path, does not use this mapping), `Common/IjnTextView.swift` (`IjnClickTextView`, separate legacy tap code; not checked for the same bug).

## Gotchas
- Never derive character ranges from DText content (`w.count`, `cntChar`). Always from the produced `NSAttributedString` lengths. `cntChar`/`cntCharContainFront/Back` in FHLCommon are now dead but still wrong; they were left in place (not mine to remove, FHLBibleTW compiles against FHLCommon).
- Simulator: screenshots lag one frame behind taps; look at a second screenshot before concluding a tap did nothing.
