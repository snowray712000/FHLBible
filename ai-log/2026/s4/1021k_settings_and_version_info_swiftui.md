# Settings and Version Info screens rewritten in SwiftUI

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change, behavior preserved)
- Related logs: 1021e_version_info_screen.md, 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none (FHLBibleTW has its own UIKit `VCVersionInfo`, untouched; FHLCommon untouched)
- Commit: uncommitted

## Goal / why
First two screens of the gradual UIKit/Storyboard -> SwiftUI migration (see 1021j). Both were already pure code (not in `Main.storyboard`) and are the simplest screens in the app.

## What changed (behavior level)
- **Version Info** (`Helps/VCVersionInfo.swift`): `VersionInfoView` (SwiftUI `List`, `.insetGrouped`) replaces the `UITableViewController`. Content and rules are identical to 1021e: one section per `app_versions.md` `##` section, one row per item, multi-line rows, header = `<title>  <date>` plus the suffix "最新" on the first non-To-Do section (section header text uses `.textCase(nil)` so it is not upper-cased), a single row "找不到版本資訊" when the md is empty. Rows are not selectable. Inline nav title "版本資訊".
- **Settings** (`VCSetting/VCSettings.swift`): `SettingsView` (SwiftUI `List` of two `Button` rows) replaces the `VCOptionListViaTableViewControllerBase` subclass.
  - Row 1 "當機重置" (title blue) + explanation: sets `ManagerAddress.s.updateCur(VerseRange(DAddress(1,1,1).generateEntireThisChap()))`, `ManagerBibleVersions.s.updateCur(["unv"])`, `ManagerIsSnVisible.s.updateCur(true)`, then shows an alert "訊息" / "已重置，可再嘗試使用(1秒後繼續)" that is dismissed automatically after 1 s (`DispatchQueue.main.asyncAfter`; the old code blocked the main thread with `sleep(1)`). The alert also has an "OK" button (SwiftUI alerts need one; the old alert had none).
  - Row 2 "Bugs" + explanation: alert "打開到 support urls嗎？(https://bible.fhl.net/ios/FHLBibleSupport/index.html)" with Cancel / OK; OK opens `https://bible.fhl.net/ios/FHLBibleSupport/index.html` via `@Environment(\.openURL)`.
  - New: inline nav title "設定" (the old screen had no title). Table style changed from plain to inset grouped (default `List`).
- `VCVersionInfo` and `VCSettings` are now `UIHostingController<...View>` subclasses with a no-argument `init()`, so the call sites in `VCIndex` (`pushViewController(VCSettings(), ...)`, `pushViewController(VCVersionInfo(), ...)`) are unchanged. `VCSettings` is no longer `public`.

## Design and decisions
- The views live in the same files as the hosting controllers. `VCSetting/` is a classic Xcode group (new files would need "Add Files..." in Xcode); `Helps/` is a file-system-synchronized group. Reusing the existing files avoided any pbxproj edit in both cases.
- No `@Observable` / `ObservableObject`: both screens only have local `@State` (alert flags) and static data, so no bridging from `IjnEvent` was needed.
- `VCOptionListViaTableViewControllerBase` (in FHLCommon, still used by VCHelps and other pickers) is untouched.
- `Tools/VCOptionListViaTableViewControllerBase.swift` in FHLBible is an entirely commented-out old copy; irrelevant.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED.
- Ran in the iPhone 13 mini simulator (iOS 27.0): home -> 設定 shows the two rows with the new inline title; tapping "Bugs" shows the confirm alert (Cancel dismisses it); the version-info "ⓘ" opens the new list with To Do / 4.12.2 (最新) / 4.12.1 / 4.11.1 in order and wrapped rows.
- NOT verified: the "當機重置" alert itself (the row press highlight was seen, but the alert auto-closes after 1 s and could not be captured by the screenshot tool latency), pressing OK on the Bugs alert (would open Safari), iOS 17.4 runtime (only built against the iOS 27 SDK), dark mode, Dynamic Type, iPad, localisation (new string "設定" has no .strings entry, falls back to the key, same as the other recent strings).

## Gotchas
- The simulator tool's `tap` with the default (instant) duration did not register on SwiftUI `List` buttons; `duration: 0.1`-`0.15` worked. Taps during a navigation pop animation are swallowed, so wait for the transition. Tap coordinates are in the real 375x812 point space, not the 360x780 the tool reports.
- A SwiftUI `.alert` always renders at least one button; the "no-button, auto-dismiss" UIKit alert cannot be reproduced exactly.

## Open issues / next steps
- Decide whether the "當機重置" alert should keep the OK button or become a lighter toast.
- Add Localizable.strings entries for "設定" if localisation matters.
- Next candidate screens: see 1021j.

## Addendum (same day): release notes
- Added `## 4.12.3 (2026.10.21c)` to `Helps/app_versions.md` (SwiftUI rewrite of the two screens; minimum iOS is now 17.0) and committed under that version. `VCIndex` `labelVer`/`labelDate` still show the last release (4.11.1), per the numbering convention in 1021e.
