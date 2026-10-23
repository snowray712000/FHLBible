# Fix: Read screen text only ~60% wide when showing a multi-range verse list (4.14.1)

- Date: 2026-10-23
- Project: FHLBible
- Type: fix
- Related logs: 2026/s4/1021w_read_screen_swiftui.md, 2026/s4/1021o_tsk_screen_swiftui.md, 2026/s4/1023f_release_4_13_1_and_detail_version_toggle.md
- Cross-project: none
- Commit: uncommitted

## Goal / why
Maintainer report (version label 4.14.1): when the Read screen shows a composite address (several books/chapters, e.g. "出 18:10;創 9:26;24:27;得 4:14;撒上 25:32,39;…", typically reached from a 串珠 result) the verse text was laid out in a column roughly 150 pt wide on a 375 pt phone, leaving the right ~40% blank. Single-chapter reading was fine.

## Root cause
`DTextContentView.sizeThatFits` (FHLTools/Tsk/VCTsk.swift) answered every proposal with a width: finite -> that width, `nil`/inf/0 -> `max(bounds.width, 320)`. SwiftUI's `HStack` (ReadRowView: verse label + `VStack` of cells) probes children with width 0 (minimum), inf (maximum) and then the real proposal. Replying 320 to the *0* probe told the layout the text view cannot shrink below 320 pt, so with a wide label column ("出 18:10" is ~58 pt instead of the 28 pt of a bare verse number in single-chapter mode) the stack distribution went wrong and the final proposal handed to the text view was only 163.5 pt (observed with a temporary NSLog: proposals inf -> 0 -> 163.5, all rows).

## What changed
- `sizeThatFits`: if `proposal.width == 0` return `CGSize(0, 0)` (a genuinely shrinkable view); other cases unchanged. After the fix the text fills the full available width; 串珠 screen still renders normally.
- `Helps/app_versions.md`: new detail section `## 4.14.1 (2026.10.23e)` (4.14.* is an even-minor "detail" version, hidden by default; roll up into 4.15.1). `VCIndex.labelVer/labelDate` not bumped (same convention as 4.12.*).

## Gotchas
- The long title in the nav bar was NOT the cause (it is truncated to "出18:10;創…" with minimumScaleFactor); the first screenshot only looked that way because the nav bar was mid-transition.
- Label widths still differ per row (出 18:10 vs 創 9:26), so the text's left edge is slightly ragged in composite mode; left as is.
- Debug approach that worked: temporary `NSLog` in `sizeThatFits` + `simctl spawn log stream`, then remove.

## Verification
- Built `FHLBible` scheme for iPhone 13 mini (iOS 27.0 simulator); Read with the composite address now full width; 串珠 for 創 9:26 renders fine.
- Not verified: iOS 17.4 runtime, iPad two-column mode, 譯本比較 / 注腳 / 註釋 screens (they share `DTextContentView` but only the zero-width probe changed), dark mode.
