# Xcode 27 warning: iOS 14.0 deployment target outside supported range

- Date: 2026-10-21
- Project: FHLBible
- Type: investigation
- Superseded by: 2026/s4/1021c_deployment_target_raised_to_15.md (the "unchanged, still 14.0" claims for FHLBibleTW/FHLCommon and the `[arch=*]` observation below are outdated)
- Related logs: 2026/s4/1021a_baseline_project_overview.md
- Cross-project: none (FHLBibleTW and FHLCommon are unchanged and still at 14.0, but will show the same warning under this Xcode)
- Commit: uncommitted (the pbxproj change described below is the maintainer's uncommitted work, not made by AI)

## Goal / why
The maintainer pasted an Xcode warning for `FHLBible.xcodeproj`: "The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 14.0, but the range of supported deployment target versions is 15.0 to 27.0.x". The product intentionally supports iOS 14 so that old phones that cannot update iOS can still use the app. This entry records the facts so later AI sessions do not "fix" the warning by changing the deployment target.

## Starting state
- Installed toolchain: Xcode 27.0 (build 27A266a), iphoneos / iphonesimulator SDK 27.0.
- Committed state of `FHLBible.xcodeproj/project.pbxproj`: app target `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (Debug and Release), `MARKETING_VERSION = 4.9`.
- FHLBibleTW and FHLCommon: 14.0 everywhere (FHLBibleTW Tests target is 16.4).

## What changed (behavior level)
No code was changed by AI. Observed uncommitted working-tree changes in FHLBible's pbxproj (made by the maintainer / Xcode):
- App target Debug and Release: `IPHONEOS_DEPLOYMENT_TARGET` 14.0 → 15.0.
- App target Release only: added `"IPHONEOS_DEPLOYMENT_TARGET[arch=*]" = 14.0`, apparently an override so that release builds can still target 14.0 while the base value satisfies Xcode 27 (this is an inference; not confirmed with the maintainer).
- `MARKETING_VERSION` 4.9 → 4.11 on the app target (other docs quote 4.11, the working-tree value).
- Project-level and Tests targets remain 14.0.

## Design and decisions
- Product decision (maintainer): keep supporting iOS 14. Do not raise the minimum to follow the toolchain.
- AI rule recorded in CLAUDE.md files: the warning is known; do not change `IPHONEOS_DEPLOYMENT_TARGET` up or down and do not hand-edit pbxproj to silence it; ask the maintainer first. Do not revert or "correct" the maintainer's uncommitted change.
- Consequence: iOS 14 behavior cannot be tested on a simulator with Xcode 27 (simulator deployment range starts at 15.0). iOS 14 compatibility must be ensured by checking API availability and `#available` fallbacks, and reports must say "not tested on iOS 14".

## Key files / types / functions
- `FHLBible.xcodeproj/project.pbxproj` (build configurations of target FHLBible, around lines 1869–1915).

## Contracts and algorithms
n/a

## Gotchas
- `xcodebuild -project FHLBible.xcodeproj -target FHLBible -configuration {Debug,Release} -sdk {iphoneos,iphonesimulator} -showBuildSettings` reports `IPHONEOS_DEPLOYMENT_TARGET = 15.0` for all four combinations, including Release/iphoneos. So the `[arch=*] = 14.0` override is not visible in that output. Whether it takes effect in a real build (minimum OS recorded in the binary / `LC_BUILD_VERSION minos`) was NOT verified.
- A warning about deployment target is a toolchain statement about the simulator SDK; it does not by itself mean device builds of the app are limited to iOS 15+.

## Verification
Ran only read-only commands: `xcodebuild -version`, `xcrun --show-sdk-version`, `git diff` on the pbxproj, `-showBuildSettings`. No build was performed.

## Open issues / next steps
- Verify the real minimum OS of a Release device build (for example inspect the built binary's minos) to confirm the app still supports iOS 14.
- Decide whether to apply the same approach to FHLBibleTW and FHLCommon (maintainer's call).
