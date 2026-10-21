# Baseline: FHLBible project overview

- Date: 2026-10-21
- Project: FHLBible
- Type: baseline
- Related logs: none (first log)
- Cross-project: FHLBibleTW `ai-log/2026/s4/1021a_baseline_project_overview.md`, FHLCommon `ai-log/2026/s4/1021a_baseline_project_overview.md`
- Commit: uncommitted

## Goal / why
`ai-log/` was introduced on this date. Earlier development left no logs. This entry is a snapshot written by an AI after surveying the code, **not** from the original development sessions, so it contains no historical reasoning. Earlier history lives in `git log` and the legacy docs listed in `index.md`.

## Starting state
- Xcode project `FHLBible.xcodeproj`, bundle id `IJN.FHLBible`, marketing version 4.11, iOS 14.0 minimum (deliberate: to support old phones that cannot update iOS), Swift 5, UIKit + storyboards/xibs.
- About 218 Swift files; about 118 import `FHLCommon`.
- Part of workspace `FHLWorkSpace.xcworkspace` with sibling projects FHLBibleTW and FHLCommon. Each is a separate git repo (GitHub `snowray712000/<name>`).
- SPM dependencies: `fmdb` (SQLite), `ZIPFoundation` (unzip downloaded Bible files).

## What it does (behavior level)
Bible reader supporting multiple translations side by side, full-text search, Strong's numbers (Hebrew/Greek) with dictionary and parsing views, scripture notes/commentary, audio Bible with playback-rate control and stop timer, version download manager, reading history, settings (font scale, language).

## Design and decisions (as found in code)
- Module folders under `FHLBible/`: `Read`, `Search`, `FHLTools` (`SNParsing`, `SNDict`, `Tsk`, `Comment`), `VCAudioBible`, `Download`, `SQLiteFHL`, `EasySQLite`, `Common`, `Tools`, `Helps`, `History`, `VCSetting`, `BookChapPicker`, `VCVersionsPicker`, `VCVersionsCompareInOneVerse`, `VCWhenLongPress`, `NoUse`.
- Read data flow: address change event (`_addrsCurChanged$`) → `BibleReadDataGetter` queries one thread per translation (DispatchGroup) → each uses SQLite file if the version was downloaded, otherwise the FHL `qsb` API → `BibleText2DText` converts to `[DOneLine]`/`[DText]` → `_dataChanged$` → `ViewDisplayTable2` renders rows (first row = translation labels). `ViewDisplayTable2` is shared by Read and Search.
- Eventing uses `IjnEvent` / `Observable-Swift` with `xxx$` naming.
- Code is being migrated from this project into FHLCommon. About 25 same-named files (e.g. `DAddress`, `DText`, `BibleText2DText`, `IjnEvent`, `StringToVerseRange`, `VCBookChapPicker`) exist in both with different contents. App-local types shadow imported ones.

## Key files / types / functions
- `Read/VCRead.swift`, `Read/DataGetter/BibleGetterViaSQLiteFile.swift`, `Read/DataGetter/BibleGetterViaFhlApiQsb.swift`, `Read/ReadDataQ.swift`
- `FHLTools/SNParsing/VCParsing*.swift` (parsing UI + online `qp` API / offline DB variants)
- `FHLTools/Comment/VCComment*.swift`
- `Download/DoOneDownload_*.swift` (bible, kjv, gb, comm, cbol dict, parsing)
- `VCAudioBible/*`

## Contracts and algorithms
Not captured in this baseline. Future logs should record API parameters, SQLite schemas, and parsing formats when those areas are touched. Existing notes: `doc/260413b_parsing_format_for_ai.md`, `doc/260927a_離線parsing資料庫_bible_parsing.md`.

## Gotchas
- Some tests under `FHLBibleTests/fhlwh_bug/` need a LAN server (`192.168.0.116:5600`) and `XCTSkip` otherwise.
- `xcuserdata` is tracked in git, so `git status` shows noise.
- Verify which copy of a duplicated type the target actually uses before editing.

## Verification
Nothing was built or run for this entry. It is based on reading files and project settings only.

## Open issues / next steps
Complete the migration of shared code to FHLCommon (direction and scope to be decided by the maintainer).
