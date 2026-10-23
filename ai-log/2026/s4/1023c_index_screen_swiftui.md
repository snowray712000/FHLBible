# Home ("Index") screen rewritten in SwiftUI with a redesign

- Date: 2026-10-23
- Project: FHLBible
- Type: refactor + redesign
- Version note: 4.12.20 (2026.10.23b) in `Helps/app_versions.md`
- Related logs: 1021e_version_info_screen.md (the old ⓘ next to the version label), 1021k_settings_and_version_info_swiftui.md (VCSettings/VCVersionInfo wrappers still pushed from here)
- Cross-project: none
- Commit: not committed (user did not ask).

## Before
`Main.storyboard` scene "Index" (root of the initial `UINavigationController`, class `VCIndex`): a title button (app icon + "信望愛聖經工具"), a 2x2 block of gray buttons (閱讀 / 設定 / 資料 / 教學, `@IBAction goRead/goSetting/goData/goHelp`), two labels bottom-right (`labelVer` "4.11.1", `labelDate` "2026.04.13a") and a programmatically added ⓘ button + tap gesture on `labelVer` that pushes `VCVersionInfo`. No indication of where 閱讀 would open; tapping 閱讀 while the translation list was still loading did nothing visible (and could be tapped repeatedly).

## After (all in `VCIndex.swift`; no new files, so no pbxproj edit)
- `HomeModel` (`@Observable`): `addrText` (current chapter via `VerseRangeToString().main(ManagerAddress.s.cur.verses, ManagerLangSet.s.curTpBookNameLang)`, e.g. "創 1"), `versText` (`BibleVersionConvertor().na2cna` of `ManagerBibleVersions.s.cur`; "name" or "name +N", same as `ReadModel.versSummary`), `isOpening`, `isLoadFailed`. `refresh()` is called from the view's `.onAppear`, which also fires when popping back from Read (Read changes the current address/translations).
- `HomeActions`: closures `read/data/setting/help/versionInfo` supplied by `VCIndex` (pushing needs the `UINavigationController`), same pattern as `ReadActions`.
- `HomeView`: `List` `.insetGrouped`. Header row (clear background): `FHLLOGO` app icon + app name (`.title2`, header trait). Section 1: one big "閱讀" button row (icon tile, title, current chapter, translation summary, chevron / `ProgressView` while `isOpening`, disabled while opening). Section 2: 資料 ("下載與管理譯本"), 設定 ("當機重置、回報問題"), 教學 ("各項功能的使用方式") rows, Settings-app style (colored rounded-square SF Symbol tile: orange/gray/green, title + footnote subtitle, chevron). Section 3: 版本資訊 row (indigo tile) with trailing "4.11.1 (2026.04.13a)". Alert "無法取得譯本清單" when loading failed. Everything uses system colors/text styles (Dynamic Type, dark mode).
- `VCIndex` is still a plain `UIViewController` (class name kept for the storyboard). It keeps the `AutoLoadDUiabv` setup in `viewDidLoad`, sets `navigationItem.backButtonTitle = "首頁"` (pushed screens used to show "Back"), and embeds `UIHostingController(rootView: HomeView(...))` as a child filling its view (`addChild`, edge constraints to the view, `didMove(toParent:)`).
- `labelVer` / `labelDate` are now `private let` strings in `VCIndex` (still the place to edit on release, as `app_versions.md`'s header says). Values untouched: "4.11.1", "2026.04.13a".
- 閱讀 flow unchanged in substance: if `AutoLoadDUiabv.s.record.count == 0` call `reloadAsync()`, then `testThenDoAsync` (0.3 s polling, max 50 tries, silent give-up) until the count is non-zero, then push `VCRead` with `setInitData(globalManagerAddress.cur, ManagerBibleVersions.s.cur)`. New: `isOpening = true` meanwhile; a 17 s `asyncAfter` (just after `testThenDoAsync` gives up) clears it and sets `isLoadFailed` if still opening.

## Storyboard
The Index scene (`FDS-c9-8MC`) was reduced to an empty `viewController` (customClass `VCIndex`, one empty `view`, navigationItem); the label / button / constraint / outlet / action XML and the now-unused `<image name="Icon-App-40x40.png">` resource were removed. `UINavigationController` scene, initial view controller, Info.plist (`UIMainStoryboardFile`, `UISceneStoryboardFile`) untouched. Storyboard now has 6 scenes (Index shell, nav controllers, VCSnActionPicker, VCVerseActionPicker, VCWhenLongPress).

## Decisions / rejected
- **Not** `class VCIndex: UIHostingController<HomeView>`: a storyboard-loaded controller gets its `view` from the storyboard, which would replace the hosting view (blank screen); a root of a relationship segue cannot use `@IBSegueAction`. Making the nav controller in code would need Info.plist/SceneDelegate changes (release config) — not done without asking. Child hosting controller is the safe path; the storyboard can disappear later by building the `UINavigationController` in `SceneDelegate`.
- No large title: `prefersLargeTitles` is nav-bar-wide and would leak to pushed UIKit screens; the title lives in the content header instead.
- Icon: the header first used an SF Symbol, then (user request) the existing asset `FHLLOGO` (1024px app-icon artwork, also used by `ActiveBackgroundAudio`), 80pt, continuous-corner clip (radius 22.37%) + soft shadow; replaces the old title button image `Icon-App-40x40.png`.

## Verification
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible` succeeded (iPhone 13 mini, iOS 27.0). Run on iOS 27.0 (iPhone 13 mini) and iOS 17.4 (iPhone 15 Pro): home renders; 閱讀 pushes Read; 版本資訊 pushes the release notes with back button "首頁". Not verified: 設定/資料/教學 pushes from the new rows (same `VC…()` initializers as before), the load-failure alert, dark mode, iPad, large Dynamic Type.
