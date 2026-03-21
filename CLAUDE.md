# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

This is an Xcode iOS project. All building and testing is done through Xcode or `xcodebuild`.

```bash
# Run all tests
xcodebuild test -project FHLBible.xcodeproj -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test -project FHLBible.xcodeproj -scheme FHLBible -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FHLBibleTests/BibleReadDataGetterTests
```

Some tests in `FHLBibleTests/fhlwh_bug/` require a local server at `192.168.0.116:5600`. They use `XCTSkip` if the server is unavailable.

## Architecture Overview

**FHLBible** is a Bible reader iOS app supporting multiple translations, full-text search, audio playback, Strong's numbers (Hebrew/Greek), and scripture notes.

### Module Structure

- **`FHLBible/Read/`** — Bible reading view and data pipeline (core module)
- **`FHLBible/Search/`** — Full-text search (keyword input + results)
- **`FHLBible/FHLTools/`** — SNParsing (Strong's/Hebrew analysis), SNDict (word lookup), Tsk (scripture notes)
- **`FHLBible/VCAudioBible/`** — Audio Bible playback with rate control
- **`FHLBible/Download/`** — Bible version downloading and SQLite file management
- **`FHLBible/SQLiteFHL/`** — SQLite operations and FMDB wrappers
- **`FHLBible/Common/`** — Shared types: `DAddress`, `VerseRange`, `DOneLine`, `DText`
- **`FHLBible/Helps/`** — In-app help/tutorial (paginated images via `VCHelps`)

### Data Flow (Read Module)

```
User picks address (DAddress/VerseRange)
  → VCRead._addrsCurChanged$ event fires
  → BibleReadDataGetter.queryAsync()
      ├─ parallel: one thread per Bible version
      ├─ BibleGetterViaSQLiteOrApi decides: SQLite file OR FHL API
      └─ merges results → BibleText2DText.main() → [DOneLine]
  → VCRead._dataChanged$ event fires → drawData()
  → ViewDisplayTable2 renders TpOneRow[] as UITableView
```

### Key Types

| Type | Role |
|------|------|
| `VerseRange` | Bible address range (book/chapter/verse) |
| `DAddress` | Single verse with multilingual book name support |
| `DOneLine` | One verse from one translation; contains `DText[]` |
| `DText` | Rich text node — may carry Strong's number, notes, or plain text |
| `TpOneRow` | Row for `ViewDisplayTable2`; first row = translation labels (title), rest = verse content |

### Event System

`VCRead` uses `IjnEventOnce`-based callbacks wired in `viewDidLoad`:
- `_addrsCurChanged$` → `updateData()` (fetch new data)
- `_dataChanged$` → `drawData()` (re-render table)
- `_versChanged$` → `updateData()` (translation selection changed)
- `_isSnOnChanged$` → `drawData()` (Strong's numbers toggle)

### Shared Display Core

`ViewDisplayTable2` (`v2` in `VCRead`) is reused by both **Read** and **Search** modes (`.ModeOrig` vs search mode). The key method is `_tryQueryDataThenUpdate` — it batch-queries multiple verses when cells come into view. Data is passed via a `DataForDrawTable` instance (`iQ`).

### Data Sources

- **SQLite** (`BibleGetterViaSQLiteFile`): local `.sqlite` files downloaded per version
- **FHL API** (`BibleGetterViaFhlApiQsb`): remote HTTP API, used as fallback when SQLite not present
- Both paths funnel through `BibleText2DText` to produce `DText[]`

### Search Flow

`VCRead.doSearch()` → `VCSearching` (keyword + history picker) → back to `VCRead` → `VCSearchResult`

In `VCSearchResult`: API result stored in `_searchResult` → `DataForDrawTable` transforms it → `_dataForTable` → `ViewDisplayTable2`. Changing filter/translation options requires re-creating `DataForDrawTable`.

### Dependencies

- `FHLCommon` — shared framework imported by most files
- `FMDB` — SQLite wrapper
- `ZIPFoundation` — downloading/unzipping Bible version files
- `AVFoundation` — audio playback
