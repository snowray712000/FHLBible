# "有聲文字速度" (text-to-speech speed) screen rewritten in SwiftUI, with a small redesign

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor + UX redesign (storage and speech behavior unchanged); second screen taken out of the storyboard
- Related logs: 1021o_tsk_screen_swiftui.md, 1021n_data_screen_swiftui.md
- Cross-project: none
- Commit: committed as 4.12.7 (release-notes section added to Helps/app_versions.md). Main.storyboard was committed as HEAD's file plus only the two scene removals; the Xcode 27 format rewrite stays uncommitted in the working tree.

## Goal / why
Next screen of the UIKit -> SwiftUI migration. The maintainer allowed a different design where it fits iOS guidance better. Entry: Read -> "···" menu -> 有聲文字 (`VCAudioTextBible`) -> the speed button (`clickSpeed`) -> this screen. `VCAudioTextBible` itself is still UIKit/storyboard.

## What the old screen did
- A storyboard scene (`VCAudioTextSpeed`, with an orphan `UINavigationController` scene whose root was it): 8 rows, each = a language label, a `UISlider` (0...7, non-continuous) and an "x1.00" label; a long info button at the bottom ("若點擊無聲音，是你的手機不支援此語言語音。若全部都沒聲音，那就是工程師的Bug了。").
- Slider position n means speed `(n+1)*0.25` (0.25 ... 2.00). Releasing the slider saved the speed and played a sample sentence in that language at that speed. The sliders were not stepped: the stored position stayed fractional and `Int(value)` truncated it. A tap on the left/right half of a slider moved it -1/+1 step (a hidden gesture) and also played the sample. `deinit` stopped any ongoing speech.
- Row order is fixed and shared with `TTSEngineGetter.ttsArray` and the persisted array: 0 中文 (zh-TW, or zh-CN when the app language is GB), 1 English (en-US), 2 Hebrew (he-IL), 3 Greek (el-GR), 4 にほんご (ja-JP), 5 한국어 (ko-KR), 6 Tiếng Việt (vi-VN), 7 ру́сский язы́к (ru-RU). Sample sentences: `TTSEngineSamples`.
- Persistence: `ManagerAudioTextSpeed.s.curSpeed` / `updateSpeed([Float])` (UserDefaults key `AudioTextSpeed`, array of "%.2f" strings, padded with 1.0 to 8 entries). The reader of these speeds is `AudioTextBibleTTSCore.getSpeedWhereTTSEngine` (`utterance.rate = 0.5 * speed`). Unchanged.

## What changed
- `VCAudioTextBible/VCAudioTextSpeed.swift` rewritten:
  - `class VCAudioTextSpeed: UIHostingController<AudioTextSpeedView>` with `init()`; the caller `VCAudioTextBible.clickSpeed` now does `VCAudioTextSpeed()` and pushes it (`gVCAudioTextSpeed()` in `VCEasyFunctions.swift` removed, no other users).
  - `@Observable AudioTextSpeedModel`: `langs` (8 fixed rows, names shown verbatim in each language), `steps: [Double]` (slider positions 0...7), conversions `step2speed`, `speed2step` (rounds and clamps, so a stored non-multiple of 0.25 cannot break the slider), `commit(idx)` (read-modify-write of the whole 8-entry array through `ManagerAudioTextSpeed`, then play the sample), `playSample(idx)` (same engine / sample / `rate = 0.5 * speed` as before; stops a sample that is still speaking first), `deinit` stops speech.
  - `AudioTextSpeedView`: `List` with one `Section` of 8 rows and the info sentence as the section FOOTER (the standard place for explanatory text; it replaces the long button). Row = `VStack { HStack { language name, Spacer, "x1.50" (monospaced digits, secondary), speaker button }, Slider(0...7, step: 1) }`. Inline title "有聲文字速度" (same localized string as before).
- Redesign decisions (differences from the old screen, all deliberate):
  - Slider is stepped (`step: 1`): it snaps to the 8 valid speeds instead of floating between them; the value label updates live while dragging, saving and the audition happen only on release (`onEditingChanged(false)`), matching the old `isContinuous = false`.
  - The hidden "tap left/right half of the slider" gesture is replaced by an explicit speaker button per row (`speaker.wave.2.fill`, accessibility label "試聽") that plays the sample at the current speed without changing it.
  - Accessibility: each slider has label = language name and value = "x1.50"; the speaker button has a label; the list uses system sizing so long names / larger Dynamic Type wrap instead of being cut by fixed-width labels (the old labels were 100 / 45 pt wide).
  - The info text keeps the same localization key as before; "試聽" is a new key (no .strings entry, falls back to the key).
- `Main.storyboard`: removed the `VCAudioTextSpeed` scene (`U8J-px-SKF`, with 8 sliders, 16 labels, the info button and 16 outlet-collection connections) and the orphan navigation controller scene (`ta3-qm-mQD`, no incoming reference). 34 -> 32 scenes (committed file: HEAD's 34-scene file minus these two scenes; the working-tree file has the same removals plus Xcode's format rewrite).

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED, no warnings from VCAudioTextSpeed.swift.
- Ran in the simulator: 閱讀 -> ··· -> 有聲文字 -> speed button: the new screen shows the 8 languages with x1.00 sliders, speaker buttons and the footer sentence. Dragging 中文 shows x1.50 live and it settled at x1.75; going back and opening the screen again showed x1.75 (persisted); the speaker button did not crash; the slider was dragged back toward x1.00.
- NOT verified: actual audio (the simulator output was not heard, so voices for each language and the "no sound if the voice is missing" case are unchecked), that the audition plays only on release, the stored value after dragging back, GB (簡體) 中文 voice, other 7 rows' persistence (same code path), VoiceOver, Dynamic Type, dark mode, iPad, iOS 17.4 runtime, no unit tests run. `AudioTextBibleTTSCore` reading the new speed during real playback was not exercised.

## Gotchas
- The UIKit speed button in `VCAudioTextBible` can look disabled/blank (spinner-like icon) while data loads, and the push takes a moment; automation taps need patience.
- SwiftUI `Slider(value: $model.steps[i], ...)` works with an `@Observable` model held in `@State` (needs `@Bindable`-style `$model.steps[i]`; since the view holds `@State var model`, the `$` projection is available).
- Removing a scene by hand: also search for `relationship="rootViewController"` segues to its id to find an orphan nav controller; also delete the `<!--title-->` comment line before each scene.
- The working tree's `Main.storyboard` also contains Xcode 27's own format rewrite (uncommitted since before 1021o). Commit it like in 1021o: from HEAD's file, applying only the scene removals.

## Open issues / next steps
- Release notes: `## 4.12.7 (2026.10.21g)` added to `Helps/app_versions.md`; `VCIndex` labelVer/labelDate still show the last release (4.11.1).
- Possible follow-ups: a "reset to 1.00" row, and the sibling `VCAudioStopTimer` picker / the `VCAudioTextBible` main screen (still UIKit).
