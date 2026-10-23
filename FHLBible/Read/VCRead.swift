import Foundation
import UIKit
import SwiftUI
import AVFoundation
import FHLCommon
import OSLog

/*

 閱讀畫面 (SwiftUI)

 - `VCRead` 是 `UIHostingController<ReadView>`，用 `VCRead()` 建立，呼叫 `setInitData` 後 push，不再經由 storyboard。
 - 狀態都在 `ReadModel` (`@Observable`)：目前位址、譯本、每一節每個譯本的 `[DText]`、SN 開關、複選狀態。
   換章節、換譯本，都是 `ReadModel.reload()` 重抓資料 (沿用 `ReadDataQ`)，抓完在主執行緒更新 `rows`。
 - 經文內容仍是 `ViewDisplayCell` (UITextView，點到 SN、參照、注腳要逐字判定)，用 `DTextContentView` 包進 SwiftUI。
 - 點擊流程 (SN、參照、注腳、節的功能選單) 與 push 其它畫面，都在 `VCRead`，因為它們需要 UIViewController。
 - 手勢 (左右滑換章、返回上一頁等) 沿用 `SwipeHelp`。

 */
protocol IVCReadDataQ {
    func qDataForReadAsync(_ addr:String, _ vers: [String])
    var qDataForRead$: IjnEventOnce<Any,(ViewDisplayTable2.OneRow,[ViewDisplayTable2.OneRow])> { get }
}

class VCRead : UIHostingController<ReadView> {
    private let model: ReadModel
    private var saver: SaveToPhotoHelper?

    init() {
        let m = ReadModel()
        self.model = m
        super.init(rootView: ReadView(model: m, actions: ReadActions()))
        rootView = ReadView(model: m, actions: makeActions())
        // 之後 push 的畫面，返回鈕會寫這個
        title = NSLocalizedString("閱讀", comment: "")
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = ReadModel()
        self.model = m
        super.init(coder: aDecoder, rootView: ReadView(model: m, actions: ReadActions()))
    }

    /// 供還沒顯示前呼叫, 它不會去 trigger
    /// vers是設 [unv, cnv] 這些
    func setInitData(_ addr:VerseRange,_ vers:[String]){
        model.setInitData(addr, vers)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        _swipeHelp.addSwipe(dir: .left, numberOfTouches: 1)
        _swipeHelp.addSwipe(dir: .left, numberOfTouches: 3)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.addSwipe(dir: .right, numberOfTouches: 2)
        _swipeHelp.addSwipe(dir: .right, numberOfTouches: 3)
        _swipeHelp.onSwipe$.addCallback {[weak self] sender, pData in
            guard let self = self, let pData = pData else { return }
            // 複選中，手勢不換章，避免選到一半被換掉
            if self.model.isSelecting { return }

            if pData.direction == .left {
                if pData.numberOfTouchesRequired == 1 {
                    self.model.goNext()
                } else if pData.numberOfTouchesRequired == 3 {
                    self.pickBookChap()
                }
            } else if pData.direction == .right {
                if pData.numberOfTouchesRequired == 1 {
                    self.model.goPrev()
                } else if pData.numberOfTouchesRequired == 2 {
                    self.model.clickGoBack()
                } else if pData.numberOfTouchesRequired == 3 {
                    self.pickFromHistory()
                }
            }
        }

        model.reload()
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view, viewController: self)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 當交互參照 push 後，再 back 時，要再把 history 換到目前變第1個
        model.addToReadHistory()
        model.idxGoBack = 0
        _swipeHelp.onViewWillAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _swipeHelp.onViewWillDisappear()
    }

    private func makeActions() -> ReadActions {
        var a = ReadActions()
        a.pickBookChap = { [weak self] in self?.pickBookChap() }
        a.pickVers = { [weak self] in self?.pickVersions() }
        a.search = { [weak self] in self?.doSearching() }
        a.history = { [weak self] in self?.pickFromHistory() }
        a.audioBible = { [weak self] in self?.pushAudioBible() }
        a.audioText = { [weak self] in self?.pushAudioText() }
        a.makeImage = { [weak self] in self?.generateImage() }
        a.confirmSelection = { [weak self] in self?.confirmSelection() }
        a.tap = { [weak self] row, col, dtext in self?.doWhenContentClicked(row, col, dtext) }
        a.verseAction = { [weak self] row, act in self?.doVerseAction(row, act) }
        return a
    }

    private func push(_ vc: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(vc, animated: animated)
    }

    // MARK: 選擇其它位置、譯本

    private func pickBookChap(){
        // 準備「目前的」給 dialog 初始參數
        let cur = model.addrFirst
        let r1 = BookChapPickerViewController(book: cur?.book ?? 1, chap: cur?.chap ?? 1)
        r1.onClick$.addCallback {[weak self] sender, pData in
            guard let self = self, let pData = pData else { return }

            let r2 = VerseRange()
            r2.verses = DAddress(book: pData.idBook, chap: pData.idChap, verse: 1).generateEntireThisChap()
            self.model.setAddr(r2)
        }
        push(r1, animated: false)
    }
    private func pickFromHistory(){
        let vc1 = VCReadHistory()
        vc1.onClickAddr$.addCallback {[weak self] sender, pData in
            guard let self = self, let pData = pData else { return }

            self.model.setAddr(VerseRange(StringToVerseRange().main(pData)))
        }
        push(vc1, animated: false)
    }
    private func pickVersions(){
        let vc1 = VCVersionsPicker(vers: model.vers)
        vc1.onClickOkay$.addCallback {[weak self] sender, pData in
            guard let self = self, let pData = pData else { return }
            // 情境: 雖然按 okay, 但其實譯本沒變, (順序、內容), 就不要再取一次
            self.model.setVers(pData)
        }
        push(vc1, animated: false)
    }
    private func doSearching(){
        let vc2 = VCSearching()
        vc2.onClickSearching$.addCallback {[weak self] sender, pData in
            guard let self = self, let w = pData?.w, let addr = self.model.addrFirst else { return }

            self.push(VCSearchResult(keyword: w, vers: self.model.vers, addr: addr), animated: false) // pData '天使'
        }
        push(vc2, animated: false)
    }
    private func pushAudioBible(){
        guard let addr = model.addrFirst else { return }
        push(VCAudioBible(book: addr.book, chap: addr.chap))
    }
    private func pushAudioText(){
        push(VCAudioTextBible(addr: model.addr, vers: model.vers))
    }

    // MARK: 點擊內容

    /// 點擊經文：SN 跳選單、參照開閱讀、注腳開 Footer
    private func doWhenContentClicked(_ row: ReadRow, _ col: Int, _ dtext: DText){
        let vers = model.vers
        // 以「該節」的位置為準，因為可能是複合型 read，即 羅1:2;創1:3
        guard let addrThisRow = row.addr ?? model.addrFirst else { return }

        if dtext.sn != nil {
            SnDTextClickFlow(vc: self, addr: addrThisRow, vers: vers).mainAsync(dtext)
        } else if dtext.refDescription != nil {
            guard let addrPage = model.addrFirst else { return }
            RefDTextClickFlow(vc: self, addr: addrPage, vers: vers).mainAsync(dtext)
        } else if dtext.foot != nil, vers.indices.contains(col) {
            FooterDTextClickFlow(vc: self, vers: vers).mainAsync(dtext, vers[col], addrThisRow)
        }
    }
    /// 點擊節的位置後，選了要作什麼功能
    private func doVerseAction(_ row: ReadRow, _ act: VerseAction){
        guard let addr = row.addr ?? model.addrFirst else { return }

        switch act {
        case .InfoTsk:
            push(VCTsk(addr: addr), animated: false)
        case .InfoComment:
            push(VCComment(addr: addr), animated: false)
        case .VersionsCompare:
            push(VCVersionsCompareInOneVerse(addr: addr), animated: false)
        case .InfoParsing:
            push(VCParsing(addr: addr, vers: model.vers), animated: false)
        }
    }

    // MARK: 複選、圖片

    /// 複選後按「完成」，開啟複製、產生圖片等功能的畫面
    private func confirmSelection(){
        let vc = VCWhenLongPress(dataSelections: model.makeSelections())
        model.endSelection()
        push(vc, animated: false)
    }
    /// 把目前這章 (含所有譯本) 畫成一張長圖，存到相簿。
    /// 不是截 SwiftUI 畫面，因為 List 只會畫出看得到的列；改用一個離螢幕的 UIStackView 全部排好再畫。
    private func generateImage(){
        let width = view.bounds.width
        guard let image = ReadSnapshotRenderer(model: model, width: width, scale: traitCollection.displayScale).render() else {
            MessageBox.ok(vc: self, msg: NSLocalizedString("產生影像失敗", comment: ""))
            return
        }
        let saver = SaveToPhotoHelper()
        self.saver = saver
        saver.main(vc: self, img: image)
    }
}

// MARK: - Model

/// 一格 = 一節 (row) 的一個譯本 (col, 0-based)
struct ReadCellKey: Hashable {
    let row: Int
    let col: Int
}

/// 一個譯本 (一欄)
struct ReadColumn {
    /// 譯本代碼，例如 unv
    let ver: String
    /// 譯本中文名，例如 和合本
    let name: String
    /// 台語、客語漢字需要特殊字型
    let isFontOpenHan: Bool
    /// 希伯來文靠右、英文靠左、其它左右對齊
    let alignment: NSTextAlignment
}

/// 一節經文 (一列)
struct ReadRow: Identifiable {
    let id: Int
    /// 例如 創1:1 (多節合併時是 創1:1-2)，沒有經文時是空字串
    let address: String
    /// 此節的第一個位置，轉換失敗是 nil
    let addr: DAddress?
    /// 畫面上顯示的節號。整頁都是同一章時只顯示節號 (1)，否則顯示完整位置 (羅1:2)
    let label: String
    /// 每個譯本一個 `[DText]`
    let cells: [[DText]]
}

/// 閱讀的狀態：目前位址、譯本、資料、SN 開關、複選
@Observable
final class ReadModel {
    var addr: VerseRange = VerseRange()
    var vers: [String] = ["unv"]
    var columns: [ReadColumn] = []
    var rows: [ReadRow] = []
    var isLoading = false
    /// 每載入一次、或 SN 開關變了就加 1，讓 UIKit 內容只在真的要重畫時才重畫
    var generation: Int = 0
    var isSnVisible: Bool = ManagerIsSnVisible.s.cur

    /// 複選
    var isSelecting = false
    var selected: Set<ReadCellKey> = []

    /// 點了節的位置，要跳功能選單的那一列 (`ReadRow.id`)
    var verseActionRow: Int?

    /// 按 GoBack 時，考慮連續按的時候，它就是一直往前
    @ObservationIgnored var idxGoBack = 0
    @ObservationIgnored private var requestId = 0

    /// 呼叫 setInitData 後再開啟此，不會 trigger 重抓
    func setInitData(_ addr: VerseRange, _ vers: [String]) {
        self.addr = addr
        self.vers = vers.isEmpty ? ["unv"] : vers
    }

    var addrFirst: DAddress? { addr.verses.first }
    var titleAddr: String {
        if addr.verses.isEmpty { return "" }
        return VerseRangeToString().main(addr.verses, ManagerLangSet.s.curTpBookNameLang)
    }
    /// 當譯本不含 和合本、和合本2010、KJV 時，SN 無法顯示
    var isSnAvailable: Bool { vers.ijnAny({ ["unv","kjv","rcuv"].contains($0) }) }
    /// 底部「譯本」鈕上的文字
    var versSummary: String {
        let names = vers.map { BibleVersionConvertor().na2cna($0) }
        if names.count <= 1 { return names.first ?? "" }
        return "\(names[0]) +\(names.count - 1)"
    }

    // MARK: 換位置、譯本

    /// 換章節。`isFromGoBack` 是「上一頁」造成的，不要再寫進閱讀記錄，否則會一直往前
    func setAddr(_ a: VerseRange, isFromGoBack: Bool = false) {
        addr = a
        ManagerAddress.s.updateCur(a)
        if !isFromGoBack {
            addToReadHistory()
            idxGoBack = 0
        }
        reload()
    }
    func goNext() { setAddr(addr.goNext()) }
    func goPrev() { setAddr(addr.goPrev()) }
    func clickGoBack() {
        let r1 = ManagerHistoryOfRead.s.cur
        if idxGoBack + 1 >= r1.count { return }
        idxGoBack += 1
        setAddr(VerseRange(StringToVerseRange().main(r1[idxGoBack])), isFromGoBack: true)
    }
    func setVers(_ newVers: [String]) {
        if newVers == vers { return }
        vers = newVers
        ManagerBibleVersions.s.updateCur(newVers)
        reload()
    }
    func toggleSn() {
        isSnVisible.toggle()
        ManagerIsSnVisible.s.updateCur(isSnVisible)
        generation += 1
    }
    /// nil 的時候，會用目前位置
    func addToReadHistory() {
        if addr.verses.isEmpty { return }
        let addr2 = VerseRangeToString().main(addr.verses, ManagerLangSet.s.curTpBookNameLang)
        var r2 = ManagerHistoryOfRead.s.cur

        // 防止重複，但又不用 remove where 是提高效率
        if let r2a = r2.ijnIndexOf(addr2) { r2.remove(at: r2a) }

        r2.insert(addr2, at: 0)
        ManagerHistoryOfRead.s.updateCur(r2)
    }

    // MARK: 資料

    /// 用 addr、vers 重抓。快速連續換章或換譯本時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        let vers = self.vers
        endSelection()
        rows = []
        isLoading = true

        let dataQ: IVCReadDataQ = ReadDataQ()
        dataQ.qDataForRead$.addCallback {[weak self] sender, pData in
            guard let pData = pData else { return }
            DispatchQueue.main.async {
                guard let self = self, self.requestId == id else { return }
                self.setRows(vers, pData.1)
            }
        }
        dataQ.qDataForReadAsync(titleAddr, vers)
    }
    private func setRows(_ vers: [String], _ data: [ViewDisplayTable2.OneRow]) {
        let isOpenHans = BibleVersionFonts().mainIsOpenHanBibleTCs(vers)
        let alignments = getTpTextAlignmentsViaBibleVersions(vers)
        columns = vers.indices.map { i in
            ReadColumn(ver: vers[i],
                       name: BibleVersionConvertor().na2cna(vers[i]),
                       isFontOpenHan: isOpenHans[i],
                       alignment: alignments[i])
        }

        let addresses = data.map { $0.header.map { $0.w ?? "" }.joined() }
        let parsed = addresses.map { StringToVerseRange().main($0, nil).first }
        // 整頁都是同一章，節的標示就只要節號
        let chaps = Set(parsed.compactMap { $0 }.map { $0.book * 1000 + $0.chap })
        let isSingleChap = chaps.count == 1 && parsed.allSatisfy { $0 != nil }

        rows = data.indices.map { i in
            let s = addresses[i]
            var label = s
            if isSingleChap, let r = s.range(of: ":", options: .backwards) {
                label = String(s[r.upperBound...])
            }
            return ReadRow(id: i, address: s, addr: parsed[i], label: label, cells: data[i].datas)
        }
        generation += 1
        isLoading = false
    }

    // MARK: 複選

    /// 從「更多」選單進入，一開始都沒選
    func beginSelecting() {
        selected = []
        isSelecting = true
    }
    /// 長按某一格進入，那一格先選起來
    func startSelecting(row: Int, col: Int) {
        beginSelecting()
        toggle(row: row, col: col)
    }
    func endSelection() {
        isSelecting = false
        selected = []
    }
    func toggle(row: Int, col: Int) {
        let k = ReadCellKey(row: row, col: col)
        if selected.contains(k) { selected.remove(k) } else { selected.insert(k) }
    }
    /// 此節所有譯本；已經全選就全部取消
    func toggleRow(_ row: Int) {
        let keys = vers.indices.map { ReadCellKey(row: row, col: $0) }
        if keys.allSatisfy({ selected.contains($0) }) {
            keys.forEach { selected.remove($0) }
        } else {
            keys.forEach { selected.insert($0) }
        }
    }
    func isRowSelected(_ row: Int) -> Bool {
        !vers.isEmpty && vers.indices.allSatisfy { selected.contains(ReadCellKey(row: row, col: $0)) }
    }
    var isAllSelected: Bool {
        !rows.isEmpty && rows.allSatisfy { isRowSelected($0.id) }
    }
    func toggleSelectAll() {
        if isAllSelected {
            selected = []
        } else {
            selected = Set(rows.flatMap { r in vers.indices.map { ReadCellKey(row: r.id, col: $0) } })
        }
    }
    /// 給「複製、產生圖片」畫面 (VCWhenLongPress) 的資料
    func makeSelections() -> DSelections {
        let selections = DSelections()
        selections.data = [:]

        var isVersionExist: [Bool] = vers.map { _ in false }
        var addresses: [[DAddress]] = []

        for row in rows {
            lazy var addressesThisRow = StringToVerseRange().main(row.address)
            for col in vers.indices where selected.contains(ReadCellKey(row: row.id, col: col)) {
                guard row.cells.indices.contains(col) else { continue }
                if selections.data[addressesThisRow] == nil {
                    selections.data[addressesThisRow] = [:]
                    addresses.append(addressesThisRow)
                }
                selections.data[addressesThisRow]![vers[col]] = row.cells[col]
                isVersionExist[col] = true
            }
        }

        selections.vers = vers.indices.filter { isVersionExist[$0] }.map { vers[$0] }
        selections.addrs = addresses
        return selections
    }
}

// MARK: - View

/// View 要作的事，由 `VCRead` 實作 (需要 push 其它畫面)
struct ReadActions {
    var pickBookChap: () -> Void = { }
    var pickVers: () -> Void = { }
    var search: () -> Void = { }
    var history: () -> Void = { }
    var audioBible: () -> Void = { }
    var audioText: () -> Void = { }
    var makeImage: () -> Void = { }
    var confirmSelection: () -> Void = { }
    var tap: (ReadRow, Int, DText) -> Void = { _, _, _ in }
    var verseAction: (ReadRow, VerseAction) -> Void = { _, _ in }
}

/// 閱讀畫面：一節一列，多個譯本在同一節內上下排 (寬螢幕改左右並排)。
/// 上方：書卷章節 (點了選聖經目錄)、搜尋、SN、更多；下方：譯本、上一章、下一章。
struct ReadView: View {
    let model: ReadModel
    let actions: ReadActions
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            list
            bottomBar
        }
        .sensoryFeedback(.selection, trigger: model.selected.count)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isSelecting)
        .toolbar { toolbarContent }
    }

    private var list: some View {
        List {
            ForEach(model.rows) { row in
                ReadRowView(model: model, row: row, actions: actions, isWide: sizeClass == .regular)
                    .listRowSeparator(model.columns.count > 1 ? .visible : .hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            }
        }
        .listStyle(.plain)
        // 預設一列至少 44pt，單行的節會多出一大塊空白
        .environment(\.defaultMinListRowHeight, 1)
        .overlay {
            if model.isLoading {
                ProgressView(NSLocalizedString("取得資料中...", comment: ""))
            }
        }
    }

    /// 底部：目前的譯本 (點了換譯本)、上一章、下一章。
    /// 不用 .toolbar(.bottomBar)：SwiftUI 畫面放在 UINavigationController (UIHostingController) 時，要自己 setToolbarHidden(false)，
    /// 各系統版本的行為也不一定一樣。直接用 VStack 排在清單下面，所有版本都一樣。
    private var bottomBar: some View {
        HStack(spacing: 8) {
            if model.isSelecting {
                Button(model.isAllSelected ? NSLocalizedString("取消全選", comment: "") : NSLocalizedString("全選", comment: "")) {
                    model.toggleSelectAll()
                }
                Spacer()
            } else {
                Button(action: actions.pickVers) {
                    HStack(spacing: 6) {
                        Image(systemName: "books.vertical")
                        Text(model.versSummary).lineLimit(1)
                    }
                }
                .accessibilityLabel(NSLocalizedString("選擇譯本", comment: ""))
                Spacer()
                Button { model.goPrev() } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .accessibilityLabel(NSLocalizedString("上一章", comment: ""))
                Button { model.goNext() } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .accessibilityLabel(NSLocalizedString("下一章", comment: ""))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .background(.bar, ignoresSafeAreaEdges: .bottom)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if model.isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button(NSLocalizedString("取消", comment: "")) { model.endSelection() }
            }
            ToolbarItem(placement: .principal) {
                Text(String(format: NSLocalizedString("已選取 %d 項", comment: ""), model.selected.count))
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(NSLocalizedString("完成", comment: ""), action: actions.confirmSelection)
                    .fontWeight(.semibold)
                    .disabled(model.selected.isEmpty)
            }
        } else {
            ToolbarItem(placement: .principal) {
                Button(action: actions.pickBookChap) {
                    HStack(spacing: 4) {
                        Text(model.titleAddr)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.titleAddr)
                .accessibilityHint(NSLocalizedString("聖經目錄", comment: ""))
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: actions.search) {
                    Label(NSLocalizedString("搜尋", comment: ""), systemImage: "magnifyingglass")
                }
                Toggle(isOn: Binding(get: { model.isSnVisible }, set: { _ in model.toggleSn() })) {
                    Text("SN")
                }
                .toggleStyle(.button)
                .disabled(!model.isSnAvailable)
                moreMenu
            }
        }
    }

    private var moreMenu: some View {
        Menu {
            Button { model.beginSelecting() } label: {
                Label(NSLocalizedString("選取經文", comment: ""), systemImage: "checkmark.circle")
            }
            .disabled(model.rows.isEmpty)
            Button(action: actions.makeImage) {
                Label(NSLocalizedString("圖片產生", comment: ""), systemImage: "photo")
            }
            .disabled(model.rows.isEmpty)
            Divider()
            Button(action: actions.history) {
                Label(NSLocalizedString("閱讀記錄", comment: ""), systemImage: "clock.arrow.circlepath")
            }
            Button { model.clickGoBack() } label: {
                Label(NSLocalizedString("上一頁", comment: ""), systemImage: "arrowshape.turn.up.left")
            }
            Divider()
            Button(action: actions.audioBible) {
                Label(NSLocalizedString("有聲聖經", comment: ""), systemImage: "speaker.wave.3")
            }
            Button(action: actions.audioText) {
                Label(NSLocalizedString("有聲文字", comment: ""), systemImage: "text.bubble")
            }
        } label: {
            Label(NSLocalizedString("更多", comment: ""), systemImage: "ellipsis.circle")
        }
    }
}

/// 一節：左邊節號 (點了選功能，複選中是整節選取)，右邊每個譯本一塊經文
struct ReadRowView: View {
    let model: ReadModel
    let row: ReadRow
    let actions: ReadActions
    let isWide: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !row.label.isEmpty {
                Button {
                    if model.isSelecting {
                        model.toggleRow(row.id)
                    } else {
                        model.verseActionRow = row.id
                    }
                } label: {
                    Text(row.label)
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.tint)
                        .frame(minWidth: 28, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(row.address)
                // 掛在節號上，選單才會從被點的那一節冒出來
                .confirmationDialog(row.address,
                                    isPresented: Binding(get: { model.verseActionRow == row.id },
                                                         set: { if !$0 { model.verseActionRow = nil } }),
                                    titleVisibility: .visible) {
                    Button(NSLocalizedString("譯本比較", comment: "")) { actions.verseAction(row, .VersionsCompare) }
                    Button("Parsing") { actions.verseAction(row, .InfoParsing) }
                    Button(NSLocalizedString("註釋", comment: "")) { actions.verseAction(row, .InfoComment) }
                    Button(NSLocalizedString("串珠", comment: "")) { actions.verseAction(row, .InfoTsk) }
                }
            }
            if isWide && model.columns.count > 1 {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(model.columns.indices, id: \.self) { col in
                        cellView(col).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.columns.indices, id: \.self) { col in
                        cellView(col)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func cellView(_ col: Int) -> some View {
        if row.cells.indices.contains(col) {
            let column = model.columns[col]
            let isSelected = model.selected.contains(ReadCellKey(row: row.id, col: col))
            VStack(alignment: .leading, spacing: 2) {
                if model.columns.count > 1 {
                    Text(column.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                DTextContentView(dtexts: row.cells[col],
                                 generation: model.generation,
                                 isVisibleSn: model.isSnVisible,
                                 onTapRef: { _ in },
                                 isFontOpenHan: column.isFontOpenHan,
                                 alignment: column.alignment,
                                 onTapAny: { dtext in actions.tap(row, col, dtext) },
                                 onLongPress: { model.startSelecting(row: row.id, col: col) })
            }
            .padding(.leading, 4)
            // 複選中，右邊留位置給勾選圈，免得蓋到文字
            .padding(.trailing, model.isSelecting ? 32 : 4)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if model.isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .padding(6)
                }
            }
            .overlay {
                // 複選中，整塊都是「選取」，不再是點文字
                if model.isSelecting {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { model.toggle(row: row.id, col: col) }
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

// MARK: - 產生圖片

/// 把閱讀的內容畫成一張圖：標題 + 每節 (節的位置、每個譯本的經文)。
/// 用 `ViewDisplayCell` 畫，所以字型、SN 顯示都與畫面一致；固定淺色，方便當筆記或分享。
fileprivate struct ReadSnapshotRenderer {
    let model: ReadModel
    let width: CGFloat
    let scale: CGFloat

    func render() -> UIImage? {
        if model.rows.isEmpty { return nil }
        let pad: CGFloat = 16

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        func addLabel(_ text: String, _ font: UIFont, _ color: UIColor, spaceBefore: CGFloat = 0) {
            let l = UILabel()
            l.numberOfLines = 0
            l.text = text
            l.font = font
            l.textColor = color
            stack.addArrangedSubview(l)
            if spaceBefore > 0 { stack.setCustomSpacing(spaceBefore, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2]) }
        }

        addLabel(model.titleAddr, .preferredFont(forTextStyle: .title2), .black)
        for row in model.rows {
            if !row.address.isEmpty {
                addLabel(row.address, .preferredFont(forTextStyle: .footnote), .systemBlue, spaceBefore: 12)
            }
            for (col, dtexts) in row.cells.enumerated() where model.columns.indices.contains(col) {
                let column = model.columns[col]
                if model.columns.count > 1 {
                    addLabel(column.name, .preferredFont(forTextStyle: .caption2), .darkGray)
                }
                let cell = ViewDisplayCell()
                cell.overrideUserInterfaceStyle = .light
                cell.set(dtexts: dtexts, isVisibleSn: model.isSnVisible, isFontNameOpenHanBibleTC: column.isFontOpenHan, tpTextAlignment: column.alignment, isSwitchOn: false, isSwitchVisible: false)
                stack.addArrangedSubview(cell)
            }
        }

        let container = UIView()
        container.overrideUserInterfaceStyle = .light
        container.backgroundColor = .white
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: pad),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -pad),
        ])

        // 寬度固定，量需要的高度
        let fit = container.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                    withHorizontalFittingPriority: .required,
                                                    verticalFittingPriority: .fittingSizeLevel)
        container.frame = CGRect(x: 0, y: 0, width: width, height: fit.height)
        container.layoutIfNeeded()

        // 太長的章節 (詩篇119) 圖片會超過系統上限，降低倍率
        let s = min(scale, max(1, 16000 / max(fit.height, 1)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = s
        return UIGraphicsImageRenderer(size: container.bounds.size, format: format).image { ctx in
            container.layer.render(in: ctx.cgContext)
        }
    }
}

/// 原本是閱讀的，但搜尋也要用到，所以重構出來。
func drawSnButtonState(btn:UIButton,vers: [String]){
    if vers.ijnAny({["unv","kjv","rcuv"].contains($0)}) {
        btn.isEnabled = true
        btn.alpha = 1
    } else {
        btn.isEnabled = false
        btn.alpha = 0.2
    }
}
