# Help / tutorial ("教學") screens rewritten in SwiftUI

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change, behavior preserved)
- Related logs: 1021k_settings_and_version_info_swiftui.md, 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none (FHLBibleTW has no help screen; FHLCommon untouched)
- Commit: committed as 4.12.4 (release-notes section added to Helps/app_versions.md)

## Goal / why
Third screen of the gradual UIKit -> SwiftUI migration (see 1021j). The user guessed the tutorial screen was not in the storyboard; confirmed:
- Only the home-screen button "教學" (`goHelp` outlet, `Main.storyboard` line ~70 in the VCIndex scene) lives in the storyboard. It stays as is.
- `goHelp()` in `VCIndex.swift` does `pushViewController(VCHelps(), animated: true)`. `VCHelps` and the image pager were pure code in `Helps/`.

## What changed (behavior level)
- `Helps/VCHelps.swift` rewritten:
  - `HelpTopic` (data): `titleTw`, `titleGb`, `imageNames`; `title` picks by `ManagerLangSet.s.curIsGb`. `HelpTopic.all` holds the 9 topics in the old row order: 閱讀/阅读 (01read, 9 images), 譯本切換/译本切换 (02translation, 8), 注釋/注释 (03comment, 8), 譯本比較/译本比较 (04comparetranslations, 7), 串珠 (05textsearchkey, 6), 搜尋/搜寻 (06search, 11), SN (07sn, 23), 有聲聖經/有声圣经 (08audio, 12; `helps_08audio_01c` is deliberately commented out, as before), 有聲文字/有声文字 (09textspeech, 10). Images are in `Assets.xcassets/Helps/<NN_topic>/` and named `helps_<NN><topic>_<page><a|b|c…>`.
  - `HelpsView`: SwiftUI `List` (inset grouped) of one `Button` per topic; `.buttonStyle(.plain)` + `frame(maxWidth: .infinity, alignment: .leading)` + `contentShape(Rectangle())` so the whole row is tappable and the text stays black (a default List Button turns the text blue; `.foregroundStyle(.primary)` alone did not override it). Inline nav title "教學" ("教学" in GB). New compared to the old screen: the nav title and the grouped style (old: plain table, no title).
  - `HelpPagesView`: `TabView` with `.tabViewStyle(.page(indexDisplayMode: .never))` (no page dots, same as the old `UIPageViewController`), each page `Image(name).resizable()` stretched to fill (old: `UIImageView` `scaleToFill`), `.ignoresSafeArea(edges: .bottom)` so the image runs to the screen bottom while its top stays below the nav bar. Horizontal swipe changes page; there is no wrap-around.
  - `VCHelpPages: UIHostingController<HelpPagesView>` (`init(imageNames:)`) and `VCHelps: UIHostingController<HelpsView>` (`init()`), so `VCIndex.goHelp()` is unchanged. A SwiftUI `NavigationLink` cannot be used because the screen is hosted inside the existing `UINavigationController` (no `NavigationStack`); `VCHelps` instead gives `HelpsView` an `onSelect` closure that does `navigationController?.pushViewController(VCHelpPages(...), animated: true)`. The closure is installed after `super.init` (`rootView = ...`, `[weak self]`) because `self` cannot be captured before init completes.
- `Helps/ImagePageViewController.swift` deleted (`git rm`): the old `UIPageViewController` base plus the 9 `ImagePageViewController_XX` subclasses in `VCHelps.swift` were used nowhere else (grep over all three projects, storyboards and xibs). `Helps/` is a file-system-synchronized group, so no pbxproj edit was needed.
- No longer imported in the file: `ZIPFoundation`, `zlib` (they were unused there).
- The old `VCHelps` subclassed FHLCommon's `VCOptionListViaTableViewControllerBase` (-> `VCHalfPresentBase` `UITableViewController`) and used `IjnEvent _onClickRow$`; that base class is untouched and still used by other pickers.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED.
- Ran in the iPhone 13 mini simulator (iOS 27.0): home -> 教學 shows the 9 rows with title "教學", black text; tapping 閱讀 pushes the image pager (first screenshot full width, below the nav bar, to the screen bottom); a left swipe shows the next image; the back button returns to the list.
- NOT verified: the other 8 topics (same code path, only the image name lists differ; a typo in a name would show a blank page, check by paging through each), the GB (簡體) titles (only the TW titles were seen), iOS 17.4 runtime, dark mode (the images are screenshots with white backgrounds; the nav bar area is system colored), Dynamic Type, iPad, no unit tests run.

## Gotchas
- SwiftUI `Button` in a `List` is tinted with the accent color; use `.buttonStyle(.plain)` for neutral rows. Then the tap target shrinks to the text unless the label has a full-width frame and `contentShape`.
- The pager images are stretched (not aspect-fit), as before. Aspect-fit would be nicer if the screenshots differ in aspect from the screen, but that is a visual change and was not requested.

## Open issues / next steps
- Release notes: `## 4.12.4 (2026.10.21d)` added to `Helps/app_versions.md`; `VCIndex` labelVer/labelDate still show the last release (4.11.1).
- Next candidate screens: see 1021j (VCSnDict, VCComment, VCFooter, VCReadHistory, VCTsk), one at a time, asking the user first.
