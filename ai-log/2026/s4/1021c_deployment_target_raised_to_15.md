# Deployment target raised to 15.0 by the maintainer after Xcode 27 update

- Date: 2026-10-21
- Project: FHLBible
- Type: config
- Supersedes: 2026/s4/1021b_xcode27_deployment_target_warning.md (in part)
- Related logs: 2026/s4/1021a_baseline_project_overview.md
- Cross-project: FHLCommon `ai-log/2026/s4/1021b_deployment_target_raised_to_15.md`, FHLBibleTW `ai-log/2026/s4/1021b_deployment_target_changed_by_xcode27.md`
- Commit: uncommitted (all pbxproj changes below are the maintainer's / Xcode's, not AI's)

## Goal / why
After updating to Xcode 27.0 the projects could neither build nor run with an iOS 14.0 deployment target (simulator SDK supports 15.0 to 27.0.x only). The maintainer manually set the deployment target to 15.0 for FHLBible and FHLCommon, and then ran the app successfully for the first time since the Xcode update. The product principle is unchanged: keep the minimum as low as the toolchain allows and do not chase the newest iOS APIs.

## Starting state
- Committed: all targets 14.0 (FHLBible app target marketing version 4.9, FHLBibleTW 2.1).
- Toolchain: Xcode 27.0 (27A266a), SDK 27.0. Xcode reports `RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

## What changed (observed working tree, effective values via `xcodebuild -showBuildSettings -target <T> -configuration {Debug,Release} -sdk iphonesimulator`)
| Project | Effective `IPHONEOS_DEPLOYMENT_TARGET` | How |
|---|---|---|
| FHLBible (app target) | 15.0 | set manually; project-level and Tests targets still literal 14.0. An earlier-seen Release-only `[arch=*] = 14.0` override is no longer present. |
| FHLCommon (framework target) | 15.0 | set manually; project-level still literal 14.0 |
| FHLBibleTW (app and Tests) | 17.0 | Xcode 27 "update to recommended settings" rewrote them to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`; `LastUpgradeCheck` 1430 → 2700; also added `ENABLE_USER_SCRIPT_SANDBOXING`, `STRING_CATALOG_GENERATE_SYMBOLS`, `ONLY_ACTIVE_ARCH`; removed `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` |

## Design and decisions
- Maintainer decision: 15.0 for FHLBible and FHLCommon, because 14.0 cannot be built/run with Xcode 27.
- 17.0 for FHLBibleTW comes from Xcode's recommendation, not from a stated decision. It appears unintended. An app cannot target a lower OS than the framework it embeds, so FHLBibleTW must be at least 15.0 (FHLCommon's target).
- Rules recorded in all CLAUDE.md files: AI must not change `IPHONEOS_DEPLOYMENT_TARGET` (up or down), must not hand-edit pbxproj or accept Xcode's recommended-settings update, must not set a target to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`, and must only use APIs available at the current floor (15.0), with `#available` plus fallback for anything newer. iOS 15-only APIs are technically allowed now but should not be introduced without need.

## Key files / types / functions
- `FHLBible/FHLBible.xcodeproj/project.pbxproj`, `FHLCommon/FHLCommon.xcodeproj/project.pbxproj`, `FHLBibleTW/FHLBibleTW.xcodeproj/project.pbxproj`.

## Contracts and algorithms
n/a

## Gotchas
- iOS 14 can no longer be tested on a simulator with this Xcode; practical minimum for verification is iOS 15.
- Xcode's "recommended settings" update silently bumps deployment targets. Review pbxproj diffs for `RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET` after any Xcode upgrade.
- FHLBibleTW working tree contains other uncommitted changes (storyboard, `VCRead.swift`, `BibleText2DText.swift`), unrelated to this entry.

## Verification
Read-only commands only (`git diff`, `xcodebuild -showBuildSettings`). No build by AI. The maintainer reports a successful run of the project after the change (which project/simulator not specified).

## Open issues / next steps
- Maintainer to confirm the intended FHLBibleTW target (probably 15.0, matching FHLCommon) and whether to keep project-level 14.0 literals.
- Existing logs `1021a_*` in each project still say 14.0; this log supersedes that part.
