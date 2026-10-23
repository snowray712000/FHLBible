//
//  VCFooter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/22.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon
import OSLog

/// 注腳。閱讀時某些譯本 (cnet、csb、lcc) 的經文後面會有【23】這種注腳，點了就來到這裡。
/// 畫面是 SwiftUI (`FootnoteView`)，注腳內容仍用 `ViewDisplayCell` (UITextView，點到交叉參照要逐字判定)。
/// 以 `VCFooter(dtext:ver:addr:vers:)` 建立後 push，不再經由 storyboard。
class VCFooter : UIHostingController<FootnoteView> {
    private let model: FootnoteModel

    /// - Parameters:
    ///   - dtext: 被點到的【23】，`foot.id` 是注腳編號
    ///   - ver: 目前這個欄位的譯本（注腳屬於哪個譯本）
    ///   - addr: 注腳所在的節
    ///   - vers: 閱讀用的譯本們，內容若點到交叉參照要開閱讀時用
    init(dtext: DText, ver: String, addr: DAddress, vers: [String]) {
        let m = FootnoteModel(id: dtext.foot?.id ?? 1, ver: ver, addr: addr, vers: vers)
        self.model = m
        super.init(rootView: FootnoteView(model: m, onTapRef: { _ in }))
        rootView = FootnoteView(model: m, onTapRef: { [weak self] dtext in self?.doWhenRefClicked(dtext) })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = FootnoteModel(id: 1, ver: "cnet", addr: DAddress(1,1,1), vers: [])
        self.model = m
        super.init(coder: aDecoder, rootView: FootnoteView(model: m, onTapRef: { _ in }))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 左右滑換上一則、下一則。(SwipeHelp 也會停用系統的右滑返回，否則會互相干擾)
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.onSwipe$.addCallback {[weak self] sender, pData in
            if pData?.direction == .right {
                self?.model.goPrev()
            } else if pData?.direction == .left {
                self?.model.goNext()
            }
        }

        // 第 1 次查詢
        model.reload()
    }
    lazy var _swipeHelp = SwipeHelp(view: self.view, viewController: self)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _swipeHelp.onViewWillAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _swipeHelp.onViewWillDisappear()
    }

    /// 點擊到內容中的交叉參照 -> 開啟閱讀
    private func doWhenRefClicked(_ dtext: DText) {
        guard let ref = dtext.refDescription else { return }
        let r1 = StringToVerseRange().main(ref, (model.addr.book, model.addr.chap))
        let vc = self.gVCRead()
        vc.setInitData(VerseRange(r1), model.vers)
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

/// 注腳的狀態：目前的注腳編號、內容 `[DText]`
@Observable
final class FootnoteModel {
    enum Phase { case loading, loaded, failed }

    /// 目前顯示（或正要顯示）的注腳編號。換編號要等查到才會變，查不到就維持原樣
    private(set) var id: Int
    let ver: String
    /// 被點到的那一節。只有編號還是被點的那一則時，才知道它在哪一節
    let addr: DAddress
    let vers: [String]
    private let firstId: Int

    var dtexts: [DText] = []
    /// `dtexts` 每換一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    var generation: Int = 0
    var phase: Phase = .loading
    /// 換編號時查不到（已經是最後一則），就停用對應的按鈕，直到成功換到別則
    var isNextUnavailable = false
    var isPrevUnavailable = false

    @ObservationIgnored private var requestId = 0
    @ObservationIgnored private let logger = Logger(subsystem: "FHLBible", category: "VCFooter")

    init(id: Int, ver: String, addr: DAddress, vers: [String]) {
        self.id = id
        self.firstId = id
        self.ver = ver
        self.addr = addr
        self.vers = vers
    }

    var title: String { "【\(id)】" }
    /// 譯本中文名，例如 NET聖經中譯本
    var versionName: String { BibleVersionConvertor().na2cna(ver) }
    /// 出處：被點的那則顯示到節，其它則只知道章
    var place: String {
        let lang = ManagerLangSet.s.curTpBookNameLang
        if id == firstId { return addr.toString(lang) }
        return "\(BibleBookNames.getBookName(addr.book, lang)) \(addr.chap)"
    }
    var canGoPrev: Bool { id > 1 && !isPrevUnavailable }
    var canGoNext: Bool { !isNextUnavailable }

    func goNext() {
        if canGoNext { reload(id + 1) }
    }
    func goPrev() {
        if canGoPrev { reload(id - 1) }
    }
    /// 重抓目前的注腳（第一次、或失敗後重試）
    func reload() { reload(id) }

    /// engs=Matt&chap=1&version=cnet&id=1
    private func gParam(_ id: Int) -> String {
        "engs=\(BibleBookNames.getBookName(addr.book, .Matt))&chap=\(addr.chap)&version=\(ver)&id=\(id)&\(ManagerLangSet.s.curQueryParamGb)"
    }

    /// 抓 `newId` 的內容。快速連續換編號時，舊的回應（requestId 不同）會被丟掉。
    private func reload(_ newId: Int) {
        requestId += 1
        let reqId = requestId
        // 已經有內容時（換上一則、下一則）保留舊內容，查到才換；沒有內容才是「取得資料中」
        if dtexts.isEmpty { phase = .loading }

        let ver = self.ver
        let addr = self.addr
        fhlRt(gParam(newId)) {[weak self] data in
            var result: [DText]?
            if data.isSuccess(), let text = data.record.first?.text {
                result = cvtFooter(text, addr, ver)
            } else {
                self?.logger.info("\(data.status)")
            }
            DispatchQueue.main.async {
                guard let self = self, self.requestId == reqId else { return }
                self.finish(newId, result)
            }
        }
    }
    private func finish(_ newId: Int, _ result: [DText]?) {
        if let r = result {
            id = newId
            dtexts = r
            generation += 1
            phase = .loaded
            isNextUnavailable = false
            isPrevUnavailable = false
        } else if dtexts.isEmpty {
            phase = .failed
        } else {
            // 換編號沒查到：留在原本那則，並停用往那個方向的按鈕
            phase = .loaded
            if newId > id { isNextUnavailable = true } else if newId < id { isPrevUnavailable = true }
        }
    }
}

/// 注腳畫面：上方是出處與譯本，下面是注腳內容；右上角是上一則、下一則
struct FootnoteView: View {
    let model: FootnoteModel
    let onTapRef: (DText) -> Void

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                ProgressView(NSLocalizedString("取得資料中...", comment: ""))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                ContentUnavailableView {
                    Label(NSLocalizedString("無法取得注腳", comment: ""), systemImage: "text.badge.xmark")
                } description: {
                    Text(NSLocalizedString("請確認網路連線後再試一次", comment: ""))
                } actions: {
                    Button(NSLocalizedString("重試", comment: "")) { model.reload() }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(model.versionName) · \(model.place)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 13)
                        DTextContentView(dtexts: model.dtexts,
                                         generation: model.generation,
                                         isVisibleSn: true,
                                         onTapRef: onTapRef,
                                         alignment: .left)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(NSLocalizedString("注腳", comment: "") + " " + model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.goPrev() } label: {
                    Label(NSLocalizedString("上一則注腳", comment: ""), systemImage: "arrow.left")
                }
                .disabled(!model.canGoPrev)
                Button { model.goNext() } label: {
                    Label(NSLocalizedString("下一則注腳", comment: ""), systemImage: "arrow.right")
                }
                .disabled(!model.canGoNext)
            }
        }
    }
}

// MARK: - 注腳載入方式（全域設定）與「直接載入」

/// 注腳的載入方式。參考 FHLNUI 的 `foot_note_show_method`（0 點擊顯示、2 直接載入）。
/// rawValue 會存進 UserDefaults；沒設定過時 `getCoreInt` 回 0，所以 `direct` 必須是 0，預設才會是「直接載入」。
enum FootnoteLoadMode: Int {
    /// 直接載入：取得經文後先把注腳內容一起取回，內嵌在 【n】 的位置，顯示成 【註n：內容】
    case direct = 0
    /// 點擊載入：維持藍色 【n】，點了才開「注腳」畫面
    case onTap = 1
}

class ManagerFootnoteLoadMode : NSObject {
    static var s: ManagerFootnoteLoadMode = ManagerFootnoteLoadMode()
    var cur: FootnoteLoadMode { FootnoteLoadMode(rawValue: _cur.cur ?? 0) ?? .direct }
    func updateCur(_ v: FootnoteLoadMode) { _cur.updateCur(v.rawValue) }
    lazy var _cur = Cur()
    class Cur : GlobalVariableIntBase {
        override var _tp: FHLUserDefaults.keys { .FootnoteLoadMode }
        override var _getDefaultInt: Int { FootnoteLoadMode.direct.rawValue }
    }
}

/// 「直接載入」：把 `[[DOneLine]]` 裡所有 【n】（`DText.foot` 有 id）換成 【註n：內容】。
///
/// 後端用 `rt-nui.php`（FHLNUI 的 `rtAsync` 也是），不帶 id 就一次回整章（lcc、csb，`scope: "chapter"`）
/// 或整本（cnet 等 id 整本唯一的譯本，`scope: "book"`），所以每個（譯本、書、章）只要一個請求，不是一個注腳一個。
/// 回應沒有 `scope`（舊後端）、網路失敗、查不到該編號：那個 【n】 維持原樣，仍可點擊載入，不影響其它注腳。
/// 只有 id 的注腳（cnet、csb、lcc）；和合本2010 的 `foot.text`（沒有 id）本來就內嵌，不處理。
final class FootnoteExpander {
    static let s = FootnoteExpander()

    /// 查詢整章（整本）的單位。`chap` 為 0 表示整本
    private struct Key: Hashable {
        let ver: String
        let book: Int
        let chap: Int
        let gb: Int
    }
    private struct Response: Decodable {
        struct Record: Decodable { let id: Int; let text: String? }
        let status: String?
        let scope: String?
        let record: [Record]?
    }

    /// 在這個 queue 上讀寫下面三個狀態
    private let q = DispatchQueue(label: "FootnoteExpander")
    /// 已查到的，[id: 內容]。失敗不放進來，下次再試
    private var cache: [Key: [Int: String]] = [:]
    /// 某譯本的 scope 是 book 之後，同書的任何一章都共用整本的結果
    private var bookScopeVers: Set<String> = []
    /// 正在查的。同時間多個要求（搜尋結果一次取好幾章）等同一個回應
    private var pending: [Key: [([Int: String]?) -> Void]] = [:]

    /// - Parameter completion: 在主執行緒呼叫。沒有任何注腳時同步呼叫
    func expand(_ datas: [[DOneLine]], completion: @escaping () -> Void) {
        let gb = ManagerLangSet.s.curIsGb ? 1 : 0
        var keys = Set<Key>()
        for oneLine in datas.joined() {
            collectKeys(oneLine.children ?? [], gb, &keys)
        }
        if keys.isEmpty { completion(); return }

        let lock = NSLock()
        var maps: [Key: [Int: String]] = [:]
        let group = DispatchGroup()
        for key in keys {
            group.enter()
            load(key) { map in
                if let map = map {
                    lock.lock(); maps[key] = map; lock.unlock()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            for oneLine in datas.joined() where oneLine.children != nil {
                oneLine.children = self.replace(oneLine.children!, gb, maps)
            }
            completion()
        }
    }

    private func key(of foot: DFoot, _ gb: Int) -> Key? {
        guard foot.id != nil, let ver = foot.version, let book = foot.book, let chap = foot.chap else { return nil }
        return Key(ver: ver, book: book, chap: chap, gb: gb)
    }
    private func collectKeys(_ ds: [DText], _ gb: Int, _ keys: inout Set<Key>) {
        for d in ds {
            if let f = d.foot, let k = key(of: f, gb) { keys.insert(k) }
            if let c = d.children { collectKeys(c, gb, &keys) }
        }
    }
    private func replace(_ ds: [DText], _ gb: Int, _ maps: [Key: [Int: String]]) -> [DText] {
        return ds.map { d in
            if let f = d.foot, let id = f.id, let k = key(of: f, gb),
               let text = maps[k]?[id]?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 0 {
                return makeExpanded(id, text, DAddress(k.book, k.chap, f.verse ?? 1), k.ver)
            }
            if let c = d.children { d.children = replace(c, gb, maps) }
            return d
        }
    }
    /// 【註3：內容】。容器用 `kjvrf`：紫色、不會自動加括號；內容的交叉參照（藍色）仍可點。
    private func makeExpanded(_ id: Int, _ text: String, _ addr: DAddress, _ ver: String) -> DText {
        let re = DText()
        re.tpContain = "kjvrf"
        re.children = [DText("【\(ManagerLangSet.s.curIsGb ? "注" : "註")\(id)：")] + cvtFooter(text, addr, ver) + [DText("】")]
        return re
    }

    // MARK: 網路

    /// `completion` 可能在任何執行緒；`nil` 是失敗或後端不支援整章查詢
    private func load(_ key: Key, _ completion: @escaping ([Int: String]?) -> Void) {
        q.async {
            // 已知 scope 是 book 的譯本，用整本的 key 找（chap 0）
            let bookKey = Key(ver: key.ver, book: key.book, chap: 0, gb: key.gb)
            let k = self.bookScopeVers.contains(key.ver) ? bookKey : key
            if let hit = self.cache[k] { completion(hit); return }
            if self.pending[k] != nil { self.pending[k]!.append(completion); return }
            self.pending[k] = [completion]
            self.fetch(key) { scope, map in
                self.q.async {
                    var store = key
                    if scope == "book" {
                        self.bookScopeVers.insert(key.ver)
                        store = bookKey
                    }
                    if let map = map { self.cache[store] = map }
                    // 先前以 chap key 等待的，都在 k 下面；scope 是 book 時 k 與 store 可能不同，兩邊都要通知
                    var waiters = self.pending.removeValue(forKey: k) ?? []
                    if store != k { waiters += self.pending.removeValue(forKey: store) ?? [] }
                    waiters.forEach { $0(map) }
                }
            }
        }
    }
    /// https://bible.fhl.net/json/rt-nui.php?engs=Hab&chap=2&version=lcc&gb=0
    private func fetch(_ key: Key, _ done: @escaping (_ scope: String?, [Int: String]?) -> Void) {
        var c = URLComponents(string: "https://bible.fhl.net/json/rt-nui.php")!
        c.queryItems = [
            URLQueryItem(name: "engs", value: BibleBookNames.getBookName(key.book, .Matt)),
            URLQueryItem(name: "chap", value: String(key.chap)),
            URLQueryItem(name: "version", value: key.ver),
            URLQueryItem(name: "gb", value: String(key.gb)),
        ]
        var req = URLRequest(url: c.url!)
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let r = try? JSONDecoder().decode(Response.self, from: data),
                  r.status == "success", r.scope == "chapter" || r.scope == "book" else {
                done(nil, nil) // 網路失敗、503 的 html、舊後端（沒有 scope）
                return
            }
            var map: [Int: String] = [:]
            for one in r.record ?? [] { if let t = one.text { map[one.id] = t } }
            done(r.scope, map)
        }.resume()
    }
}
