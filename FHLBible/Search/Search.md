#  Search

> 2026-10-22 起「搜尋ing」「搜尋結果」兩個畫面改為 SwiftUI（見 `ai-log/2026/s4/1022b_search_screens_swiftui.md`）。
> 下面「進入點」與「資料流」是現況；最後的「舊版（UIKit）筆記」保留給考古，檔案名稱與類別已不是現在的樣子。

## 進入點

- 進入點是 `VCRead` 裡的 `doSearching()`（工具列的放大鏡）
  - 先 push `VCSearching()`：`UIHostingController<SearchingView>`，畫面在 `ViewSearching.swift`（`SearchingView`／`SearchingModel`）。系統搜尋列（`.searchable`）+ 搜尋記錄，一進來就聚焦。
  - `VCSearching` 只是選一個「關鍵字」：按搜尋鍵、點「搜尋「…」」或點記錄都會先 pop 掉自己，再用 `onClickSearching$`（`IjnEventOnce<UIView,DText>`）通知 `VCRead`。
  - `VCRead` 收到後 push `VCSearchResult(keyword:vers:addr:)`。「彙編」（字典、點 SN）也直接建立 `VCSearchResult`（`SnDTextClickFlow`、`VCSnDict`）。

## 搜尋ing（SearchingView）

- 記錄存在 `ManagerSearchHistory.s.cur`（UserDefaults 字串陣列，新的在最前）。送出（含點記錄）都會把該字移到最前面、去頭尾空白；空字串不搜尋。
- 邊輸入邊用 `localizedCaseInsensitiveContains` 過濾記錄；輸入中最上面多一列「搜尋「…」」。
- 左滑刪除單筆；清單最後的「清除搜尋記錄」與導覽列垃圾桶都會先確認。（搜尋列聚焦時系統會收起導覽列，所以清單裡也放一個。）
- 沒有記錄也沒輸入時，顯示說明（關鍵字用空格分開、也可輸入 H430／G3056 這種原文編號）。

## 搜尋結果（SearchResultView）

```
SearchQ (fhlSe, 每譯本分頁 500 筆)  --> DSearchResult (所有 DAddress + 每書/每分類筆數 + 建議篩選)
  -> SearchResultModel.makeFilters()  標籤（書卷、分類）+ 建議篩選
  -> SearchResultModel.applyFilter()   rows（只有位置）+ 新的 DataForDrawTable（舊的標 isAlreadyNoUse）
  -> 列出現在畫面上: rowAppeared(i) -> DataForDrawTable.queryDataAsync([i-10 ..< i+30]) （15 秒內不重複要）
  -> onDatasGetter$ -> 主執行緒 absorb() -> rows[i].cells = 已上色的 [[DText]]
  -> SearchRowView -> DTextContentView -> ViewDisplayCell
```

- 畫面：上方篩選列 `SearchFilterBar`（`ViewSearchFilter.swift`；左邊 分類/書卷 分段選單，右邊橫向標籤＋筆數），下面一節一列（位置 + 每個譯本；寬螢幕左右並排）。
- 標題：關鍵字；副標題「搜尋中...」／「共 N 筆」。右上角 SN 開關（只對搜尋結果，不影響閱讀；搜原文編號時預設開；譯本不含和合本/KJV/和合本2010 時停用）。
- 點節的位置 → 譯本比較／Parsing／註釋／串珠；點經文中的 SN／參照／注腳 → 與閱讀相同的流程（`SnDTextClickFlow`／`RefDTextClickFlow`／`FooterDTextClickFlow`）。
- 上色：`SearchKeywordColorer`（原 `_colorKeyword`）。原文編號：只在 unv/kjv 把相同 SN 的字標成顏色 0；關鍵字：以空格切開，每個關鍵字一個括號群組，比對到第幾群就用第幾種顏色（`DText.keyIdx0based`）。規則式不合法時只是不上色。
- 空結果：說明 + 「重試」（`SearchQ` 不分辨「沒有結果」與「網路失敗」）。

## 舊版（UIKit）筆記（已不是現況）

- 舊流程：`VCRead.doSearch` → `VCSearching`（`ViewSearching` xib + UITableView）→ `VCSearchResult`（storyboard，`ViewSearchFilter` xib 按鈕列 + `ViewDisplayTable2`）。
- 舊的繪圖事件：`_onSearchResultChanged$`；`_searchResult` → `DataForDrawTable` → `_dataForTable` → `ViewDisplayTable2`。
- `ViewDisplayTable2`（`UITableView`）的 `_tryQueryDataThenUpdate` 在 cellForRow 時缺資料就一次查附近 ±20 節；現在這個工作由 `SearchResultModel.rowAppeared` 接手，`DataForDrawTable` 本身沒改。
- `ViewDisplayTable2`／`ViewDisplayRow` 已沒有畫面使用，但檔案還在。
