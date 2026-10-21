# IjnRegex Sendable, extension `open` -> `public`, and release notes 4.12.2

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor
- Related logs: 1021g_cleanup_safe_build_warnings.md, 1021h_audio_session_allow_bluetooth_hfp.md, 1021e_version_info_screen.md
- Cross-project: ../../../../FHLCommon/ai-log/2026/s4/1021e_ijnregex_unchecked_sendable.md
- Commit: uncommitted

## Goal / why
Last two code-level warning categories the maintainer approved, then close the warning cleanup as development version 4.12.2.

## What changed (behavior level)
1. `Tools/ijnRegex.swift`: `open class IjnRegex : NSRegularExpression` -> `..., @unchecked Sendable` (compiler asked to restate the inherited conformance). Compile-time only. See the FHLCommon log for the reasoning.
2. `EasySQLite/path_UserDomain.swift`: in `extension FileManager`, `makeSureDirExistAtDocumentUserDomain(dirName:)` and `getPathAtDocumentUserDomain(pathRelative:)` changed from `open func` to `public func`. Methods declared in an extension can never be overridden, so `open` was meaningless; the warning says it becomes an error in a future Swift language mode. Call sites unchanged (this is the app target, not a framework, so visibility to callers is unaffected).
3. `Helps/app_versions.md`: added section `## 4.12.2 (2026.10.21b)` with one item, "✨ 優化: 內部整理，清除程式編譯時累積的警告（不影響使用）". Follows the 4.12.* convention in 1021e (even middle number = in-development accumulation; the next release 4.13.1 will fold these in).

## Design and decisions
- "4.12.2" here means the release-notes section only. `MARKETING_VERSION` (still 4.11), `labelVer`/`labelDate` in `VCIndex` and the pbxproj were NOT touched, per the rule against editing release settings; the in-app table marks the first non-To-Do section (now 4.12.2) as "最新" although it is unreleased (same side effect as in 1021e).
- Stopping point of the warning cleanup. Remaining warnings (85 distinct lines in FHLBible, 15 in FHLBibleTW), all deliberately left:
  - storyboard/xib (Xcode GUI work): Plain Style in Navigation Item (21), Navigation Controller unreachable (16), Tinted/Gray Button Style before iOS 15 (18), Data Detection+Editable (1), storyboard older than deployment target (1).
  - `contentEdgeInsets` deprecated in iOS 15 (18; replacement UIButton.Configuration would change button styling) and SF Symbol renames (6; new names need iOS 18/26) - see 1021h.
  - `VCData.swift` "will never be executed" (2): `let isDebug = true` + `if isDebug == false { urls.append(unzip) }`; the unzip URL is never appended. May be an intentional debug toggle or a latent bug; maintainer should decide.
  - `appintentsmetadataprocessor` "no AppIntents.framework" (2): Xcode tool noise, ignorable.

## Verification
Clean builds of schemes `FHLBible` and `FHLBibleTW` (generic iOS Simulator, Xcode 27 SDK): both BUILD SUCCEEDED, 0 errors; Sendable and "cannot be overridden" warnings gone; `app_versions.md` with the 4.12.2 section is present in the built bundle. Not tested: unit tests, on-screen look of the version table, iOS 14.
