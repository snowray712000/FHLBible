# "有聲文字" (TTS Bible player) screen rewritten in SwiftUI, with a redesign

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor + UX redesign (playback core and persisted data unchanged); third screen taken out of the storyboard today
- Related logs: 1021p_audio_text_speed_screen_swiftui.md, 1021q_read_history_screen_swiftui.md
- Cross-project: none
- Commit: 0abbf79 (no release note); the note for this screen was added with 4.12.9 together with 有聲聖經 (see 1021s). Main.storyboard working tree also still carries Xcode 27's format rewrite; when committing, apply only the scene removals to HEAD's file as in 1021o/p.

## Goal / why
Next screen of the UIKit -> SwiftUI migration; the maintainer allowed a different design if it fits iOS guidelines better (also hinted that there may be a ready-made media UI). Entry: Read -> "···" -> 有聲文字 (`VCRead._doMore`, `pData == "audiobibletext"`).

Note on "ready-made media UI": there is no stock SwiftUI player chrome for TTS (`VideoPlayer` / `AVPlayerViewController` are for AVPlayer media). The iOS-native pieces that apply are the Now Playing / remote command integration, which already exists in `AudioTextBibleTTSCore` (MPRemoteCommandCenter, `setPlayingCenterInfo`) and is untouched, plus system `Menu`/`Picker` controls used below.

## What the old screen did
- Storyboard scene `VCAudioTextBible` (+ an orphan `UINavigationController` scene whose root it was): 5 tinted icon buttons (loop, prev, play, next, speed), a gray timer button ("-- : --"), two long "info" buttons used as text (Greek/Hebrew TTS is modern, not Koine; lock-screen progress time is approximate), and a right bar item showing the current address string. Several outlets (`labelTime1`, `sliderProcess`, ...) were declared but unused.
- Loop button cycled `All -> Book -> Chap -> All` with icons goforward / repeat / repeat.1 (no text).
- Timer button presented the UIKit picker `VCAudioStopTimer` (custom modal) with options 30, 60, 1:30, 2:00, 3:00, 4:00, 6:00, 8:00 minutes and "--" to cancel.
- Speed button pushed `VCAudioTextSpeed`.
- viewDidLoad: `ttsCore.setAddrAndPauseAndCleanDataAndTriggerAddrChangedEventIfNeeded(addr)`, `ttsCore.setVersions(vers)`, show `ttsCore.addrStr`, loopMode from core; callbacks: core `addrChanged$` (update title), `AudioBibleTextStopTimer.s.evTick` (button title = `ctime2dashdashformat(secondRemain)`), `evCompleted` (play icon, "-- : --"), app became-active (refresh play icon); `DBackgroundMusic.s.tp = .bibleText` so the control center targets this source. deinit cleared the three callbacks by key.

## What changed
- `VCAudioTextBible/VCAudioTextBible.swift` rewritten:
  - `class VCAudioTextBible: UIHostingController<AudioTextBibleView>` with `init(addr: VerseRange, vers: [String])`; sets `rootView.onOpenSpeed` to push `VCAudioTextSpeed()` (SwiftUI has no navigation stack of its own here). `init(coder:)` is `fatalError` (no storyboard instantiation any more).
  - `@Observable AudioTextBibleModel`: `addrStr`, `isPlaying` (= `ttsCore.statePlaying != .stop`, so "querying data" counts as playing), `loopMode` (`didSet` writes `ttsCore.loopMode`), `timerText` (nil = no timer). `init` does what viewDidLoad did (set addr/versions on the singleton core, read loop mode / playing state, `DBackgroundMusic.s.tp = .bibleText`) and now also shows the remaining time when a timer is already running (`AudioBibleTextStopTimer.s.timer != nil`) - the old screen showed a blank/placeholder in that case. Event callbacks are registered with a per-instance key and hop to the main queue; `deinit` clears them. Actions: `playOrPause`, `goNext`, `goPrev` (all call the same core methods as before then `refreshPlaying()`), `startStopTimer(minutes:)` (`stopPrevTimerAndStartNewTimer(min*60)`), `cancelStopTimer()` (`cancelTimer()`, `secondRemain = 0`).
  - `AudioTextBibleView`: centered column: waveform symbol (`symbolEffect(.variableColor.iterative, isActive: isPlaying)`), address as large title, transport row (prev / 72pt play-pause / next, plain buttons tinted), three equal-width option tiles (icon over caption, `quaternary` rounded background): loop `Menu` with a `Picker` (連續播放 / 本卷循環 / 單章重複 with the same three SF symbols), speed (calls `onOpenSpeed`), stop-timer `Menu` (cancel item only while running + the 8 durations, titles formatted by `DateComponentsFormatter(.full, hour+minute)`; the tile shows the live countdown). Footnotes: the two old info sentences as secondary footnote `Label`s with `info.circle` (same localization keys). Inline navigation title "有聲文字". `onChange(of: scenePhase)` -> `refreshPlaying()` replaces the `EasyEventAppBackgroundForegroundSwitch` usage.
- Design differences (deliberate): loop mode is now a menu with named options instead of a blind 3-way cycle; stop timer is a system menu instead of the custom modal picker (`VCAudioStopTimer` is still used by `VCAudioBible`, untouched); the speed icon is `speedometer` (the old `timelapse` symbol renders like a spinner on iOS 27); accessibility labels on prev/play/next; Dynamic Type friendly (no fixed frames except the tile min height).
- `Read/VCRead.swift`: `VCAudioTextBible(addr: self._addrsCur!, vers: self._vers)` replaces `gVCAudioTextBible()` + property assignment. `VCEasyFunctions.swift`: `gVCAudioTextBible()` removed (no other users).
- `Base.lproj/Main.storyboard`: removed scene `F3q-JV-cKf` (VCAudioTextBible) and the orphan nav-controller scene `3Sh-Mw-y0v` (`L13-og-r1V`, only referenced the removed VC). 30 -> 28 scenes (working tree).
- `zh-Hans.lproj/Localizable.strings`: added 暫停, 連續播放, 本卷循環, 單章重複, 計時停止, 取消計時 (other new keys - 上一章 下一章 播放 速度 播放方式 - are identical in Simplified, or already present). zh-Hant relies on the key itself.

## Not changed
`AudioTextBibleTTSCore` (singleton, queries data, TTS, control center), `AudioBibleTextStopTimer`, `TTSEngineGetter`, `ManagerAudioTextSpeed`, persisted values. Behavior quirk kept as-is: `cancelTimer()` triggers `evCompleted` when a timer was running, and the core's own `evCompleted` handler then pauses playback, so cancelling a running timer also pauses (the UI now reflects that). The play state is only refreshed on user actions, `addrChanged$`, timer completion and returning to active; the core has no "playing state changed" event, so a pause from the control center while this screen is visible is not reflected until one of those happens (same as the old screen).

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination 'platform=iOS Simulator,id=1642C4FC-...'` (iPhone 13 mini, iOS 27.0 SDK, target 17.0): BUILD SUCCEEDED, no warnings from the new file.
- Ran in the simulator: 閱讀 -> ··· -> 有聲文字 shows the new screen (waveform, "詩 5", transport, three tiles, footnotes); play toggles to pause and the waveform animates; timer menu opens with the 8 durations, choosing 30 分鐘 starts the countdown on the tile (29:56 -> 29:31, kept counting after leaving and re-pausing); the speed tile pushes 有聲文字速度; back returns; pause restores the play icon.
- NOT verified: actual audio output, prev/next chapter, loop menu selection, cancel-timer item, timer completion, control-center / lock-screen controls, returning from background, re-entering the screen while playing, zh-Hans strings, VoiceOver, Dynamic Type, dark mode, iPad, iOS 17.4 runtime, unit tests.

## Gotchas
- Driving the simulator: the Read "···" sheet needs a swipe to reach 有聲文字; the first tap after a swipe is sometimes swallowed, and the in-panel screenshot lags - use `xcrun simctl io <udid> screenshot` after a short sleep.
- `.buttonStyle(.bordered)` on a `Menu` label did not render a background next to a `Button` on iOS 27, so the tiles draw their own background and use `.plain` + `.tint` for all three.
- `.monospacedDigit()` takes no argument; use `.font(.caption.monospacedDigit())`.
- When removing a scene by hand, delete the `<!--title-->` comment line before it too, and check `relationship="rootViewController"` segues for the orphan nav controller.

## Open issues / next steps
- Possible: a core event for playing-state changes; a read-only progress bar (the old `getProcessInfo()` estimate); `VCAudioBible` (有聲聖經) is the sibling still in UIKit and could reuse the same layout.
