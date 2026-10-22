//
//  VCComment.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit
import SwiftUI
import FMDB
import FHLCommon

/// 註釋。畫面是 SwiftUI (`CommentView`)，經文內容仍用 `ViewDisplayCell` (UITextView，點到 SN、參照要逐字判定)。
/// 以 `VCComment(addr:)` 建立後 push，不再經由 storyboard。
/// (資料讀取的 `IReloadData` 等型別在 `VCComment*IReloadData*.swift` 的 extension，串珠也共用)
class VCComment : UIHostingController<CommentView> {
    private let model: CommentModel

    init(addr: DAddress) {
        let m = CommentModel(addr: addr)
        self.model = m
        super.init(rootView: CommentView(model: m, onTap: { _ in }))
        rootView = CommentView(model: m, onTap: { [weak self] dtext in self?.doWhenClicked(dtext) })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = CommentModel(addr: DAddress(1,1,1))
        self.model = m
        super.init(coder: aDecoder, rootView: CommentView(model: m, onTap: { _ in }))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 左右滑換上一節、下一節。(SwipeHelp 也會停用系統的右滑返回，否則會互相干擾)
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.onSwipe$.addCallback {[weak self] sender, pData in
            if pData?.direction == .right {
                self?.model.goPrev()
            } else if pData?.direction == .left {
                self?.model.goNext()
            }
        }

        // 首先觸發
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

    /// 點擊到內容中的交叉參照 -> 開啟閱讀；點擊到原文 SN -> 跳出 SN 選單
    private func doWhenClicked(_ dtext: DText) {
        if let ref = dtext.refDescription {
            let addr = model.addr
            let r1 = StringToVerseRange().main(ref, (addr.book, addr.chap))
            let r2 = self.gVCRead()
            r2.setInitData(VerseRange(r1), ManagerBibleVersions.s.cur)
            self.navigationController?.pushViewController(r2, animated: false)
        } else if dtext.sn != nil {
            SnDTextClickFlow(vc: self, addr: model.addr, vers: ManagerBibleVersions.s.cur).mainAsync(dtext)
        }
    }
}

/// 註釋的狀態：目前節、上下節、經文 `[DText]`
@Observable
final class CommentModel {
    var addr: DAddress
    var dtexts: [DText] = []
    /// `dtexts` 每換一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    var generation: Int = 0
    var isLoading = false
    /// data 取得後，會設定它 (供 next prev button 按)。沒有表示已到此卷書的頭或尾，或取得失敗
    var addrNext: DAddress?
    var addrPrev: DAddress?

    @ObservationIgnored private var requestId = 0

    init(addr: DAddress) {
        self.addr = addr
    }
    var title: String {
        let lang = ManagerLangSet.s.curTpBookNameLang
        let prefix = NSLocalizedString("註釋", comment: "")
        guard let prev = addrPrev, let next = addrNext else {
            return prefix + addr.toString(lang)
        }
        // comment 會有 第 0 章，也就是此卷書的導論
        let from = prev.chap == 0 ? DAddress(prev.book,1,1) : prev.goNextVerse()
        let to = next.goPrevVerse()
        return prefix + "\(from.toString(lang))至\(to.toString(lang))"
    }

    func goNext() {
        if let n = addrNext {
            addr = n
            reload()
        }
    }
    func goPrev() {
        if let p = addrPrev {
            addr = p
            reload()
        }
    }
    /// 用 addr 重抓一次資料。抓到後在主執行緒更新。
    /// 快速連續換節時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        isLoading = true
        // 標題要等到取得這一節的範圍後才會是「某節至某節」
        addrNext = nil
        addrPrev = nil

        let dataQ: VCComment.IReloadData = VCComment.ReloadDataAutoUseOfflineOrScApi()
        dataQ.apiFinished$.addCallback {[weak self] sender, pData in
            if sender != nil {
                // 錯誤或提示訊息
                let msg = sender!
                DispatchQueue.main.async {
                    guard let self = self, self.requestId == id else { return }
                    self.setDTexts(msg)
                }
            } else {
                let dtexts = CommentDataStrToDText().main(pData!.com_text ?? "")
                let next = pData!.addrNext
                let prev = pData!.addrPrev
                DispatchQueue.main.async {
                    guard let self = self, self.requestId == id else { return }
                    self.addrNext = next
                    self.addrPrev = prev
                    self.setDTexts(dtexts)
                }
            }
        }
        dataQ.reloadAsync(addr)
    }
    private func setDTexts(_ data: [DText]) {
        dtexts = data
        generation += 1
        isLoading = false
    }
}

/// 註釋畫面：經文可捲動，右上角是上一節、下一節（到頭尾時停用）
struct CommentView: View {
    let model: CommentModel
    let onTap: (DText) -> Void

    var body: some View {
        ScrollView {
            if model.isLoading {
                ProgressView(NSLocalizedString("取得資料中...", comment: ""))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else {
                DTextContentView(dtexts: model.dtexts,
                                 generation: model.generation,
                                 isVisibleSn: true,
                                 onTapRef: onTap,
                                 alignment: .left,
                                 onTapAny: onTap)
                    .padding(.horizontal, 8)
            }
        }
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.goPrev() } label: { Image(systemName: "arrow.left") }
                    .disabled(model.addrPrev == nil)
                Button { model.goNext() } label: { Image(systemName: "arrow.right") }
                    .disabled(model.addrNext == nil)
            }
        }
    }
}
