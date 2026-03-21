
# 進入點

- `VCRead` class
- 在 `viewDidLoad` 中，可以看到很多 callback。其中關鍵的有 `drawData` 與 `updateData`。
  - 很直覺的， `updateData` 是準備要重抓資料，抓完會觸發 `_dataChanged` 事件、也會更新 `_data`。
  - 很直覺的， `_dataChanged` 觸發，就會呼叫 `drawData`，從 `drawData` 中就可以看到繪圖核心 class `ViewDisplayTable2`，它在 class 叫 `v2`

# 抓資料

- 資料最後給 `v2` 時，是由 TpOneRow 組成，這設計的很直覺，因為 v2 本質是一個 tableview，所以它由多個 row 組成。而分成 title 與 data 是因為，title 那一列，就是置中對齊，它是放 `譯本` 用的，而 data 就是放 `經文內容` 用的。
- 以 設計概念 來說，傳給 v2 的資料，就應該是轉換好，是要顯示的資料，而不是原始的 `api` 結果。
- `ReadDataQ` class 是核心函式，但我猜它是由 api 相關、 轉換 相關、兩個組成，但猜錯了，實際上，它是由 `BibleReadDataGetter` 為關鍵，而 ReadDataQ 不過是將資料轉成 TpOneRow 的過程。
- `BibleReadDataGetter` 的本質，不是抓資料。因為是多個譯本，但是 api 卻是一次抓一個譯本，所以它是 `產生多個執行緒，並且整合多個執行緒取得的結果`，這就是它的本質。
- 真正在作 `資料轉換` 的，是叫 `BibleText2DText` class 的。

# 資料轉換

- 不論是從 api 還是 sqlite 抓取過來的資料，都要轉換成最終 ui 要用的 DText[]，這是 `BibleText2DText` class 的工作。
- 誰使用它呢？ 搜尋後，就會發現有 2 個人使用它，一個是 `BibleGetterViaSQLiteFile` 一個是 `QsbRecords2DOneLines01`。 第 2 個其它就是 From Api 的。


