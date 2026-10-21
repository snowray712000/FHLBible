# In-app version info screen (app_versions.md)

- Date: 2026-10-21
- Project: FHLBible
- Type: feature
- Related logs: none
- Cross-project: none (FHLBibleTW has no home screen / version label; FHLCommon untouched)
- Commit: uncommitted

## Goal / why
The maintainer wanted release notes visible inside the app, modeled on the sibling web project `FHLNUI` (`app_versions.json`, shown next to its version number), but authored as Markdown. Order: To Do first, then the newest version, then older ones further down. Displayed as a "table".

## Starting state
- Home screen is `VCIndex` (storyboard scene in `Base.lproj/Main.storyboard`, nav-controller based). Bottom-right has two labels: `labelVer` ("4.11.1") and `labelDate` ("2026.04.13a"), both hard-coded in `VCIndex.viewDidLoad`; Info.plist `CFBundleShortVersionString` is `4.11` (not kept in sync). Both labels had `userInteractionEnabled = NO`.
- No release-notes UI existed.

## What changed (behavior level)
- Next to the version label on the home screen there is a small `info.circle` button (14pt SF Symbol, left of `labelVer`); the version label itself is also tappable. Either pushes `VCVersionInfo` onto the navigation stack, titled "版本資訊".
- `VCVersionInfo` is an `.insetGrouped` `UITableViewController`. One section per Markdown `##` section, one row per `- ` item, self-sizing multi-line rows (`numberOfLines = 0`, body text style). Section header = `<title>  <date>`; the first non-To-Do section also gets the suffix "最新". If the md is missing/empty, a single row "找不到版本資訊" is shown.
- Content comes from `Helps/app_versions.md`, bundled in the app (no network).

## Design and decisions
- Placement: next to the version number (like FHLNUI), not a Settings row and not a 5th home button — keeps the 2×2 button grid intact and is where users look when asking "what version is this".
- Component: grouped `UITableView`, not a real multi-column table. Items are 50–200 chars; on a ~375pt wide phone a version|date|text table would squeeze the text column. Rejected: WKWebView rendering md→HTML (heavy, no native look/dark mode/dynamic type), `AttributedString(markdown:)` (iOS 15 API, and does not give sections; project rule is to avoid non-essential iOS 15 APIs).
- Data source: bundled md (offline, no URL to maintain). Remote loading like FHLNUI was offered and declined.
- Custom tiny parser instead of a Markdown library (no new dependencies).
- Did NOT make `labelVer`/`labelDate` read from the md (possible later: single source of truth); they are still hard-coded in `VCIndex.viewDidLoad`. Release procedure now: add a section to `app_versions.md` AND update those two strings.
- The info button is created in code (`VCIndex.setupVersionInfoEntry`) rather than editing the storyboard XML.
- New files were placed in `FHLBible/Helps/` because that folder is a `PBXFileSystemSynchronizedRootGroup` in `FHLBible.xcodeproj`: files dropped there join the target automatically (the `.md` is copied as a bundle resource), so no pbxproj edit was needed. Other folders (e.g. `VCSetting/`) are classic groups and would need "Add Files…" in Xcode.

## Key files / types / functions
- `FHLBible/Helps/app_versions.md` — the release notes (format below). Its header HTML comment documents the format.
- `FHLBible/Helps/VersionInfoParser.swift` — `DVersionInfoSection {title, date?, items, isToDo}`; `VersionInfoParser.parse(_:)`, `loadFromBundle(_:)` (resource `app_versions.md`), `splitTitleAndDate(_:)`.
- `FHLBible/Helps/VCVersionInfo.swift` — the table screen.
- `FHLBible/VCIndex.swift` — `setupVersionInfoEntry()` (button + tap gesture) and `@objc goVersionInfo()`.

## Contracts and algorithms
`app_versions.md` format (lines not matching are ignored):
```
<!-- comment, may span lines -->
## To Do
- item
## 4.11.1 (2026.04.13a)
- ✨ 新增: ...
  continuation line (starts with space/tab, appended to previous item with "\n")
```
Parsing: strip `<!-- ... -->` (multi-line aware) → line by line: `## ` starts a section; title/date split on a trailing `( … )` (date optional) → `- ` appends an item to the current section; indented non-empty line after an item appends to that item. A section is To Do iff its title lower-cased with spaces removed equals `todo`. Order in the file is display order (To Do first, versions newest→oldest).

Layout of the button: 32×32 `UIButton(.system)` added to `labelVer.superview`, trailing = `labelVer.leading − 2`, centerY = `labelVer.centerY`; tint = label text color.

Initial content was derived from git history, not invented: 4.7.1 (2026.03.21a: background audio playback setting for 有聲文字), 4.9.1 (2026.03.30a: middle word invisible/unselectable fix, home 教學 fix), 4.11.1 (2026.04.13a: 聖經目錄, swipe-right gesture bug, Parsing segmentation / font scaling / no single-finger chapter switch). To Do holds a placeholder "（目前沒有待辦事項）" for the maintainer to replace.

## Gotchas
- The simulator tool's tap coordinate space is labeled 360×780 but taps land in the device's real point space (375×812 on this iPhone 13 mini sim). Taps computed from screenshot pixels ÷ 2.564 missed the 32pt button by ~13pt; the button was verified by `hitTest` logging and a tap at the true point (296, 742). This was a test-harness issue, not an app bug.
- `UITableViewController.init(style:)` must be overridden in a custom init (`super.init(style: .insetGrouped)`), including the `init?(coder:)` path.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible` for the iPhone 13 mini simulator (iOS 27.0): BUILD SUCCEEDED; `app_versions.md` found inside `FHLBible.app`.
- Ran in the simulator: home screen shows ⓘ left of "4.11.1"; tapping it pushes "版本資訊" with To Do, 4.11.1 (最新), 4.9.1, 4.7.1 in that order, long lines wrap, scrolls correctly.
- NOT verified: tapping the version label itself (gesture), iPad layout, dark mode, Dynamic Type at large sizes, iOS 15/16 devices (this environment's simulators are iOS 17.4 and 27.0 only), the zh-Hans/en localizations (new strings "版本資訊", "最新", "找不到版本資訊" have no .strings entries and fall back to the key). FHLBibleTW not built (no change there).

## Open issues / next steps
- Replace the To Do placeholder with real items; the maintainer should proofread the git-derived notes.
- Optional: derive `labelVer`/`labelDate` from the first version section of the md; optional "new version" badge using a last-seen-version UserDefaults key.
- Optional: add Localizable.strings entries for the new strings.

## Addendum (2026-10-21, same day): version numbering convention
- Maintainer's convention: released versions are `4.odd.1` (current 4.11.1, next 4.13.1); the last number is the build. The even middle number (`4.12.N`) marks in-development work: each small piece of development gets its own `## 4.12.N (date)` section in `app_versions.md`, and the next release (4.13.1) is the accumulation of the 4.12.* entries (borrowed from FHLNUI's practice). Documented in the md's header comment.
- Added section `## 4.12.1 (2026.10.21a)` ("版本資訊" feature itself) and amended the original commit accordingly (commit hash changed; see `git log`).
- `labelVer`/`labelDate` in `VCIndex` and MARKETING_VERSION were NOT changed: they still show the last release (4.11.1). Side effect: the table marks the first non-To-Do section ("4.12.1") as "最新" even though it is unreleased.
