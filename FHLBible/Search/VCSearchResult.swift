//
//  VCSearchResults.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon

/// 搜尋結果。畫面是 SwiftUI (`SearchResultView`)，經文內容仍用 `ViewDisplayCell` (UITextView，點到 SN、參照、注腳要逐字判定)。
/// 以 `VCSearchResult(keyword:vers:addr:)` 建立後 push，不再經由 storyboard。
/// `addr` 是從哪一節進來搜尋的：決定一開始建議篩選哪個書卷／分類，也是點到參照時的預設章。
class VCSearchResult : UIHostingController<SearchResultView> {
    private let model: SearchResultModel

    init(keyword: String, vers: [String], addr: DAddress) {
        let m = SearchResultModel(keyword: keyword, vers: vers, addr: addr)
        self.model = m
        super.init(rootView: SearchResultView(model: m, actions: SearchResultActions()))
        var a = SearchResultActions()
        a.tap = { [weak self] row, col, dtext in self?.doWhenContentClicked(row, col, dtext) }
        a.verseAction = { [weak self] row, act in self?.doVerseAction(row, act) }
        a.retry = { [weak m] in m?.search() }
        rootView = SearchResultView(model: m, actions: a)
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = SearchResultModel(keyword: "", vers: ["unv"], addr: DAddress(1,1,1))
        self.model = m
        super.init(coder: aDecoder, rootView: SearchResultView(model: m, actions: SearchResultActions()))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.search()
    }

    /// 點擊內容：SN 跳選單、參照開閱讀、注腳開 Footer
    private func doWhenContentClicked(_ row: SearchRow, _ col: Int, _ dtext: DText) {
        let vers = model.vers
        if dtext.sn != nil {
            SnDTextClickFlow(vc: self, addr: row.addr, vers: vers).mainAsync(dtext)
        } else if dtext.refDescription != nil {
            RefDTextClickFlow(vc: self, addr: model.addr, vers: vers).mainAsync(dtext)
        } else if dtext.foot != nil, vers.indices.contains(col) {
            FooterDTextClickFlow(vc: self, vers: vers).mainAsync(dtext, vers[col], row.addr)
        }
    }
    /// 點節的位置後，選了要作什麼功能
    private func doVerseAction(_ row: SearchRow, _ act: VerseAction) {
        let push = { (vc: UIViewController) in
            self.navigationController?.pushViewController(vc, animated: false)
        }
        switch act {
        case .InfoTsk:
            push(VCTsk(addr: row.addr))
        case .InfoComment:
            push(VCComment(addr: row.addr))
        case .VersionsCompare:
            push(VCVersionsCompareInOneVerse(addr: row.addr))
        case .InfoParsing:
            push(VCParsing(addr: row.addr, vers: model.vers))
        }
    }
}

// MARK: - Model

/// 篩選的組別。rawValue 同時是 `SearchData.Filter.na2` 的值（程式內部用，不是畫面文字，畫面文字要走 NSLocalizedString）
enum SearchFilterGroup: String {
    case classor = "分類"
    case book = "書卷"
}

/// 一個譯本（一欄）
struct SearchColumn {
    /// 譯本中文名，例如 和合本
    let name: String
    /// 台語、客語漢字需要特殊字型
    let isFontOpenHan: Bool
    /// 希伯來文靠右、英文靠左、其它左右對齊
    let alignment: NSTextAlignment
}

/// 一節搜尋結果（一列）。`cells` 是 nil 表示經文還沒取到
struct SearchRow: Identifiable {
    let id: Int
    let addr: DAddress
    /// 例如 創 1:3
    let address: String
    /// 每個譯本一個 `[DText]`，已經把關鍵字上色
    var cells: [[DText]]?
}

/// View 要作的事，由 `VCSearchResult` 實作 (需要 push 其它畫面)
struct SearchResultActions {
    var tap: (SearchRow, Int, DText) -> Void = { _, _, _ in }
    var verseAction: (SearchRow, VerseAction) -> Void = { _, _ in }
    var retry: () -> Void = { }
}

/// 搜尋結果的狀態：搜尋進度、篩選、目前篩選下的每一節（經文捲到才取）、SN 開關
///
/// 資料流：api (`SearchQ`) -> `searchResult` (全部位置與統計) -> 依目前篩選轉成 `rows` (只有位置)
/// -> 列出現在畫面上時，用 `DataForDrawTable` 一次取附近的 40 節 -> 回主執行緒補進 `rows[i].cells`。
/// 換篩選要重新 new `DataForDrawTable`（舊的標成不再使用，晚回來的資料就會被丟掉）。
@Observable
final class SearchResultModel {
    enum Phase { case searching, done }

    let keyword: String
    let vers: [String]
    /// 從哪一節進來搜尋
    let addr: DAddress
    let columns: [SearchColumn]

    var phase: Phase = .searching
    /// 搜尋中，目前各譯本累計找到的筆數
    var foundCount = 0
    /// 全部找到幾節（不分篩選）
    var totalCount = 0

    // 篩選：filters 是全部標籤；group 是畫面上目前顯示哪一組；selected* 是真正套用的那一個
    var filters: [SearchData.Filter] = []
    var group: SearchFilterGroup = .classor
    var selectedGroup: SearchFilterGroup = .classor
    var selectedOpt: String = ""

    /// 目前篩選下的每一節
    var rows: [SearchRow] = []
    /// 換一次篩選加 1，讓清單回到最上面
    var filterToken = 0

    /// 搜尋結果的 SN 開關，不要用到全域的（全域的是閱讀用的）。搜的是原文編號時預設開
    var isSnVisible: Bool
    /// SN 開關變了就加 1，讓 UIKit 內容重畫
    var snGeneration = 0

    /// 點了節的位置，要跳功能選單的那一列
    var verseActionRow: Int?

    @ObservationIgnored private var searchResult: DSearchResult?
    @ObservationIgnored private var table: DataForDrawTable?
    /// 已經要求取得的列與時間；太久沒回來（失敗）的才會再要一次
    @ObservationIgnored private var requested: [Int: Date] = [:]
    @ObservationIgnored private var progress: [String: Int] = [:]
    @ObservationIgnored private var searchId = 0

    init(keyword: String, vers: [String], addr: DAddress) {
        self.keyword = keyword
        self.vers = vers
        self.addr = addr
        let isOpenHans = BibleVersionFonts().mainIsOpenHanBibleTCs(vers)
        let alignments = getTpTextAlignmentsViaBibleVersions(vers)
        columns = vers.indices.map { i in
            SearchColumn(name: BibleVersionConvertor().na2cna(vers[i]),
                         isFontOpenHan: isOpenHans[i],
                         alignment: alignments[i])
        }
        let sn = SnHelper()
        sn.main(keyword)
        isSnVisible = sn.sn != nil
    }

    /// 當譯本不含 和合本、KJV、和合本2010 時，SN 無法顯示
    var isSnAvailable: Bool { vers.ijnAny({ ["unv","kjv","rcuv"].contains($0) }) }
    func toggleSn() {
        isSnVisible.toggle()
        snGeneration += 1
    }
    var visibleFilters: [SearchData.Filter] { filters.filter { $0.na2 == group.rawValue } }
    func isSelected(_ f: SearchData.Filter) -> Bool {
        f.na2 == selectedGroup.rawValue && f.na == selectedOpt
    }

    // MARK: 搜尋

    func search() {
        searchId += 1
        let id = searchId
        phase = .searching
        foundCount = 0
        progress = [:]
        rows = []
        table?.isAlreadyNoUse = true
        table = nil

        let pa = DSearchParameters()
        pa.keywords = keyword
        pa.addr = addr
        pa.vers = vers

        let se: ISearchQ = SearchQ()
        se.onSearchResultFinished$.addCallback { [weak self] _, _ in
            // 在主執行緒觸發 (SearchQ 用 DispatchGroup.notify(queue: .main))
            guard let self = self, self.searchId == id else { return }
            self.searchResult = se.searchResult
            self.finishSearch()
        }
        // 各譯本分開抓，callback 不在主執行緒。sender 是譯本代碼，pData 是該譯本累計筆數
        se.onProgressChanged$.addCallback { [weak self] ver, cnt in
            guard let ver = ver, let cnt = cnt else { return }
            DispatchQueue.main.async {
                guard let self = self, self.searchId == id else { return }
                self.progress[ver] = cnt
                self.foundCount = self.progress.values.reduce(0, +)
            }
        }
        se.mainAsync(pa)
    }

    private func finishSearch() {
        guard let result = searchResult else {
            totalCount = 0
            filters = []
            rows = []
            phase = .done
            return
        }
        totalCount = result.datas.count
        makeFilters(result)
        applyFilter()
        phase = .done
    }

    /// 統計結果轉成標籤：每卷書一個、每個分類一個；並套用建議的篩選（進來搜尋的那卷書、或包含它的分類）
    private func makeFilters(_ r: DSearchResult) {
        let names = BibleBookNames.getBookNames(ManagerLangSet.s.curTpBookNameLang)

        var all = r.cntBook.sorted { $0.key < $1.key }
            .compactMap { (key, value) -> SearchData.Filter? in
                guard names.indices.contains(key - 1) else { return nil }
                return SearchData.Filter(names[key - 1], value, SearchFilterGroup.book.rawValue)
            }
        let classors = ManagerLangSet.s.curBookClassorNaOrder.map { a1 -> SearchData.Filter in
            SearchData.Filter(a1, r.cntClassor[a1] ?? 0, SearchFilterGroup.classor.rawValue)
        }.filter { $0.cnt > 0 }
        all.append(contentsOf: classors)
        filters = all

        if let cls = r.suggestClassor {
            selectedGroup = .classor
            selectedOpt = cls
        } else if let bk = r.suggestBook, names.indices.contains(bk - 1) {
            selectedGroup = .book
            selectedOpt = names[bk - 1]
        } else {
            selectedGroup = .classor
            selectedOpt = ""
        }
        group = selectedGroup
    }

    func select(_ f: SearchData.Filter) {
        guard let g = SearchFilterGroup(rawValue: f.na2) else { return }
        if isSelected(f) { return }
        selectedGroup = g
        selectedOpt = f.na
        applyFilter()
    }

    /// 依目前篩選，列出要顯示的節（只有位置，經文捲到才取）
    private func applyFilter() {
        table?.isAlreadyNoUse = true
        requested = [:]
        filterToken += 1

        let addrs = filteredAddresses()
        let t = DataForDrawTable(vers, addrs, SearchKeywordColorer(keyword: keyword, vers: vers).colorIt)
        t.onDatasGetter$.addCallback { [weak self, weak t] _, _ in
            // 不一定在主執行緒
            guard let t = t, !t.isAlreadyNoUse else { return }
            DispatchQueue.main.async {
                guard let self = self, self.table === t else { return }
                self.absorb(t)
            }
        }
        table = t

        let tp = ManagerLangSet.s.curTpBookNameLang
        rows = addrs.enumerated().map { SearchRow(id: $0.offset, addr: $0.element, address: $0.element.toString(tp), cells: nil) }
    }

    private func filteredAddresses() -> [DAddress] {
        guard let r = searchResult else { return [] }
        switch selectedGroup {
        case .classor:
            // 找不到對應的分類（例如沒有任何結果時）就是空的
            guard let books = ManagerLangSet.s.curBookClassor.first(where: { $0.key == selectedOpt })?.value else { return [] }
            return r.datas.filter { books.contains($0.book) }
        case .book:
            let idbook = BibleBookNameToId().main1based(ManagerLangSet.s.curTpBookNameLang, selectedOpt)
            return r.datas.filter { $0.book == idbook }
        }
    }

    // MARK: 經文（捲到才取）

    /// 某一列出現在畫面上。一次取附近的幾十節，比一節一節取有效率
    func rowAppeared(_ index: Int) {
        guard let t = table, rows.indices.contains(index) else { return }
        let lo = max(0, index - 10)
        let hi = min(rows.count, index + 30)
        let now = Date()
        let need = (lo..<hi).filter { i in
            if rows[i].cells != nil { return false }
            if let at = requested[i], now.timeIntervalSince(at) < 15 { return false }
            return true
        }
        if need.isEmpty { return }
        need.forEach { requested[$0] = now }
        t.queryDataAsync(need)
    }
    /// 把 DataForDrawTable 取到的經文補進 rows
    private func absorb(_ t: DataForDrawTable) {
        let datas = t.datas
        for i in Array(requested.keys) where rows.indices.contains(i) && rows[i].cells == nil {
            if let cells = datas[i]?.1 {
                rows[i].cells = cells
                requested.removeValue(forKey: i)
            }
        }
    }
}

/// 把關鍵字（或 SN）在取到的經文裡上色。`DataForDrawTable` 每取到一節就呼叫一次，不一定在主執行緒。
private struct SearchKeywordColorer {
    let keyword: String
    let vers: [String]

    func colorIt(_ dataOneRow: ViewDisplayTable2.OneRow) {
        let snHelper = SnHelper()
        snHelper.main(keyword)
        if snHelper.sn != nil {
            colorSn(dataOneRow, snHelper)
        } else {
            colorKeywords(dataOneRow, snHelper)
        }
    }

    private func colorSn(_ dataOneRow: ViewDisplayTable2.OneRow, _ snHelper: SnHelper) {
        func doDts(_ dts: [DText]) {
            for a1 in dts {
                if a1.children != nil {
                    doDts(a1.children!)
                } else if a1.sn == snHelper.sn && a1.tp == snHelper.snTp {
                    a1.keyIdx0based = 0
                }
            }
        }
        for i in 0..<vers.count {
            if i >= dataOneRow.datas.count { continue }
            // 只有這2個譯本才會有 sn
            if ["unv","kjv"].contains(vers[i]) {
                doDts(dataOneRow.datas[i])
            }
        }
    }

    private func colorKeywords(_ dataOneRow: ViewDisplayTable2.OneRow, _ snHelper: SnHelper) {
        // 核心，可看 testSearchKeyword。關鍵字以空格分開，每個一組括號，才知道比對到的是第幾個關鍵字（顏色不同）
        let r1 = snHelper.keyword.split(separator: " ")
        let r2 = r1.map({"(\($0))"}).joined(separator: "|")
        // 關鍵字若含括號等符號，組出來的規則式可能不合法；不合法就只是不上色，不要當掉
        guard let r3 = try? NSRegularExpression(pattern: r2, options: [.caseInsensitive]) else { return }

        func doDtext(_ dt: DText) {
            // assert ( dt.children == nil )
            if dt.isCantSplit() { return }

            let r1 = SplitByRegex().main(str: dt.w!, reg: r3)
            if r1 == nil { return }

            var re: [DText] = []
            for a1 in r1! {
                let r2 = dt.clone()
                r2.w = String(a1.w)
                re.append(r2)
                if a1.isMatch() {
                    var idx: Int {
                        for i in 1..<a1.exec.count {
                            if a1.exec[i] != nil { return i }
                        }
                        return 0 // 雖然不可能，但還是給它一個預設值吧
                    }
                    r2.keyIdx0based = idx - 1
                    if r2.keyIdx0based == -1 { r2.keyIdx0based = 0 }
                }
            }
            dt.children = re
            dt.w = nil
            dt.tpContain = ""
        }
        func doDTexts(_ dts: [DText]) {
            for a1 in dts {
                if a1.children != nil {
                    doDTexts(a1.children!)
                } else {
                    doDtext(a1)
                }
            }
        }
        for a1 in dataOneRow.datas {
            doDTexts(a1)
        }
    }
}

// MARK: - View

/// 搜尋結果畫面：上方篩選列（分類／書卷），下面一節一列：位置（點了選功能）+ 每個譯本的經文（寬螢幕左右並排）。
/// 搜尋中顯示進度，沒有結果時說明並可重試。
struct SearchResultView: View {
    let model: SearchResultModel
    let actions: SearchResultActions
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(model.keyword)
                            .font(.headline)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: Binding(get: { model.isSnVisible }, set: { _ in model.toggleSn() })) {
                        Text("SN")
                    }
                    .toggleStyle(.button)
                    .disabled(!model.isSnAvailable)
                }
            }
    }

    private var subtitle: String {
        switch model.phase {
        case .searching:
            return NSLocalizedString("搜尋中...", comment: "")
        case .done:
            return String(format: NSLocalizedString("共 %@ 筆", comment: ""), model.totalCount.formatted())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .searching:
            VStack(spacing: 12) {
                ProgressView()
                Text(NSLocalizedString("搜尋中...", comment: ""))
                    .foregroundStyle(.secondary)
                if model.foundCount > 0 {
                    Text(String(format: NSLocalizedString("已找到 %@ 筆", comment: ""), model.foundCount.formatted()))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .done:
            if model.totalCount == 0 {
                ContentUnavailableView {
                    Label(String(format: NSLocalizedString("找不到「%@」", comment: ""), model.keyword), systemImage: "magnifyingglass")
                } description: {
                    Text(NSLocalizedString("沒有符合的經文。請換個關鍵字，或確認網路連線後再試一次。", comment: ""))
                } actions: {
                    Button(NSLocalizedString("重試", comment: ""), action: actions.retry)
                        .buttonStyle(.bordered)
                }
            } else {
                list
            }
        }
    }

    private var list: some View {
        List {
            ForEach(model.rows) { row in
                SearchRowView(model: model, row: row, actions: actions, isWide: sizeClass == .regular)
                    .onAppear { model.rowAppeared(row.id) }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        // 換篩選要回到最上面
        .id(model.filterToken)
        .overlay {
            if model.rows.isEmpty {
                ContentUnavailableView(NSLocalizedString("此篩選沒有結果", comment: ""), systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            SearchFilterBar(model: model)
        }
    }
}

/// 一節：上方是位置（點了選功能），下面是每個譯本一塊經文；還沒取到經文時顯示轉圈
struct SearchRowView: View {
    let model: SearchResultModel
    let row: SearchRow
    let actions: SearchResultActions
    let isWide: Bool

    var body: some View {
        // 經文的 UITextView 自己就有上方內距，這裡不再加間距
        VStack(alignment: .leading, spacing: 0) {
            Button {
                model.verseActionRow = row.id
            } label: {
                HStack(spacing: 4) {
                    Text(row.address)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.tint)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(row.address)
            // 掛在位置上，選單才會從被點的那一節冒出來
            .confirmationDialog(row.address,
                                isPresented: Binding(get: { model.verseActionRow == row.id },
                                                     set: { if !$0 { model.verseActionRow = nil } }),
                                titleVisibility: .visible) {
                Button(NSLocalizedString("譯本比較", comment: "")) { actions.verseAction(row, .VersionsCompare) }
                Button("Parsing") { actions.verseAction(row, .InfoParsing) }
                Button(NSLocalizedString("註釋", comment: "")) { actions.verseAction(row, .InfoComment) }
                Button(NSLocalizedString("串珠", comment: "")) { actions.verseAction(row, .InfoTsk) }
            }

            if let cells = row.cells {
                if isWide && model.columns.count > 1 {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(model.columns.indices, id: \.self) { col in
                            cellView(cells, col).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(model.columns.indices, id: \.self) { col in
                            cellView(cells, col)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func cellView(_ cells: [[DText]], _ col: Int) -> some View {
        if cells.indices.contains(col) {
            let column = model.columns[col]
            VStack(alignment: .leading, spacing: 2) {
                if model.columns.count > 1 {
                    Text(column.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                DTextContentView(dtexts: cells[col],
                                 generation: model.snGeneration,
                                 isVisibleSn: model.isSnVisible,
                                 onTapRef: { _ in },
                                 isFontOpenHan: column.isFontOpenHan,
                                 alignment: column.alignment,
                                 onTapAny: { dtext in actions.tap(row, col, dtext) })
            }
        }
    }
}
