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
