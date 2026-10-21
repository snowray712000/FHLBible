# Clear the safest categories of build warnings

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor
- Related logs: none
- Cross-project: ../../../../FHLCommon/ai-log/2026/s4/1021d_cleanup_self_import_warnings.md
- Commit: uncommitted

## Goal / why
A clean build of scheme `FHLBible` (Xcode 27, `generic/platform=iOS Simulator`) produced ~182 distinct warning lines accumulated over time. The maintainer asked to clear only the safest categories, one category at a time, with no behavior change: never-mutated, never-used, duplicate import, duplicate parameter name.

## Starting state (warning inventory)
Besides the four target categories, the log also contained (left untouched, still present): storyboard/xib warnings (Plain Style in Navigation Item, unreachable Navigation Controller, Tinted/Gray Button Style), `contentEdgeInsets` deprecated in iOS 15 (18), SF Symbol renames (`goforward`, `cursorarrow.rays`), `IjnRegex` must restate `@unchecked Sendable` (FHLBible + FHLCommon copies), `path_UserDomain.swift` extension methods not overridable, `AVAudioSession allowBluetooth` deprecated, `VCData.swift:523` "will never be executed".

## What changed (behavior level)
No runtime behavior change.
1. Duplicate import: 16 self-imports removed, all in FHLCommon (see Cross-project log). None existed in FHLBible itself.
2. Duplicate parameter name: `OneVerseFunctionsClickFlow.init(vc:addrThisPageFirst:vers vers:)` -> `vers:`. The external label is unchanged, so call sites are unaffected.
3. Never mutated (`var` -> `let`), 12 places: `ScrollViewCaptureImage.swift` (`sz`), `BibleGetterViaSQLiteFile.swift` (`r1..r4` in both `bhs_to_utf8_umscode` and `fhlwh_to_utf8_gcode`), `ViewDisplayTable2.swift` (`dtextsData`, `r1a`), `VCWhenLongPress.swift` (`isVerShow`).
4. Never used:
   - `ScrollViewCaptureImage.swift`: deleted `oldDelegate`, `savedContentOffset`, `cy`, `fr` (pure property reads). Note `oldDelegate`/`savedContentOffset` were only referenced by commented-out code that restored the scroll view's delegate/offset; `capture()` currently sets `delegate = EventForScrollView.shared` and never restores it. That is pre-existing behavior and was not changed.
   - `ViewDisplayTable2.swift`: deleted `r3 = self.widthRatio` and `rowOfTable = a2.value`.
   - `VCRead.swift` (long-press callback guard): `let dtexts = pData.dtext, let addrsCur = self._addrsCur` became `pData.dtext != nil, self._addrsCur != nil` so the early-return conditions are identical.
   - `VCData.swift` (`#if DEBUG`): `let dir = ...getPathAtDocumentUserDomain` is intentionally kept for reading in the debugger; added `_ = dir` to silence the warning.

## Design and decisions
- Edits were applied by exact file:line from the compiler output, verifying the line text first.
- Rejected for now: `contentEdgeInsets` -> `UIButton.Configuration` (iOS 15 API, CLAUDE.md says avoid unless needed), SF Symbol renames (new names may not exist on iOS 15), storyboard/xib edits (should be done in Xcode, not by hand).

## Verification
Clean builds of `FHLBible` and `FHLBibleTW` succeeded, 0 errors. Distinct warning lines in FHLBible build: 182 -> 93; none of the four target categories remain. Not run: unit tests, device/simulator launch, iOS 14.

## Pitfalls / notes for future AI
- Working tree already had unrelated uncommitted changes (`OneVerseFunctionsClickFlow.swift`, `VCSearchResult.swift`, `ai-log/index.md`, pbxproj, xcuserdata); the edit to `OneVerseFunctionsClickFlow.swift` is one line on top of those.
- Each warning appears 2–3 times in raw xcodebuild output (diagnostic, caret echo, "in target" echo); dedupe with `sort -u` before counting.
