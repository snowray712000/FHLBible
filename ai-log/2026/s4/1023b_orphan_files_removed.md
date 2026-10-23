# Orphan UIKit files of the migrated screens removed from the project

- Date: 2026-10-23
- Project: FHLBible
- Type: refactor (cleanup)
- Related logs: 1022b_search_screens_swiftui.md, 1022c_parsing_screen_swiftui.md, 1023a_versions_picker_screen_swiftui.md (all three said "remove in Xcode"; this log records that it was done)
- Cross-project: none
- Commit: amended into the 1023a commit.

## What was removed
The maintainer removed these in Xcode (references gone from `project.pbxproj`); leftovers were deleted from disk here:
- Parsing: `FHLTools/SNParsing/{ViewParsing,ViewParsingWord,ViewParsingDict,ViewSNDictCell}.{swift,xib}` (the comment-only swift stubs and their 4 xibs). A stray empty-named `FHLTools/SNParsing/.swift` (the ViewParsing stub, renamed by accident during removal, not in pbxproj) was deleted too.
- Search: `Search/ViewSearching.xib`, `Search/ViewSearchFilter.xib` (the swift files of the same names stay: they hold the new SwiftUI `SearchingView` / `SearchFilterBar`).
- Translation picker: `VCVersionsPicker/ViewVersionsPicker.swift`, `Base.lproj/ViewVersionsPicker.xib`, `{zh-Hans,zh-Hant,en}.lproj/ViewVersionsPicker.strings`.
- `FHLTools/SNDict/VCSnDictMore.swift` (comment-only stub from 1021y) was removed afterwards by the maintainer in Xcode; its pbxproj references went into the same commit.

## Commit hygiene
`project.pbxproj` was staged hunk by hunk: only the file-reference removals; the two local `DEVELOPMENT_TEAM = VYVKTHK4E5;` additions (maintainer's signing team) were deliberately left unstaged.

## Verification
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible` for iPhone 13 mini (iOS 27.0): see the build result reported in the conversation; app not re-run after the cleanup.
