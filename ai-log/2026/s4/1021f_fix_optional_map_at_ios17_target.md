# Fix: `Bool?` vs `[Bool]` compile error in VCSearchResult after the deployment target became 17.0

- Date: 2026-10-21
- Project: FHLBible
- Type: fix
- Related logs: 1021c_deployment_target_raised_to_15.md
- Cross-project: none
- Commit: uncommitted

## Goal / why
After Xcode 27 re-applied "recommended settings" (all three projects' deployment targets became `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` = 17.0, see FHLBibleTW log 1021e addendum), FHLBible failed to compile: `Search/VCSearchResult.swift:193:69 Cannot convert value of type 'Bool?' to expected argument type '[Bool]'`. The file had not been edited; it compiled at 15.0.

## Root cause
`_vers` is declared `var _vers: [String]!` (implicitly unwrapped). In `_drawDataView`, `let isOpenHanBibleTCs = _vers.map({["ttvh","thv12h","ttvhl2021"].contains($0)})` was ambiguous:
- Array path: `[String]!` force-unwrapped, `Array.map`, `$0: String`, `[String].contains(String)` → `[Bool]` (intended).
- Optional path: `Optional<[String]>.map`, `$0: [String]`, `[String].contains(some Collection)` → `Bool?`.
The second `contains` is the `_StringProcessing` collection-containment overload, available only from iOS 16. At a 15.0 target it was unavailable so the Array path was the only valid one; at a 17.0 target both type-check and Swift prefers the non-unwrapping Optional path, giving `Bool?`, which then mismatches `setInitData(... _ isFontNameOpenHanBibleTCs: [Bool] ...)` (`ViewDisplayTable2.setInitData`).

## What changed
`VCSearchResult._drawDataView`: `let isOpenHanBibleTCs: [Bool] = _vers!.map({...})` (explicit `!` and explicit type, plus a comment). Behavior unchanged; valid at 15.0 and at 17.0.

## Gotchas
- Raising the deployment target can change overload resolution, not only API availability. Any `x.map { [..].contains($0) }` on an implicitly-unwrapped optional array is a candidate for the same problem; the only other `_vers.map` in this file (`return _vers.map({DText(...)})`) is unaffected because its closure has no overload ambiguity.
- Not a reason to change the target: the maintainer's policy is still 15.0 (see 1021c); this fix works at both.

## Verification
`xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible`, iPhone 13 mini simulator (iOS 27.0), with the projects' current (Xcode-rewritten, 17.0) deployment settings: BUILD SUCCEEDED. Not re-built at 15.0 and not run.
