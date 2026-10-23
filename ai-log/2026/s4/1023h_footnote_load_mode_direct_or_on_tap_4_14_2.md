# Feature: global "footnote load mode" setting (direct load / tap to load), default direct (4.14.2)

- Date: 2026-10-23
- Project: FHLBible
- Type: feature
- Related logs: 2026/s4/1021x_footnote_screen_swiftui.md, 2026/s4/1023f_release_4_13_1_and_detail_version_toggle.md, 2026/s4/1023g_fix_read_composite_verses_narrow_width_4_14_1.md
- Cross-project: none (FHLCommon untouched; FHLNUI at /Users/snow/coding/FHLNUI, a web project, was the reference)
- Commit: uncommitted

## Goal / why
Maintainer asked (as "4.14.2") to port FHLNUI's footnote option `foot_note_show_method` (0 = 點擊顯示, 2 = 直接載入; `index/queryFootsAsync.js`, `index/lecture/docs/注腳.md`, `docs/z261010b`) to the iOS app as a global setting: 「直接載入」 or 「點擊載入」, default 「直接載入」.
Footnotes exist for cnet (NET聖經中譯本), csb (中文標準譯本), lcc (呂振中譯本): the verse text contains `【n】`, which `SSFoot` turns into a `DText` with `foot = DFoot(id, book, chap, verse, version)` (blue). Before this, tapping it pushed the 注腳 screen (`VCFooter`, log 1021x). 和合本2010's inline `foot.text` (no id, purple) is already inline and untouched.

## Behavior
- Setting 「注腳載入方式」 in 設定 (a `Picker` at the top of `SettingsView`, footer text explains both modes). Stored in UserDefaults key `FootnoteLoadMode` (Int): `0` = direct, `1` = on tap. `getCoreInt` returns 0 when unset, so direct = 0 makes direct the default without any migration. Wrapper: `ManagerFootnoteLoadMode.s.cur / updateCur` (`GlobalVariableIntBase`, new key `FHLUserDefaults.keys.FootnoteLoadMode`).
- Direct: when verses are fetched, all `【n】` are replaced by `【註n：<content>】` (`【注n：…】` when `ManagerLangSet.s.curIsGb`). Container `DText` has `tpContain = "kjvrf"` (borrowed on purpose: `DTextDrawToAttributeString.gParentStyle` paints it purple and does NOT add brackets), children = `[DText("【註n："), …cvtFooter(text, addr, ver)…, DText("】")]`, so cross references inside (e.g. 參撒下11:3) stay blue and tappable via the existing ref flow. Purple matches the colour of the existing inline footnotes.
- On tap mode, or when a footnote could not be fetched (offline, 503, id missing, old backend), the blue `【n】` stays and still opens `VCFooter`. The mode applies the next time verses are loaded (no live refresh of an open Read screen).
- Applies to every screen that gets verses through `ReadDataQ`: Read, search results (`DataForDrawTable.OneQuery : ReadDataQ`), 譯本比較. Not to 有聲文字: `AudioTextBibleTTSCore` sets `dataReader.isExpandFootnotes = false` so the footnote is not read aloud.

## Implementation (all in existing files; no pbxproj edits — only `Helps/` is a synchronized group, other new files would need adding in Xcode)
- `Read/Footer/VCFooter.swift` (appended): `enum FootnoteLoadMode`, `ManagerFootnoteLoadMode`, `final class FootnoteExpander` (`FootnoteExpander.s.expand(_ datas: [[DOneLine]], completion:)`).
- `Read/ReadDataQ.swift`: after `BibleReadDataGetter().queryAsync` returns, if `isExpandFootnotes && mode == .direct` call `FootnoteExpander.s.expand(datas) { finishQuery }`, else `finishQuery` directly. `finishQuery` is the old closure body moved into a method (unchanged logic). `DOneLine.children` is mutated in place (no cache in the getters, so safe).
- `VCSetting/VCSettings.swift`: Picker + `.onChange` → `updateCur`. `zh-Hans.lproj/Localizable.strings`: 注腳載入方式 / 直接載入 / 點擊載入 / footer.
- `Helps/app_versions.md`: `## 4.14.2 (2026.10.23f)` detail section (even minor = hidden by default; roll up into 4.15.1). `VCIndex.labelVer/labelDate` not bumped (same convention as 4.12.*, 4.14.1).

## Network / API (same as FHLNUI `rtAsync`)
- `GET https://bible.fhl.net/json/rt-nui.php?engs=<Matt|1 Sam|…>&chap=<n>&version=<cnet|csb|lcc>&gb=<0|1>` — **no `id`** = whole chapter (lcc, csb: `scope:"chapter"`, `chap` echoed) or whole book (other versions such as cnet whose ids are unique per book: `scope:"book"`, e.g. 739 records for Matthew). `engs` from `BibleBookNames.getBookName(book, .Matt)`; built with `URLComponents` so the space in "1 Sam" is encoded.
- Response: `{"status":"success","record_count":N,"version":..,"engs":..,"scope":"chapter|book","chap":n,"record":[{"id":1,"text":"…"}]}`; text may have leading `\t ` and trailing `\r\n` (trimmed before `cvtFooter`). A response without `scope` = old backend that does not know whole-chapter queries → treated as failure (NUI falls back to one request per id; iOS deliberately does not, the footnotes just stay tappable). The old per-id `rt.php` (`fhlRt`, used by `VCFooter`) is unchanged.
- Verified live on 2026-10-23: rt-nui.php returns scope chapter for lcc Hab 2 and scope book for cnet Matt.
- `FootnoteExpander`: keys = (ver, book, chap, gb); one request per distinct key; results cached in memory for the process (`cache`), concurrent identical requests share one in-flight call (`pending`); once a version answers `scope:"book"` it is remembered (`bookScopeVers`) and later chapters of that book use the book-wide cache (key chap 0). State is guarded by a private serial `DispatchQueue`. 15 s request timeout; failure is never cached. All keys are awaited with a `DispatchGroup`, then `notify(queue: .main)` replaces nodes (recursively through `children`) and calls completion on main, so the existing `requestId` stale-response guards in Read etc. still work. If there are no footnotes at all, completion is called synchronously (no overhead for 和合本 etc.).
- Direct load adds one network round-trip before the chapter is shown for cnet/csb/lcc (offline: up to 15 s timeout before the plain text shows — not mitigated).

## Decisions / rejected
- Putting the code in FHLCommon: rejected for now (only FHLBible has footnote screens; avoids a cross-repo change). The expander only uses FHLCommon public API (`cvtFooter`, `DText`, `BibleBookNames`), so it can move later.
- Adding a clean `tpContain = "foot"` style in FHLCommon instead of borrowing `kjvrf`: rejected to keep FHLCommon untouched; if FHLCommon is touched later, switch to a dedicated value.
- Per-id fallback like NUI (4-parallel, retry 3): rejected, over-engineering for the app; the server limit (~6 concurrent) only bit the per-id approach.
- Pre-fetching on the next chapters: not done.

## Gotchas
- `DText.refDescription` taps in the expanded content go through the normal `doWhenContentClicked` → `RefDTextClickFlow`; the expanded leaves have no `foot`, so tapping the 【註n： text does nothing (not opening VCFooter).
- Copying text from the Read screen now includes the expanded footnotes in direct mode (NUI behaves the same).
- Launch-argument UserDefaults overrides for simulator tests: `simctl launch <dev> IJN.FHLBible -BibleVersions "(cnet)" -AddressCurrent "太1" -isSn 0 -FootnoteLoadMode 1` (arguments are volatile, they do not persist across launches). The Home 閱讀 row is disabled until the translation list loads; the first tap right after launch is ignored.

## Verification
- Built `FHLBible` scheme (workspace) for iPhone 13 mini, iOS 27.0 simulator: BUILD SUCCEEDED.
- cnet, 太 1, direct mode: v6 shows purple `【註1：「烏利亞的妻子」。即拔示巴(Bathsheba)(參撒下11:3)。】`, ref blue. Tap mode: blue `【1】` stays. 設定 screen shows the Picker and footer.
- Not verified: iOS 17.4 runtime, csb / lcc live in the app (only the API response for lcc was checked with curl), tapping a ref inside an expanded footnote, GB (簡體) label/content, search results and 譯本比較 with direct mode, offline / 503 behavior, FHLBibleTW build (FHLCommon untouched, so not rebuilt), toggling the setting while Read is open.
