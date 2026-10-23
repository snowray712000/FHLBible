# Home screen becomes a real UIHostingController root; app no longer launches from Main.storyboard

- Date: 2026-10-23
- Project: FHLBible
- Type: refactor (launch configuration)
- Supersedes: the "child UIHostingController inside a storyboard VCIndex" decision in 1023c_index_screen_swiftui.md (the screen design in 1023c is unchanged)
- Related logs: 1023c_index_screen_swiftui.md
- Cross-project: none (FHLBibleTW has its own Info.plist/storyboard, untouched)
- Commit: not committed (user did not ask). Approved by the user in chat before touching Info.plist.

## Why
Making `VCIndex` a thin UIKit shell + child hosting controller was only a workaround for "Main.storyboard owns the initial navigation controller". The idiomatic setup is `VCIndex: UIHostingController<HomeView>` as the navigation root, so SwiftUI modifiers (`.navigationTitle`, `.toolbar`) on the home screen work directly.

## Changes
- `Info.plist`: removed `UISceneStoryboardFile` (scene configuration "Default Configuration") and the legacy `UIMainStoryboardFile`; `UILaunchStoryboardName` changed `Main` -> `LaunchScreen`. NOTE: before this, the launch screen was also `Main.storyboard` (its initial view controller, i.e. the old home screen was rendered statically as the launch image). `Base.lproj/LaunchScreen.storyboard` already existed in the project (blank, system background) and is now used.
- `SceneDelegate.scene(_:willConnectTo:options:)`: with no storyboard UIKit does not make a window, so it creates `UIWindow(windowScene:)`, `rootViewController = UINavigationController(rootViewController: VCIndex())`, stores it in `self.window`, `makeKeyAndVisible()`.
- `VCIndex`: now `UIHostingController<HomeView>` (same init pattern as `VCRead`: model created before `super.init`, `rootView` re-assigned after `super.init` with actions that capture `self`). `labelVer` / `labelDate` are `private static let` (still the place to edit when releasing). `viewDidLoad` keeps the `AutoLoadDUiabv` setup and `navigationItem.backButtonTitle = "首頁"`.
- `Main.storyboard`: removed the Index scene (`VCIndex`) and the initial `UINavigationController` scene, and the `initialViewController` attribute. Remaining scenes: `VCSnActionPicker`, `VCVerseActionPicker`, `VCWhenLongPress` (+ its navigation controller). These are still instantiated by identifier via `gEasyGetViewCtrlFromXibCore`, which already falls back to `UIStoryboard(name: "Main", bundle: nil)` when `self.storyboard` and `navigationController?.storyboard` are nil (true now for every screen).
- `zh-Hans/zh-Hant Main.strings` still contain keys for object ids of long-gone scenes; harmless, left alone.

## Verification
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible` succeeded (iPhone 13 mini, iOS 27.0). Built app's Info.plist has `UILaunchStoryboardName = LaunchScreen` and no `UIMainStoryboardFile`. Cold launch on iOS 27.0 and iOS 17.4 shows the new home; on 27.0 also pushed 設定, 資料, 教學 (back button "首頁") and 閱讀 (data loaded), and opened the verse action picker (`VCVerseActionPicker`, still from the storyboard) from Read. Not verified: iPad, landscape, dark mode, launch-screen appearance (not looked at; it is a blank system-background screen).
