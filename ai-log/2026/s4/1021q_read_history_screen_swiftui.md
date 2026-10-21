# "閱讀記錄" (read history) screen rewritten in SwiftUI, removed from Main.storyboard

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor + small UX redesign (storage and callback contract unchanged); third screen taken out of the storyboard
- Related logs: 1021p_audio_text_speed_screen_swiftui.md, 1021o_tsk_screen_swiftui.md
- Cross-project: none
- Commit: committed as 4.12.8 (release-notes section added to Helps/app_versions.md). Main.storyboard was committed as HEAD's file plus only the two scene removals; the Xcode 27 format rewrite stays uncommitted in the working tree.

## Goal / why
Next screen of the UIKit -> SwiftUI migration; the maintainer allowed a better iOS-style design. Entry: Read -> "···" -> 閱讀記錄 (`VCReadMore` row; `VCRead.pickFromHistory`). It is also reachable by the 3-finger right swipe tip shown in the menu (that gesture still goes through the same `pickFromHistory`).

## What the old screen did
- `UITableViewController` (storyboard `VCReadHistory`, plus an orphan `UINavigationController` scene whose root it was): rows "N. <addr string>" for `ManagerHistoryOfRead.s.cur` (UserDefaults string array, newest first; entries are `VerseRangeToString` output such as "創 1" or "詩 33:6,9;148:5;太 8:3;約 11:43"), a trash bar button.
- Tap a row: `popViewController(animated: false)` then `onClickAddr$.triggerAndCleanCallback(nil, addr)`. `VCRead` turns the string into a `VerseRange` with `StringToVerseRange().main` and fires `_addrsCurChanged$` (which also re-inserts it at index 0 of the history, de-duplicated).
- `viewDidDisappear` fires `onClickAddr$` with nil so the one-shot callback is always cleaned.
- Trash: keep only the first (current) entry, then pop. No confirmation.

## What changed
- `History/VCReadHistory.swift` rewritten:
  - `class VCReadHistory: UIHostingController<ReadHistoryView>`, `init()`, still exposes `onClickAddr$: IjnEventOnce<Any,String>` and the same `viewDidDisappear` nil trigger, so `VCRead.pickFromHistory` only changed from `gVCReadHistory()` to `VCReadHistory()`. Root view is created with no-op closures and replaced after `super.init` (to capture `[weak self]`), same pattern as `VCTsk`.
  - `@Observable ReadHistoryModel`: `items` (copy of the manager's array read once in `init`), `clearAllButLatest()`, `remove(at:)`; each mutation writes back through `ManagerHistoryOfRead.s.updateCur`.
  - `ReadHistoryView`: `List` of `Button` rows ("N. addr", `.buttonStyle(.plain)` + full width + `contentShape` so the whole row taps and the text is not blue), inline title "閱讀記錄", empty state `ContentUnavailableView` (iOS 17), trailing trash toolbar button.
- Redesign decisions (deliberate differences):
  - Trash now asks for confirmation (`confirmationDialog`, destructive button "清空閱讀記錄", title hidden because it would repeat the button text). After confirming it behaves as before (keep latest entry, pop back). The trash button is disabled when there is at most one entry (nothing to clear).
  - NEW: swipe-to-delete on a row (`.onDelete`), writes the shortened array back. Note: the one-entry list can be reduced to empty this way, which the old trash never did; the empty state covers it, and `VCRead._addToReadHistory` / `clickGoBack` cope with an empty array (`clickGoBack` only reads indices < count).
  - Accessibility: the trash button has the label "清空閱讀記錄"; rows use the system List so Dynamic Type wraps long address strings (rows with many refs wrap to 2 lines).
  - New localization key "清空閱讀記錄" added to zh-Hans (清空阅读记录) and zh-Hant Localizable.strings. The title key "閱讀記錄" already existed.
- `VCEasyFunctions.swift`: `gVCReadHistory()` removed (only user was `VCRead.pickFromHistory`).
- `Main.storyboard`: removed scene `KgC-Sz-1VF` (VCReadHistory table view controller, prototype cell, trash button with action `removeAllAndBack`) and the orphan Navigation Controller scene `Xuo-66-mNv` (only segue = root `Ils-6J-lJZ`). Working tree 32 -> 30 scenes; no remaining reference to either id or "VCReadHistory". (`zh-Hans/zh-Hant Main.strings` still contain the now-dead `KkQ-jI-AOE` title entry; left alone, harmless.)

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED (also after the last tweak, titleVisibility .hidden).
- Ran in the simulator with 7 existing history entries: 閱讀 -> ··· -> 閱讀記錄 shows the numbered list, long entries wrap; tapped entry 4 -> popped back to the reader showing the 詩 33:6,9;... range, and reopening the screen showed that entry moved to the top (existing VCRead logic); trash -> confirmation popover -> destructive button -> back to reader; reopening showed a single entry and a greyed-out trash.
- NOT verified: swipe-to-delete (not exercised), the empty state, the final build's dialog without the title (screenshot was taken with the title visible), GB (簡體) strings, VoiceOver, Dynamic Type, dark mode, iPad, iOS 17.4 runtime, the 3-finger swipe entry, no unit tests run. The simulator history data was changed by the test (cleared to one entry).

## Gotchas
- On the iOS 27 simulator, a `confirmationDialog` attached to a toolbar button shows as a popover bubble anchored at the button, not a bottom action sheet; a visible title just repeats the button, so hide it.
- Remove a scene by hand: also delete its `<!--title-->` comment line, and look for `relationship="rootViewController"` segues to find the orphan nav controller.
- Simulator coordinate space for tap was 360x780 this session (screenshot px x 0.39), not 375x812.

## Open issues / next steps
- Release notes: `## 4.12.8 (2026.10.21h)` added to `Helps/app_versions.md`; `VCIndex` labelVer/labelDate still show the last release (4.11.1).
- Remaining UIKit screens: VCComment (same shape as VCTsk), VCSnDict, VCFooter, VCAudioStopTimer, VCAudioTextBible main screen.
