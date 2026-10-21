# TSK ("串珠", cross references) screen rewritten in SwiftUI, removed from Main.storyboard

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (UI technology change, behavior preserved; first screen taken out of the storyboard)
- Related logs: 1021n_data_screen_swiftui.md, 1021m_helps_screen_swiftui.md, 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none
- Commit: committed as 4.12.6 (release-notes section added to Helps/app_versions.md). Main.storyboard was committed as HEAD's file plus only the two scene removals; the Xcode 27 format rewrite stays uncommitted in the working tree.

## Goal / why
Fifth screen of the UIKit -> SwiftUI migration. Unlike the previous four, `VCTsk` WAS in `Main.storyboard`, so this also shrinks the 36-scene storyboard (suspected cause of slow Interface Builder, see 1021j). Entry point: in Read, tap a verse address on the left of a row -> action sheet (`VCVerseActionPicker`) -> "串珠" -> `OneVerseFunctionsClickFlow._doWhenClickedVerseAddressCell` pushes the Tsk screen.

## What the old screen did (kept)
- Title "串珠 <book> <chap>:<verse>" (book name via `BibleBookNames.getBookName(book, .太)`), body = the cross-reference text of that verse rendered by `ViewDisplayCell` (a non-scrolling UITextView; DText -> attributed string; references drawn blue), inside a scroll view.
- Data: `ReloadDataAutoUseOfflineOrScApi` (offline `comm.db`/`comm_gb.db` if present in `/offline/`, else the FHL SC API with `tpSc = .tsk`) -> `apiFinished$(sender, pData)`. If `sender != nil` it is an error/info message as `[DText]` (prev/next untouched); otherwise `pData.com_text` -> `TskDataStrToDText().main(com_text, addr)` plus `pData.addrNext/addrPrev`. While loading the body shows "取得資料中...".
- Navigation: two right nav-bar arrow buttons (left arrow = previous verse, right arrow = next verse, both always enabled; no-ops while `addrPrev/addrNext` is nil) and one-finger swipe right = previous, swipe left = next (`SwipeHelp`, which also disables the system interactive-pop gestures so a right swipe does not go back).
- Tapping a DText that has `refDescription` (e.g. "Pr 8:22-24") pushes a `VCRead` (non-animated) with `VerseRange(StringToVerseRange().main(ref))` and the current versions `ManagerBibleVersions.s.cur`.

## What changed
- `FHLTools/Tsk/VCTsk.swift` rewritten: 
  - `class VCTsk: UIHostingController<TskView>`, `init(addr: DAddress)` (replaces `setInitData` + storyboard instantiation; the addr is passed because e.g. "19,27" is shown as "太2:19,27"). Root view is created with a no-op closure and replaced after `super.init` with `onTapRef` that pushes VCRead (`[weak self]`).
  - `@Observable TskModel`: `addr`, `dtexts`, `generation` (bumped on every `dtexts` change), `addrNext/addrPrev`, `title`, `goNext()/goPrev()`, `reload()`. `reload()` sets the loading text, starts the reload, and applies results on the main queue. NEW: a `requestId` (`@ObservationIgnored`) discards stale responses when the user changes verse quickly (the old code could show an older verse's data under the new title).
  - `TskView`: `ScrollView { DTextContentView }`, inline `.navigationTitle(model.title)`, `.toolbar` trailing group with `arrow.left` (prev) then `arrow.right` (next) buttons (same visual order as the storyboard, whose `rightBarButtonItems` were [Next, Prev]).
  - `DTextContentView: UIViewRepresentable` wrapping the existing `ViewDisplayCell` (not modified): `set(dtexts:isVisibleSn: false, isSwitchOn: false, isSwitchVisible: false)` only when `generation` changed; `onClicked$` forwards only DTexts with `refDescription != nil`; `sizeThatFits` returns (proposed width, `systemLayoutSizeFitting` height) because the text view is not scrollable, so its height comes from content.
  - Swipes: `SwipeHelp` is attached to the hosting controller's view exactly as before (`viewDidLoad` / `viewWillAppear` / `viewWillDisappear`); a SwiftUI `DragGesture` was not used because it cannot suppress the system back swipe.
- Opening VCRead: the old code used `self.gVCRead()` (`storyboard!.instantiateViewController`). A hosting controller created in code has `storyboard == nil` and would crash, so VCTsk uses `navigationController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)` and instantiates "VCRead".
- Call site: `Read/OneVerseFunctionsClickFlow.swift` now does `push(VCTsk(addr: _addr ?? DAddress(1,1,1)))`. `VCEasyFunctions.swift`: `gVCTsk()` removed (no other users).
- `Main.storyboard`: removed the `VCTsk` scene (`KAf-ug-Ein`, storyboardIdentifier "VCTsk", with its scroll view + ViewDisplayCell + two bar buttons) and an orphan `Navigation Controller` scene (`N7R-MI-MdR`, no identifier, no entry point, only root = VCTsk). 36 -> 34 scenes; verified with `grep` that no id of either scene remains and with an XML parse; the build (ibtool) passes.
- Untouched: `VCTskIReloadData*.swift` (`extension VCTsk { typealias ...; class ReloadDataViaScApi / ReloadDataAutoUseOfflineOrScApi }`, still valid because they extend the class by name), `TskDataStrToDText.swift`, `ViewDisplayCell`, `VCComment` (the sibling screen with the same structure; it is the natural next candidate and can reuse `DTextContentView`).

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED, no new warnings from VCTsk.swift.
- Ran in the simulator: 閱讀 -> tap "創1:1" -> action sheet -> 串珠: title "串珠 創 1:1", full cross-reference text with blue references, two arrow buttons; next arrow -> "串珠 創 1:2" with "取得資料中..." then the (shorter) text with the height shrinking correctly; swipe right -> back to 1:1 and no system back; tapping the blue "Pr 8:22-24" -> pushed VCRead showing 箴 8:22-24; 16:4; ... (the tap is recognized after about 0.5 s because ViewDisplayCell requires its tap to wait for its long-press recognizer to fail, same as before).
- NOT verified: swipe left, the prev arrow button on its own, going back from VCRead to the Tsk screen (the screenshot caught the pop animation), GB (簡體) titles, offline `comm.db` path (the run used the API path), error message path, iOS 17.4 runtime, dark mode, Dynamic Type, iPad, rapid verse changes (stale-response guard), no unit tests run.

## Gotchas
- A code-created `UIViewController` has `storyboard == nil`; helpers like `gVCRead()` (`storyboard!`) crash from it. Use `navigationController?.storyboard`.
- `UIViewRepresentable` with a non-scrolling UITextView host: implement `sizeThatFits(_:uiView:context:)` (iOS 16+) or it collapses to zero/intrinsic height; only call `set(...)` when the data really changed, or every SwiftUI update re-assigns the attributed text.
- Removing a storyboard scene by hand: also remove any scene whose segue points to it (here the orphan nav controller), and the `<!--title-->` comment line before the scene.
- The working tree's `Main.storyboard` also contains Xcode 27's own format rewrite (toolsVersion 25098, uncommitted since before this task); the scene removal sits on top of it. When committing, either accept both or build the commit from HEAD's file plus only the two scene removals.

## Open issues / next steps
- Release notes: `## 4.12.6 (2026.10.21f)` added to `Helps/app_versions.md`; `VCIndex` labelVer/labelDate still show the last release (4.11.1).
- `VCComment` is the same shape (reuses VCTsk's reload types) and could follow, reusing `DTextContentView`.
- The arrows are never disabled when there is no previous/next verse (same as the old screen).
