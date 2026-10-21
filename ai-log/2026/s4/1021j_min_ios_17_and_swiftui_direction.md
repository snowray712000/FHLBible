# Decision: minimum iOS is 17.0; new simple screens are written in SwiftUI

- Date: 2026-10-21
- Project: FHLBible
- Type: decision / config (docs only, no project-file change)
- Related logs: 1021c_deployment_target_raised_to_15.md, 1021f_fix_optional_map_at_ios17_target.md, 1021k_settings_and_version_info_swiftui.md
- Cross-project: FHLBibleTW 1021f_min_ios_17_policy.md, FHLCommon 1021f_min_ios_17_policy.md (same policy text); workspace `CLAUDE.md` (not a git repo)
- Commit: uncommitted

## Goal / why
The maintainer asked whether to move the UIKit/Storyboard UI to SwiftUI piece by piece, because (a) the screens are simple and look alike (a title bar plus a few controls), (b) `Main.storyboard` is a single large file that is slow to open and awkward to edit in Xcode, and (c) the maintainer now treats iOS 17.0 as the minimum. This log records the assessment, the policy change in the CLAUDE.md files, and what was deliberately left in UIKit.

## Findings (read-only investigation)
- `FHLBible/Base.lproj/Main.storyboard`: 2018 lines, 36 scenes = about 19 real view-controller scenes + 17 `UINavigationController` wrappers; 17 segues; 224 constraints, 54 outlets, 55 actions; 51 buttons, 23 labels, 9 sliders, 3 table views. `FHLBibleTW`'s `Main.storyboard` is 298 lines / about 4 scenes.
- About 13 of the scenes are trivial (1-5 buttons or one table): VCSnDict, VCComment, VCFooter, VCSearching, VCTsk, VCReadHistory, picker lists... Medium: VCAudioTextSpeed (16 labels, 68 constraints), VCAudioBible (397 lines), VCAudioTextBible, VCWhenLongPress, VCVersionsPicker (xib 425 lines).
- Several screens were already pure code and never in the storyboard: `VCSettings`, `VCData`, `VCVersionInfo`, `VCHelps`.
- Storyboard scenes are instantiated lazily per scene, so "runtime loading is slow" is not explained by file size. The maintainer later clarified the slowness is at **development time** (opening/editing the storyboard in Xcode). Likely cause (NOT measured): 7 `@IBDesignable` views (`ViewDisplayTable2`, `ViewDisplayCell`, `ViewDisplayRow`, `ViewSearchFilter`, `ViewSearching`, `ViewSNDictCell`, `ViewParsingDict`), two of which (`ViewDisplayTable2`, `ViewDisplayCell`) are used inside `Main.storyboard`; Interface Builder must compile the module and render them. Cheap experiments, not done yet: remove `@IBDesignable`; split the storyboard with Storyboard References.
- The Read screen displays rich text in a `UITextView` and finds the tapped/long-pressed character itself (`FindIndexOfCharInTextView`, `FindWordInTextViewWhenTapGesture`), to classify it as Strong number / reference / title. SwiftUI `Text` cannot do per-word long press, so `VCRead`, `ViewDisplayTable2`, `ViewDisplayCell` stay UIKit.

## Effective deployment target (measured)
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme X -showBuildSettings` gives `IPHONEOS_DEPLOYMENT_TARGET = 17.0` for FHLBible, FHLBibleTW and FHLCommon. The pbxproj text is inconsistent (some configs `17.0`, some `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` which is 17.0 under Xcode 27, FHLCommon still has `15.0` strings in some configs). Nothing in any pbxproj was edited in this task; whether to normalise the text is the maintainer's call.
Simulators available in this environment: iOS 17.4 (iPhone 15 family) and iOS 27.0 (iPhone 13 mini, 17, 17e...).

## Policy written into CLAUDE.md (workspace, FHLBible, FHLBibleTW, FHLCommon)
- Minimum iOS 17.0. APIs up to iOS 17 may be used freely (SwiftUI, `NavigationStack`, `@Observable`, SwiftData); iOS 18+ APIs need `if #available` with a fallback. Still "do not chase the newest iOS".
- Still forbidden for AI: editing `IPHONEOS_DEPLOYMENT_TARGET`, hand-editing pbxproj, accepting "Update to recommended settings"; ask the maintainer first.
- UI direction: UIKit remains the base. Simple screens are rewritten one at a time in SwiftUI and pushed with `UIHostingController` into the existing `UINavigationController`; no new storyboard scenes. Existing working UIKit / `IjnEvent` code is not rewritten proactively; one screen at a time, ask first. async/await and new third-party packages still need approval.
- Rejected / deferred: converting the whole storyboard in one go; converting `VCRead` and its table; bridging `IjnEvent` to `@Observable` globally (only done per screen when needed; the first two screens have no events to bridge).

## Open issues / next steps
- Try removing `@IBDesignable` (7 views) and time opening `Main.storyboard`; if still slow, split it with Storyboard References.
- Next SwiftUI candidates: VCSnDict, VCComment, VCFooter, VCReadHistory, VCTsk (simple); then the audio screens.
- Index header of this project said "Minimum iOS 14.0" and has been updated to 17.0.
