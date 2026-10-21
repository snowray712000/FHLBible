# Deployment target written as literal 17.0 in all three pbxproj files

- Date: 2026-10-21
- Project: FHLBible
- Type: config
- Related logs: 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: same change in the other two projects (FHLBible 1021l, FHLBibleTW 1021g, FHLCommon 1021g)
- Commit: see `git log` (message mentions 17.0)

## What changed
The maintainer confirmed that the minimum iOS is definitively 17.0. In `FHLBible.xcodeproj/project.pbxproj` every `IPHONEOS_DEPLOYMENT_TARGET` (project level, app/framework, Tests, UITests; 8 occurrences) was rewritten to the literal `17.0` with one `sed` (it replaced `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`). The pbxproj was then committed together with Xcode 27's own pending changes in the same file (`LastUpgradeCheck = 2700`, `STRING_CATALOG_GENERATE_SYMBOLS`, `ENABLE_USER_SCRIPT_SANDBOXING`, `DEVELOPMENT_TEAM` moved, ...), which the maintainer asked to commit.

## Why
Before this, HEAD still said 14.0/15.0 while the docs said 17.0, and the working tree mixed `17.0` with `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` (a value that follows the Xcode version, so it would silently change with Xcode 28). A literal value is stable and matches the documented policy.

## Verification
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme X -destination 'platform=iOS Simulator,id=<iPhone 13 mini, iOS 27.0>' build` for FHLBible, FHLBibleTW and FHLCommon: all BUILD SUCCEEDED. Not run on an iOS 17.4 simulator; no tests run.

## Notes
This is the one time the maintainer explicitly authorised editing deployment targets in pbxproj. The standing rule is unchanged: do not edit them without asking.
