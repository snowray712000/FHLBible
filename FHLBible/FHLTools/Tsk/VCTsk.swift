//
//  VCTsk.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon
import OSLog

/// 串珠。畫面是 SwiftUI (`TskView`)，經文內容仍用 `ViewDisplayCell` (UITextView，點到參照要逐字判定)。
/// 以 `VCTsk(addr:)` 建立後 push，不再經由 storyboard。
class VCTsk : UIHostingController<TskView> {
    var logger = Logger(subsystem: "FHLBible", category: "VCTsk")

    private let model: TskModel
    /// addr 為何要傳呢？因為有的 19,27 變為 太2:19,27
    init(addr: DAddress) {
        let m = TskModel(addr: addr)
        self.model = m
        super.init(rootView: TskView(model: m, onTapRef: { _ in }))
        rootView = TskView(model: m, onTapRef: { [weak self] dtext in
            self?.logger.info("\(dtext.w ?? "nil")")
            self?.pushVCReadWhenClickContentRef(dtext)
        })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = TskModel(addr: DAddress(1,1,1))
        self.model = m
        super.init(coder: aDecoder, rootView: TskView(model: m, onTapRef: { _ in }))
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

        // 開始觸發
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

    /// 回應事件，點擊到 reference 時。
    /// 串珠功能，最常用到的就是點擊到 reference。
    fileprivate func pushVCReadWhenClickContentRef(_ dtext: DText){
        assert( dtext.refDescription != nil )

        // 不是由 storyboard 建立的，self.storyboard 是 nil，改由 navigationController 或 Main 取得
        let sb = self.navigationController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let vc1 = sb.instantiateViewController(withIdentifier: "VCRead") as! VCRead
        let r1a = dtext.refDescription!
        let r1b = VerseRange( StringToVerseRange().main(r1a) )
        let r2 = ManagerBibleVersions.s.cur
        vc1.setInitData(r1b, r2)
        self.navigationController?.pushViewController(vc1, animated: false)
    }
}

/// 串珠的狀態：目前節、上下節、經文 `[DText]`
@Observable
final class TskModel {
    var addr: DAddress
    var dtexts: [DText] = []
    /// `dtexts` 每換一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    var generation: Int = 0
    /// data 取得後，會設定它 (供 next prev button 按)
    var addrNext: DAddress?
    var addrPrev: DAddress?
    /// 串珠不須要 Sn
    let isVisibleSn = false

    @ObservationIgnored private var requestId = 0

    init(addr: DAddress) {
        self.addr = addr
    }
    var title: String { "串珠 \(BibleBookNames.getBookName(addr.book, .太)) \(addr.chap):\(addr.verse)" }

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
    /// 用 addr 重抓一次資料。先顯示「取得資料中...」，抓到後在主執行緒更新。
    /// 快速連續換節時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        let addr = self.addr
        setDTexts([DText(NSLocalizedString("取得資料中...", comment: ""))])

        let dataQ: VCTsk.IReloadData = VCTsk.ReloadDataAutoUseOfflineOrScApi()
        dataQ.apiFinished$.addCallback {[weak self] sender, pData in
            if sender != nil {
                // 錯誤或提示訊息
                let msg = sender!
                DispatchQueue.main.async {
                    guard let self = self, self.requestId == id else { return }
                    self.setDTexts(msg)
                }
            } else {
                let com_text = pData!.com_text!
                let dtexts = TskDataStrToDText().main(com_text, addr)
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
    }
}

/// 串珠畫面：經文可捲動，右上角是上一節、下一節
struct TskView: View {
    let model: TskModel
    let onTapRef: (DText) -> Void

    var body: some View {
        ScrollView {
            DTextContentView(dtexts: model.dtexts,
                             generation: model.generation,
                             isVisibleSn: model.isVisibleSn,
                             onTapRef: onTapRef)
        }
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.goPrev() } label: { Image(systemName: "arrow.left") }
                Button { model.goNext() } label: { Image(systemName: "arrow.right") }
            }
        }
    }
}

/// 把 `ViewDisplayCell` 放進 SwiftUI。只在 `generation` 改變時才重設內容；
/// 預設只有點到有參照 (`refDescription`) 的字才通知 `onTapRef`；
/// 有給 `onTapAny` 時，改成點到任何字都通知它（譯本比較要處理 SN、參照、注腳）。
struct DTextContentView: UIViewRepresentable {
    let dtexts: [DText]
    let generation: Int
    let isVisibleSn: Bool
    let onTapRef: (DText) -> Void
    /// 台語、客語漢字需要特殊字型（`BibleVersionFonts`）
    var isFontOpenHan: Bool? = nil
    var alignment: NSTextAlignment = .justified
    var onTapAny: ((DText) -> Void)? = nil

    final class Coordinator {
        var generation = -1
        var onTapRef: (DText) -> Void = { _ in }
        var onTapAny: ((DText) -> Void)?
    }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ViewDisplayCell {
        let v = ViewDisplayCell()
        let c = context.coordinator
        v.onClicked$.addCallback { _, dtext in
            guard let d = dtext else { return }
            if let any = c.onTapAny {
                any(d)
            } else if d.refDescription != nil {
                c.onTapRef(d)
            }
        }
        return v
    }
    func updateUIView(_ v: ViewDisplayCell, context: Context) {
        context.coordinator.onTapRef = onTapRef
        context.coordinator.onTapAny = onTapAny
        if context.coordinator.generation != generation {
            context.coordinator.generation = generation
            v.set(dtexts: dtexts, isVisibleSn: isVisibleSn, isFontNameOpenHanBibleTC: isFontOpenHan, tpTextAlignment: alignment, isSwitchOn: false, isSwitchVisible: false)
            v.invalidateIntrinsicContentSize()
        }
    }
    /// 文字視圖不可捲動，高度由內容決定：寬度給多少就用多少，再量需要的高度
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ViewDisplayCell, context: Context) -> CGSize? {
        let w = proposal.width ?? uiView.bounds.width
        let fit = uiView.systemLayoutSizeFitting(CGSize(width: w, height: UIView.layoutFittingCompressedSize.height),
                                                 withHorizontalFittingPriority: .required,
                                                 verticalFittingPriority: .fittingSizeLevel)
        return CGSize(width: w, height: fit.height)
    }
}
