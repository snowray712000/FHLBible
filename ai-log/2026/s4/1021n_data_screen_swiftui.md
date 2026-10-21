# Data (offline resources) screen: view layer rewritten in SwiftUI

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change, behavior preserved; logic untouched)
- Related logs: 1021m_helps_screen_swiftui.md, 1021k_settings_and_version_info_swiftui.md, 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none (FHLCommon's `VCOptionListViaTableViewControllerBase` untouched)
- Commit: committed as 4.12.5 (release-notes section added to Helps/app_versions.md); the maintainer then tested the download/delete flows manually in the simulator and reported no problems

## Goal / why
Fourth screen of the gradual UIKit -> SwiftUI migration. The home button "資料" (`goData` in `VCIndex`, storyboard only holds the button) pushes `VCData()`. `VCData` was pure code (`Download/VCData.swift`, ~750 lines, no storyboard/xib), a `VCOptionListViaTableViewControllerBase` table: one row per downloadable resource, title + status subtitle.

## Scope decision
Only the view layer changed. The screen is much heavier than Settings/Help/Version Info: it owns download, unzip, normalisation, deletion, status detection and a wait-for-`main.db` queue. None of that was rewritten. The six `extension VCData` files (`DoOneDownload_*.swift`) use `VCData` purely as a namespace for nested classes (`VCData.DoOneDownload_comm` ...) and needed no change; `CheckInitialState` / `DownloadState` / `DoDeleteBible*` / `MainDbMakeSureExist` / `DoVersionWaitMainDbCompleted` / `BibleVersionsListForDownloadGetter` are unchanged.

## What changed
- `class VCData: UIHostingController<DataListView>` (was `VCOptionListViaTableViewControllerBase`). `init()` keeps `VCIndex.goData()` unchanged. Same trick as 1021m: root view is created with a no-op closure, then replaced after `super.init` with `onSelect` calling `self._doClickRow(row)` (`[weak self]`).
- New `@Observable final class DataListModel { rows: [Row] }` with `Row { id (= row index), title, subtitle, color: Color }`.
- `VCData.refreshModel()` builds `model.rows` from the existing arrays `_ovTitle1Data` (titles), `_ovTitle2Data` (status strings or download progress) and `_ovColorsData` (`UIColor` -> `Color(uiColor:)`). It replaces every `tableView.reloadData()` (viewDidLoad end, after delete confirmation, download-progress callback via `DispatchQueue.main.async`, download-finished callback via `DispatchQueue.main.async`). Must run on main.
- Removed: the three `override var _ovTitle1/_ovTitle2/_ovColors` bridges to the base class, the `_onClickRow$` subscription; `updateTitle2DataAndColorFromStates` now uses `_ovTitle1Data.count`.
- `DataListView` (SwiftUI `List`): per row a plain `Button` (full-row tap via `frame(maxWidth: .infinity)` + `contentShape`), `VStack` of title (colored by state) and subtitle (`.subheadline`, secondary, hidden when empty). Inline nav title "資料" ("资料" in GB; new, the old screen had no title). Style changed from plain table to inset grouped.
- Colors (from `DownloadState.toColor()`): in use / cannot download = label; needs update = systemRed; everything else (not downloaded, waiting to process, downloading) = systemBlue. As before the color applies to the title, not the subtitle.
- Unchanged on purpose: deletion confirmation still uses the UIKit alert helper `MessageBox.presentDeletionAlert(self, ...)` (`Tools/messageBox.swift`); it works with any `UIViewController`, so no SwiftUI rewrite was needed. A SwiftUI `.alert` could replace it later.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED. The only VCData.swift warning (`will never be executed`, `isDebug` in `DoDeleteBibleBase`) is pre-existing.
- Ran in the simulator: home -> 資料 shows 註釋 / Parsing / CBOL字典 / 原文直譯(參考用) / 呂振中譯本 / FHL 和合本 / ... with subtitles "未下載." / "待處理." in blue titles and the inline title "資料".
- NOT verified (deliberately not clicked: a tap downloads or unzips data, and this project's rule is not to download data files on my own): tapping a row to download, live progress text ("下載中 x/y mb p%"), the finished refresh, delete confirm + refresh, "需更新" red state, the queue waiting for `main.db`, GB titles, iOS 17.4 runtime, dark mode, Dynamic Type, iPad. Scrolling to the bottom of the long list was not exercised either.

## Gotchas
- `UIHostingController` + stored properties: `model` must be assigned before `super.init` (use a local `m`), and the `required init?(coder:)` also has to create it.
- The progress callback mutates `_ovTitle2Data` on a background thread and then dispatches `refreshModel()` to main (same data race as the old code with `reloadData`; not fixed here).
- `@Observable` needs iOS 17 (fine, minimum is 17.0).

## Open issues / next steps
- Release notes: `## 4.12.5 (2026.10.21e)` added to `Helps/app_versions.md`; `VCIndex` labelVer/labelDate still show the last release (4.11.1).
- A later step could move the logic out of the view controller into a model object and replace the UIKit deletion alert; not done to keep the diff small and risk low.
