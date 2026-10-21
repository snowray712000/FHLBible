# Replace deprecated AVAudioSession option allowBluetooth with allowBluetoothHFP

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor
- Related logs: 1021g_cleanup_safe_build_warnings.md
- Cross-project: none
- Commit: uncommitted

## Goal / why
Part of the ongoing build-warning cleanup. The build warned: `'allowBluetooth' was deprecated in iOS 8.0: renamed to 'AVAudioSession.CategoryOptions.allowBluetoothHFP'` at `VCAudioBible/ActiveBackgroundAudio.swift:22`. The maintainer asked to fix only this deprecation (the other deprecations were researched but intentionally left alone, see below).

## Starting state
`activeBackgroundAudio(_:)` (used by the audio Bible players, called once) configured the shared session with
`setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])` then `setActive(isActive)`.

## What changed (behavior level)
The option list is now `[.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP]`. No behavior change: in the iOS SDK header `AVAudioSessionCategoryOptionAllowBluetooth` is marked deprecated with replacement `AllowBluetoothHFP`, both have raw value `0x4`, and `AllowBluetoothHFP` is declared available from iOS 1.0, so no `#available` guard is needed with the 15.0 floor. The option only matters for PlayAndRecord/Record categories; with `.playback` it was already a no-op.

## Design and decisions
- Pure rename; verified from the SDK header (`AVFAudio.framework/Headers/AVAudioSessionTypes.h`), not from documentation prose (Apple's web docs do not state the rename explicitly).
- Researched but deliberately NOT changed (record for future work):
  - `UIButton.contentEdgeInsets` (18 uses: InfoButtonBase, VCParsing, VCRead, ViewSearchFilter, FHLCommon ViewButtons). Replacement is `UIButton.Configuration.contentInsets` (iOS 15+), but assigning a `configuration` overrides legacy `setTitleColor`/font/`titleLabel` styling, so the buttons' look could change. The old property still works on iOS 15+. Left for a deliberate restyle.
  - SF Symbol renames in xib/storyboard: `goforward` -> `arrow.trianglehead.clockwise` (symbol introduced 2024, about iOS 18) and `cursorarrow.rays` -> `pointer.arrow.rays` (2025, about iOS 26; read from `/System/Library/CoreServices/CoreGlyphs.bundle/.../name_availability.plist`). Using the new names would show blank icons on iOS 15–17, so keep the old names.

## Verification
Incremental build of scheme `FHLBible` (`generic/platform=iOS Simulator`, Xcode 27 SDK) succeeded with 0 errors and no warning for `ActiveBackgroundAudio.swift`. Audio playback with Bluetooth devices was not tested on a device; iOS 14 not testable here.
