# Release notes 4.13.1 rollup + hide/show of even-minor "detail" versions

- Date: 2026-10-23
- Project: FHLBible
- Type: feature
- Related logs: 2026/s4/1021e_version_info_screen.md, 2026/s4/1021k_settings_and_version_info_swiftui.md, 2026/s4/1021i_warnings_sendable_publicfunc_4_12_2.md
- Cross-project: none (FHLBibleTW / FHLCommon untouched)
- Commit: uncommitted

## Goal / why
4.12.1 … 4.12.21 were small development increments (mostly UIKit -> SwiftUI screen rewrites). The maintainer wanted them rolled up into one version, 4.13.1 (not to be released formally yet), and the version-info screen to hide the detailed 4.12.* sections by default. Convention going forward: versions `major.EVEN.N` are development detail (4.12.*, 4.14.*, …), `major.ODD.1` is the official rollup (4.11.1, 4.13.1, 4.15.1, …). The rule applies from 4.12.1 on (4.11.1 is odd, so unaffected).

## Starting state
- `Helps/app_versions.md` had sections To Do, 4.12.21 … 4.12.1, 4.11.1, 4.9.1, 4.7.1. `VCIndex.labelVer/labelDate` were still "4.11.1" / "2026.04.13a" (the 4.12.* steps never bumped them). `MARKETING_VERSION` in pbxproj is 4.11 and is deliberately not touched (project rule: no hand edits of pbxproj).
- `VersionInfoView` listed every section.

## What changed (behavior level)
- New section `## 4.13.1 (2026.10.23d)` in `app_versions.md`, inserted directly under To Do: 8 user-facing bullets summarising all 4.12.* (SwiftUI rewrites list, multi-select/copy/image, search, retry states, fixes, min iOS 17.0, note that detail versions are hidden). The 4.12.* sections are kept unchanged below it.
- `VCIndex.labelVer = "4.13.1"`, `labelDate = "2026.10.23d"` (home screen version row shows "4.13.1 (2026.10.23d)").
- `DVersionInfoSection.isDetail`: title split on "."; exactly 3 integer parts and `parts[1] % 2 == 0` -> detail. To Do and unparsable titles are not detail.
- `VersionInfoView`: `@AppStorage("VersionInfoShowDetail")` (Bool, default false). Visible sections = all, or all minus detail when the flag is false. A trailing toolbar `Menu` (ellipsis.circle) containing a `Toggle("顯示開發過程的小版本")` is shown only when the md contains at least one detail section. The "最新" tag goes to the first visible non-To-Do section (still 4.13.1 in both modes).
- Header comment of `app_versions.md` documents the convention (write 4.14.N detail sections, roll them up into 4.15.1).
- zh-Hans `Localizable.strings`: "顯示開發過程的小版本" = "显示开发过程的小版本" (zh-Hant uses the key itself).

## Design and decisions
- The "flag" is a persisted user toggle, not a field in the md: the parity rule makes the md self-describing and needs no extra marker per section. Rejected: an `<!-- hidden -->` marker per section (easy to forget); a build-time flag (users could never see the detail).
- Default hidden: official users see only rollup versions.
- Bumped `labelVer` even though 4.13.1 is not shipped yet, because the maintainer said the 4.12.* group "is formed into 4.13.1"; if that is unwanted, revert the two strings.

## Key files / types / functions
- FHLBible/Helps/app_versions.md — content + convention comment.
- FHLBible/Helps/VersionInfoParser.swift — `DVersionInfoSection.isDetail`.
- FHLBible/Helps/VCVersionInfo.swift — `VersionInfoView` filtering + toolbar toggle.
- FHLBible/VCIndex.swift — `labelVer`, `labelDate`.

## Contracts and algorithms
- UserDefaults key `VersionInfoShowDetail` (Bool, absent = false).
- `isDetail("4.12.7") == true`, `("4.13.1") == false`, `("4.11.1") == false`, `("To Do") == false`, `("4.12") == false` (needs 3 parts).

## Gotchas
- The simulator screenshot tool returned the previous frame right after a tap; take a second screenshot before concluding a tap failed.
- `.toolbar { if cond { ToolbarItem … } }` works on iOS 17 (ToolbarContentBuilder supports `if`).

## Verification
- `xcodebuild -scheme FHLBible` for iPhone 18 Pro (iOS 27.0 simulator): BUILD SUCCEEDED.
- On the simulator: home shows 4.13.1 (2026.10.23d); version info shows To Do + 4.13.1 (marked 最新) and the older official versions only; menu toggle -> 4.12.21, 4.12.20 … appear.
- Not verified: iOS 17.4 runtime, dark mode, toggle off again, FHLBibleTW (not affected).

## Open issues / next steps
- `MARKETING_VERSION` (4.11) still disagrees with the displayed version; left for the maintainer.
- Release dates in the md for 4.13.1 are the roll-up date, not an App Store date.
