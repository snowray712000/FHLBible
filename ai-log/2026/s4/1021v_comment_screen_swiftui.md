# Commentary screen ("註釋") rewritten in SwiftUI; UI term unified to 註釋 (was 注釋); removed from Main.storyboard

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor + terminology change (UI technology change with small UX improvements)
- Related logs: 1021o_tsk_screen_swiftui.md (same structure, `DTextContentView` and the shared `IReloadData` types come from there), 1021t_versions_compare_screen_swiftui.md, 1021m_helps_screen_swiftui.md
- Cross-project: none (FHLCommon's `CommentDataStrToDText` is only used, not changed)
- Commit: not committed (working tree also holds uncommitted 1021u book-picker work and the Xcode 27 storyboard rewrite).

## Goal / why
Next screen of the UIKit -> SwiftUI migration, requested by the maintainer together with a rename: the UI says 「註釋」 (commentary), not 「注釋」. Entry point: Read -> tap a verse address on the left of a row -> `VCVerseActionPicker` -> 「註釋」 -> `OneVerseFunctionsClickFlow._doWhenClickedVerseAddressCell` pushes the screen.

## Behavior (kept from the old UIKit `VCComment`)
- Data: `ReloadDataAutoUseOfflineOrScApi` (offline `comm.db` / `comm_gb.db` under Documents `/offline/` if present, else FHL SC API `book=3`) -> `apiFinished$(sender, pData)`; `sender != nil` means error/info message `[DText]`; otherwise `pData.com_text` -> `CommentDataStrToDText().main(text)` (FHLCommon public class) and `pData.addrNext/addrPrev`.
- One commentary entry covers a verse RANGE; prev/next are the addresses just outside it. Title = `註釋` + `from至to` where `from = prev.chap == 0 ? (book,1,1) : prev.goNextVerse()` and `to = next.goPrevVerse()` (chapter 0 is the book introduction); if prev or next is nil the title falls back to `註釋 <addr>`. Book names use `ManagerLangSet.s.curTpBookNameLang`.
- Content shown with `ViewDisplayCell` (via `DTextContentView`, `isVisibleSn: true`, left aligned). Tap on a DText with `refDescription` -> push `VCRead` with `StringToVerseRange().main(ref, (book, chap))` and `ManagerBibleVersions.s.cur`; tap on a DText with `sn` -> `SnDTextClickFlow(vc:addr:vers:).mainAsync` (SN action picker).
- Navigation: toolbar arrows (left = previous entry, right = next) and one-finger swipe right/left via `SwipeHelp` (also disables the system back swipe).

## What changed
- `FHLTools/Comment/VCComment.swift` rewritten: `class VCComment: UIHostingController<CommentView>`, `init(addr:)` replaces `setInitData` + storyboard instantiation; `@Observable CommentModel` (`addr`, `dtexts`, `generation`, `isLoading`, `addrNext/addrPrev`, `title`, `goNext/goPrev/reload`, `@ObservationIgnored requestId` stale-response guard); `CommentView` = `ScrollView` + inline `navigationTitle(model.title)` + trailing `arrow.left`/`arrow.right` buttons. Reuses `DTextContentView` from `VCTsk.swift` with `alignment: .left` and `onTapAny` routing (ref first, then SN) — `onTapRef` is also set because it is a required parameter.
- UX changes vs old screen: loading shows a `ProgressView("取得資料中...")` instead of a text row; arrows are `.disabled` when there is no prev/next (old: silent no-op; note they are also disabled while loading and after an error because `reload()` clears prev/next so the title is not a stale range); 8pt horizontal padding around the text.
- Unchanged: `VCCommentIReloadData*.swift` (`extension VCComment { class DReloadData, IReloadData, ReloadDataViaOfflineDatabase, ReloadDataViaScApi, ... }`, shared by `VCTsk` through typealiases/subclasses), `FhlScCore.swift`.
- Call site: `Read/OneVerseFunctionsClickFlow.swift` now `push(VCComment(addr: ...))`; `gVCComment()` removed from `VCEasyFunctions.swift`.
- `Base.lproj/Main.storyboard`: removed the `VCComment` scene (`SrM-Ha-35L`) and its orphan `Navigation Controller` scene (`gjZ-iQ-9ex`); 22 -> 20 scenes (XML parses, no dangling ids). Removed the now-dead `7eq-zL-c2n.title` entries from `zh-Hans.lproj/Main.strings` and `zh-Hant.lproj/Main.strings`.
- Terminology 注釋 -> 註釋: `VCVerseActionPicker` (list title + the Tsk description sentence, which is also a `Localizable.strings` key, so the zh-Hans key was changed too), `VCHelps` topic `titleTw`, comments. `zh-Hans.lproj/Localizable.strings`: old keys `"注釋" = "注释"` and `"註釋" = "註释"` merged into `"註釋" = "注释"` (the old 註释 value was a typo mixing scripts). Simplified Chinese stays 注释. No 注釋 remains outside ai-log.
- `Helps/app_versions.md`: added `## 4.12.12 (2026.10.21l)`.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination iPhone 13 mini (iOS 27.0 simulator)`: BUILD SUCCEEDED, no warnings from VCComment.swift.
- Ran in the simulator (API data path): 詩 5 -> tap 詩5:1 -> picker shows 註釋 -> screen titled 「註釋詩 5:1至詩 5:3」 with commentary, blue refs, cyan H-numbers; next arrow -> 「註釋詩 5:4至詩 5:6」; tap H1984 -> SN action picker; tap `#5:4-6|` -> VCRead at 詩 5:4-6.
- NOT verified: previous arrow, swipe gestures, disabled arrows at book start/end, chapter-0 introductions, error/empty message path, offline `comm.db` path, GB (simplified) titles and strings, iOS 17.4, dark mode, Dynamic Type, iPad; the 8pt padding was added after the last visual check (build only). No unit tests.

## Gotchas
- `DTextContentView` is declared in `FHLTools/Tsk/VCTsk.swift`; keep it there or move it before deleting that file.
- A hosting controller has `storyboard == nil`; `gVCRead()` already falls back to `navigationController?.storyboard`/Main (see 1021t).
- Localizable keys are the literal Chinese source strings: renaming the text in code requires renaming the key in `.strings`, or the zh-Hans lookup silently falls back to the Traditional text.

## Open issues / next steps
- `VCIndex` labelVer/labelDate still show 4.11.1 (release notes sections exist up to 4.12.12).
- Help images `helps_03comment_*` may still show the old 「注釋」 wording inside the screenshots.
