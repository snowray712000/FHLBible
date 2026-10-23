# 譯本選擇 (translation picker) rewritten in SwiftUI; removed from Main.storyboard

- Date: 2026-10-23
- Project: FHLBible
- Type: refactor (UI technology change with UX redesign)
- Related logs: 1021t_versions_compare_screen_swiftui.md (the compare screen reuses this picker with `updatesCurWhenDone: false`), 1021u_book_chap_picker_screen_swiftui.md and 1022c_parsing_screen_swiftui.md (same hosting-controller / scene-removal procedure)
- Cross-project: none (FHLBibleTW has its own, unrelated screens; FHLCommon only provides `IjnEventOnce`)
- Commit: not committed.
- Release notes: `Helps/app_versions.md` section `## 4.12.19 (2026.10.23a)` (the user said "based on 4.12.18", whose section already existed, so a new section was added).

## Goal / why
Next screen of the UIKit -> SwiftUI migration. 「譯本選擇」 lets the user choose which translations (unv, cuwv, kjv, …) the Read screen (and the 譯本比較 screen) shows, in which order. The old screen was a storyboard scene + a big xib (`ViewVersionsPicker.xib`, ~500 lines of manual stack/collection-view code with `IjnEvent`s between view and controller).

## Behavior (new)
- Entry: `VCVersionsPicker(vers:updatesCurWhenDone:)` (a `UIHostingController<VersionsPickerView>`), pushed by `VCRead.pickVersions()` (`updatesCurWhenDone: true`, default) and `VersionsCompare.doPickVersions()` (`false`: compare keeps its own list in `ManagerBibleVersionsForCompare`). `gVCVersionsPicker()` and `setInitData(_:isUpdateCurVersWhenOkay:)` are gone. `onClickOkay$: IjnEventOnce<Any,[String]>` contract kept (fires AFTER the screen is popped, argument = chosen codes in order). The old `onClickCancel$` had no subscribers and was dropped.
- Commit semantics (kept from the old screen): the toolbar 「完成」 AND any back navigation (back button, swipe) confirm. Implemented in `viewDidDisappear -> commitIfNeeded()` guarded by `isFinished`. 「放棄變更」 (⋯ menu; a confirmationDialog when `hasChanges`) sets `isFinished = true` first, so nothing is saved and `onClickOkay$` does not fire.
- At commit: `model.saveState()` writes recent list (max 20, `maxRecent`), group (`optSub`), filter on/off (`isOnSub`), filter conditions (`optSub2`, new); then, if `updatesCurWhenDone`, `ManagerBibleVersions.s.updateCur(vers)`; then `onClickOkay$` fires. **When `updatesCurWhenDone` and the selection is empty nothing is saved/fired (Read must have >= 1 translation; the old code would have written an empty list)**; the section footer says so. The compare screen may confirm an empty list (it shows 尚未選擇譯本).
- Layout (`List`, `.insetGrouped`, inline title 譯本選擇, system `.searchable` bar):
  1. 已選取 N 個譯本: one row per selected translation in selection order; tap = deselect (minus icon). Empty -> 尚未選擇譯本.
  2. 最近使用 (hidden when empty): horizontal chips with a "+" icon; tap = select. Recent = stored recent minus selected minus unknown codes. Deselecting inserts at the front; selecting removes from recent; `clearSelected` pushes them in order so the last one ends up first.
  3. 分類: horizontal capsule chips for the 8 groups (中文 英文 希伯來、希臘文 其它外語 台語 客家語 台灣原住民語 其它) with a badge = number selected in that group. For 中文 only: Toggle 「依分類篩選」, and when on three chip rows (教派 pr/cc/ro, 文體 officer/ccht/study, 年代 yr1800…yrnow), multi-select.
  4. Translation rows of the chosen group (checkmark when selected; caption `year · code`). Filter rule (unchanged from the old `updateItemsVisibleNowFromSub1Sub2OnOff`): filter applies only for group 中文 with the toggle on; a version is shown if it has no `cds`, or every one of its `cds` is among the selected conditions.
  - While searching: sections 1-3 are hidden and the list shows matches over ALL groups (case-insensitive substring of display name or code; caption then also shows the group), `ContentUnavailableView.search` when none.
  - ⋯ menu (hidden by 完成 while reordering): 調整順序 (needs >= 2 selected), 全部取消選取, 放棄變更. Reorder mode: `isReordering` swaps the list to only the selected rows with `.onMove` + `.onDelete`; `.environment(\.editMode, .constant(isReordering ? .active : .inactive))` must be on the **List** (on a Section the handles/minus buttons did not appear). The toolbar button then reads 完成 and only ends reordering.
- New: reorder (old screen could not), search, remembered filter conditions, group badges, per-row year/code caption. The old 套件 (sets) row was dropped: `ManagerBibleVersions.sets` could never be created by any UI (`clickClearSets` was empty), so nothing is lost; stored value untouched, `updateSets` is no longer called.
- Defaults for the filter conditions (stored key `BibleVersionSub2Opt`, previously unused): pr, cc, ro, officer, yr1960, yrnow — same as the old xib's initially selected buttons.

## Data / persistence
- `ManagerBibleVersions` (UserDefaults via `GlobalVariableBase`): `cur` (BibleVersions), `recent` (BibleVersionsRecently), `optSub` (BibleVersionSub1Opt, group raw string), `isOnSub` (BibleVersionIsOnSub, 0/1), NEW `optSub2` / `updateOptSub2` (BibleVersionSub2Opt, `[String]` of `TpChtSub.rawValue`, in canonical order); `Sub2Opt._getDefaultStringArray` supplies the defaults.
- Catalogue: `BibleVersionConstants.s.datas` (`OneGroup` -> `One(na: code, cna: display name, yr, cds)`), unchanged. Unknown codes (e.g. a retired translation stored in prefs): `name(code)` falls back to the code, `caption` still works, and recent drops them. The old code force-unwrapped `findInfoWhereNa` and would crash.
- Display names come from `BibleVersionConstants` (already GB-converted through `AutoLoadDUiabv`); group names are `OneGroup.cna`; filter chip titles go through `NSLocalizedString(TpChtSub.rawValue)` (raw values are the Traditional UI strings).

## What changed
- `VCVersionsPicker/VCVersionsPicker.swift` rewritten (`VCVersionsPicker`, `VersionsPickerModel` `@Observable`, `VersionsPickerView`, private `PickerChip`). File names kept to avoid editing pbxproj.
- `VCVersionsPicker/ViewVersionsPicker.swift`: comment-only stub (listed in pbxproj). `Base.lproj/ViewVersionsPicker.xib` + the three `ViewVersionsPicker.strings` are orphans (**remove the stub swift, xib and its strings in Xcode**).
- `Common/Managers/ManagerBibleVersions.swift`: `optSub2` / `updateOptSub2` + defaults.
- Call sites: `Read/VCRead.swift`, `VCVersionsCompareInOneVerse/VCVersionsCompareInOneVerse.swift`; `VCEasyFunctions.swift` lost `gVCVersionsPicker()`.
- `Base.lproj/Main.storyboard`: removed the VCVersionsPicker scene (`aqN-iD-U2O`) and its orphan Navigation Controller scene (`Nrv-xn-7SL`); 8 -> 6 scenes. Removed the `LEr-kf-SpF.title` entries from `zh-Hans/zh-Hant Main.strings`.
- `zh-Hans.lproj/Localizable.strings`: new keys (譯本選擇, 已選取 %d 個譯本, 至少要選一個譯本…, 搜尋譯本, 依分類篩選, 教派, 文體, 年代, 調整順序, 拖曳右側的把手…, 全部取消選取, 放棄變更, 放棄變更？, 繼續編輯, 取消選取, plus 羅馬天主教 俄羅斯正教 官話(白話文) 研讀本 which differ in Simplified). Traditional falls back to the key. Existing keys reused: 完成, 分類, 尚未選擇譯本, 更多, 此篩選沒有結果.
- `Helps/app_versions.md`: section 4.12.19.

## Verification
- `xcodebuild -workspace FHLWorkSpace.xcworkspace -scheme FHLBible` BUILD SUCCEEDED for iPhone 13 mini (iOS 27.0) and iPhone 15 Pro (iOS 17.4, compile only).
- Ran on iOS 27.0 (iPhone 13 mini): Read -> bottom-left translation button -> picker: add from 最近使用, group chip switch + badge, 依分類篩選 toggle (three chip rows with defaults), ⋯ menu, reorder mode (handles + minus appear; dragged second row above first), 完成 -> Read shows the new order (中文標準譯本 first, then FHL和合本), re-open shows persisted order, minus-removal pushes the item to the front of 最近使用, search field focuses.
- NOT verified: typing in the search field (simulator `text` paste did not arrive; only zhuyin keyboard), search results, 放棄變更 + dialog, swipe-back confirm, compare screen path (`updatesCurWhenDone: false`), GB strings, dark mode, iPad, Dynamic Type, VoiceOver, 17.4 runtime, selecting a version from another group, empty selection on Read.
- Simulator tool: screenshots lag one frame (take two); rapid taps right after a push land on the previous screen (a stray tap toggled SN on the Read screen once; toggled back). Coordinates: screenshot px * 0.406 for iPhone 13 mini.

## Gotchas
- `editMode` environment must be applied to the `List`, not a `Section`.
- Horizontal `ScrollView` chip rows inside a `List` row need `.listRowInsets(EdgeInsets())` plus own horizontal padding; row taps do not interfere with chip buttons because `PickerChip` uses `.buttonStyle(.plain)`.
- `viewDidDisappear` is the commit point; the discard path must set `isFinished` BEFORE popping.

## Open issues / next steps
- Remove the ViewVersionsPicker swift stub, xib and strings in Xcode.
- The 譯本選擇 screen is self-contained enough to be shared with FHLBibleTW only if `BibleVersionConstants` / `ManagerBibleVersions` move to FHLCommon (not done).
