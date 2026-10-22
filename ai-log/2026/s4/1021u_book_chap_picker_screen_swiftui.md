# 「書卷選擇」(book + chapter picker) rewritten in SwiftUI, written to be movable into FHLCommon

- Date: 2026-10-21
- Project: FHLBible
- Type: refactor (SwiftUI rewrite + redesign)
- Related logs: 1021q_read_history_screen_swiftui.md (same `UIHostingController` + `onClick$` pattern), 1021t_versions_compare_screen_swiftui.md (storyboard scene removal), 1021j_min_ios_17_and_swiftui_direction.md
- Cross-project: none yet. FHLCommon and FHLBibleTW are untouched on purpose; the user plans to move this picker into FHLCommon later because FHLBibleTW needs it too (see "Moving to FHLCommon").
- Commit: uncommitted
- Release notes: `## 4.12.11 (2026.10.21k)` in `Helps/app_versions.md`

## Goal / why
User asked to rewrite the 書卷選擇 screen in SwiftUI (free to redesign when it is more iOS-guideline-like) and to design it so it can be lifted into FHLCommon later (FHLBibleTW will use it too), without touching the other two projects now.

## Old behavior
- Class `VCBookChapPicker` lives in **FHLCommon** (`FHLCommon/VCBookChapPicker/VCBookChapPicker.swift`), storyboard scene `VCBookChapPicker` (customModule FHLCommon) inside FHLBible's `Main.storyboard`, instantiated through `gVCBookChapPicker()` (FHLCommon extension on UIViewController -> `gEasyGetViewCtrlFromXibCore("VCBookChapPicker")`). FHLBible's own `BookChapPicker/VCBookChapPicker.swift` was a fully commented-out dead copy (kept in the pbxproj Sources, which is why it is reused below).
- API: `initBeforePushVC(idBook, idChap)`, `onClick$: IjnEventOnce<UIView,(idBook:Int,idChap:Int)>`. On a selection: `navigationController?.popViewController(animated: false)` then `onClick$.triggerAndCleanCallback(view, (book, chap))`. Leaving without choosing triggers nothing.
- UI: one row of tab buttons 舊約 | 新約 | 章 | 希伯來順序 + a 「完整名稱」 toggle; a `ViewButtons` (xib collection of buttons) below. Opened on the 章 tab (chapters of the current book). Tapping a book that has >1 chapter switched to the 章 tab; books with exactly 1 chapter (`BibleChapCount.getChapCountEqual1BookIds()`: 31 俄, 57 門, 63 約二, 64 約三, 65 猶) returned immediately with chap 1. Full-name toggle only affected Chinese (always 馬太福音-style, even in an English locale).
- Callers in FHLBible: `VCRead.pickBookChap()` (tap on the title / address button) and `VCParsing.goSelectBook()`. FHLBibleTW has its own storyboard scene using the FHLCommon class — unaffected.

## What changed
- `BookChapPicker/VCBookChapPicker.swift` replaced (file name kept; renaming needs a pbxproj edit which is off limits) by a self-contained SwiftUI implementation. **Only FHLCommon public API is used** (`BibleChapCount`, `BibleConstants.s.ORDER_OF_HEBREW`, `ManagerLangSet.s.curTpBookNameLang/curBookClassor/curBookClassorNaOrder`, `ManagerFontScale.s.cur`, `get_booknames_via_tp`, `BookNameLang`, `IjnEventOnce`) — nothing from FHLBible — so the file can be moved as is.
  - `final class BookChapPickerViewController: UIHostingController<BookChapPickerView>` — `init(book:chap:)`, `var onClick$` with the same type and the same contract as the old class (pop with animated:false, then trigger). Root view is first built with a no-op `onPick` then replaced with a `[weak self]` one (same trick as VCReadHistory/VCTsk); the model is created once and shared by both.
  - `@Observable BookChapPickerModel(curBook:curChap:)`: `curBook` (nil when outside 1...66), `curChap`, `order: BookChapPickerOrder` (`.canon`/`.hebrew`), `showsFullName` (persisted in `UserDefaults` key `BookChapPickerShowsFullName`, default false = abbreviations like the old default), `chapTarget: BookChapPickerChapTarget?` (the book whose chapter sheet is shown). Helpers: `displayName(book)`, `fullName(book)`, `sections`, `chapCount`, `hasSingleChap`.
  - Names: abbreviations = `get_booknames_via_tp(ManagerLangSet.s.curTpBookNameLang)`; full names = `.马太福音GB` when the current lang is `.太GB`, `.馬太福音` when `.太`, else `.Matthew` (improvement: English locale now gets English full names).
  - Sections: canonical order = `BibleBookClassor` categories from `ManagerLangSet.s.curBookClassorNaOrder.dropFirst(3)` (skips 全部/舊約/新約) with ranges from `curBookClassor` (so GB variants come for free): 摩西五經 1–5, 歷史書 6–17, 詩歌智慧書 18–22, 大先知書 23–27, 小先知書 28–39, 福音書 40–44 (incl. Acts), 保羅書信 45–57, 其它書信 58–66. Hebrew order = three OT sections cut from `ORDER_OF_HEBREW` by index (`0..<5` 律法書, `5..<26` 先知書, `26..<39` 聖卷; counts 5/21/13) followed by the NT categories (books >= 40) of the canonical list. Category names in English locale are still Chinese (`BibleBookClassor` has no English).
  - `BookChapPickerView`: `ScrollView` + `LazyVStack(pinnedViews: .sectionHeaders)` with one `Section` per category (pinned `.bar` header + `LazyVGrid` adaptive columns; min width `fontSize*3.2` for abbreviations, `*6.5` for full names). Book cell = >=44pt rounded rect, current book filled with accent color, full book name as accessibility label, `.isSelected` trait. `safeAreaInset(.top)` holds a segmented `Picker` 聖經順序 | 希伯來順序; toolbar trailing `Toggle("完整名稱").toggleStyle(.button)`; first row 「目前閱讀 創世記 1」 shortcut (hidden when the current book has a single chapter) opens the chapter sheet of the current book (the old tool's most common path: change chapter in the same book). On appear and when order/name mode change it scrolls the current book to the center (`DispatchQueue.main.async` + `ScrollViewProxy.scrollTo`; ids are the 1-based book numbers, unique across sections).
  - Chapter selection is a `.sheet(item:onDismiss:)` (`presentationDetents([.medium,.large])`, drag indicator) containing its own `NavigationStack` (title = full book name, 「取消」 button) and an adaptive `LazyVGrid` of chapter numbers (current chapter highlighted and scrolled to). Picking a chapter stores `pending`, nils `chapTarget`, and `onPick` fires from the sheet's `onDismiss` — so the pop of the hosting controller happens only after the sheet animation finished (popping while a sheet is still presented is the pitfall avoided). Swipe-down / 取消 leaves `pending` nil -> nothing is reported.
  - Fonts: `@ScaledMetric(relativeTo: .body) fontSize = 17 * ManagerFontScale.s.cur` (old code used `UIFontMetrics` on 18 * scale), so both Dynamic Type and the in-app font scale apply.
- Call sites: `Read/VCRead.swift` `pickBookChap()` and `FHLTools/SNParsing/VCParsing.swift` `goSelectBook()` now create `BookChapPickerViewController(book:chap:)` directly; `onClick$` usage unchanged. `gVCBookChapPicker()` (FHLCommon) is no longer called from FHLBible (it would crash here now: the scene is gone) but stays for FHLBibleTW.
- `Main.storyboard`: removed scene `vOZ-lH-uBd` (VCBookChapPicker + scroll/stack tab buttons + ViewButtons) and its orphan `Navigation Controller` scene `saG-b9-b4r` (only a relationship segue to it). 24 -> 22 scenes (counted by `grep -c "<scene "`). XML validated with `xmllint`; no remaining references to the removed ids. Note the working tree already had unrelated uncommitted Xcode edits in this storyboard and in the pbxproj (left as is).
- `zh-Hans`/`zh-Hant` `Main.strings`: removed the dead entries of that scene (`eBx-nJ-ndg`, `cNg-CC-9nk`, `LHg-Ea-1Lv`, `bO6-h0-nfu`, `Of4-B8-jSJ`, `1Kz-GG-2eO`); runs of blank lines were also collapsed as a side effect of the script.
- `zh-Hans` `Localizable.strings`: new keys (key = Traditional text, like the rest of the file): 書卷選擇, 排列方式, 聖經順序, 希伯來順序, 完整名稱, 目前閱讀, 律法書, 先知書, 聖卷. Reused without a new entry: 取消, 第%d章 (identical in Simplified).

## Redesign vs old (why)
- One scrolling overview with category headings instead of tabs: the whole canon is visible, category names orient the user, current book is highlighted and scrolled into view.
- Chapter step as a half-height sheet (standard iOS pattern, keeps the book list visible, supports Psalms 150 via the large detent) instead of swapping the grid in place.
- Hebrew order is a segmented control and now has real sections; full-name toggle persists; larger 44pt targets; VoiceOver reads full names; Dynamic Type works.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible -destination iPhone 18 Pro (iOS 27.0 simulator, deployment target 17.0)`: BUILD SUCCEEDED, no errors (deployment target 17.0 means any iOS 18+ API would have failed to compile).
- Ran in the simulator: 閱讀 -> tap title 「創1」 -> picker opens with 創 highlighted and the 「目前閱讀 創世記 1」 row; tap 詩 -> sheet 詩篇 with 1…150 grid; tap 13 -> sheet dismissed, then back to Read showing 詩 13; reopen -> 希伯來順序 + 完整名稱: scrolled to 詩篇 (highlighted) in the 聖卷 section, pinned header shown, NT sections follow; tap 俄巴底亞書 (single chapter) -> directly 俄 1.
- NOT verified: the `VCParsing` entry path, the 「目前閱讀」 row and the 取消 button, swipe-down dismissal, GB (簡體) names/strings, English locale, iOS 17.4 runtime, dark mode, large Dynamic Type / ManagerFontScale, iPad, VoiceOver, FHLBibleTW (untouched, not rebuilt), unit tests (none added: a new test file needs a pbxproj edit).

## Gotchas
- Simulator screenshots lag one action behind (same as earlier logs): take a second screenshot before judging; also a screenshot taken during the sheet dismissal shows the list shifted down — just a mid-animation frame.
- The model computes names on every call from `get_booknames_via_tp` (cheap arrays); no caching needed.
- `ScrollViewProxy.scrollTo` inside `onAppear` needs the `DispatchQueue.main.async` hop, otherwise the lazy rows are not laid out yet.

## Moving to FHLCommon (checklist for later)
1. Move the file (rename to e.g. `BookChapPicker.swift`); mark `BookChapPickerViewController` (`public init(book:chap:)`, `public var onClick$`) public; the view/model can stay internal.
2. It conflicts by name with nothing in FHLCommon, but the old UIKit `VCBookChapPicker`/`ViewButtons` + `gVCBookChapPicker()` there are to be retired once FHLBibleTW is switched; FHLCommon's CLAUDE.md currently says "no SwiftUI screens in FHLCommon unless the user asks" — the user has asked.
3. Strings: the nine new keys currently live in FHLBible's `zh-Hans` Localizable.strings and are resolved from the main bundle (`NSLocalizedString`). In FHLCommon they must move into the framework bundle (`NSLocalizedString(_, bundle: .init(for:))`) or be injected.
4. FHLBibleTW: replace its storyboard scene/`gVCBookChapPicker()` use the same way as here (scene removal + `Main.strings` cleanup); expect pbxproj edits for new files there.
5. `UserDefaults` key `BookChapPickerShowsFullName` becomes shared between the apps' own domains only conceptually (each app has its own defaults).

## Open issues / next steps
- Search field for book names, and an English translation of the category names, were considered and left out.
