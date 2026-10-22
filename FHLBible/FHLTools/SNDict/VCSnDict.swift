//
//  VCSnDict.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/29.
//

import UIKit
import SwiftUI
import FHLCommon

/// 原文字典。畫面是 SwiftUI (`SnDictView`)，內容仍用 `ViewDisplayCell` (UITextView，點到參照、原文要逐字判定)。
/// 以 `VCSnDict(dtext:addr:vers:)` 建立後 push，不再經由 storyboard。
/// addr, vers 是因為若點了內容，有時候可能會需要，而非 dict 真的需要
class VCSnDict: UIHostingController<SnDictView> {
    private let model: SnDictModel

    init(dtext: DText, addr: DAddress, vers: [String]) {
        let m = SnDictModel(dtext: dtext, addr: addr, vers: vers)
        self.model = m
        super.init(rootView: SnDictView(model: m, onTap: { _ in }, onList: {}))
        rootView = SnDictView(model: m,
                              onTap: { [weak self] dtext in self?.doWhenClicked(dtext) },
                              onList: { [weak self] in self?.doSnList() })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = SnDictModel(dtext: DText("G1", sn: "1", tp: "G", tp2: ""), addr: DAddress(1,1,1), vers: [])
        self.model = m
        super.init(coder: aDecoder, rootView: SnDictView(model: m, onTap: { _ in }, onList: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 左右滑換上一字、下一字。(SwipeHelp 也會停用系統的右滑返回，否則會互相干擾)
        _swipeHelp.addSwipe(dir: .right)
        _swipeHelp.addSwipe(dir: .left)
        _swipeHelp.onSwipe$.addCallback {[weak self] sender, pData in
            if pData?.direction == .right {
                self?.model.goPrev()
            } else if pData?.direction == .left {
                self?.model.goNext()
            }
        }

        // 開始動作
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

    /// 點擊內容：交互參照 -> 開啟閱讀；原文 -> 再開一個同一種字典的畫面
    private func doWhenClicked(_ dtext: DText) {
        if let ref = dtext.refDescription {
            let r1 = self.gVCRead()
            let r2 = StringToVerseRange().main(ref, nil)
            r1.setInitData(VerseRange(r2), ManagerBibleVersions.s.cur)
            self.navigationController?.pushViewController(r1, animated: false)
        } else if dtext.sn != nil {
            let r1 = dtext.clone()
            r1.snAction = model.action
            let r2 = VCSnDict(dtext: r1, addr: model.addr, vers: model.vers)
            self.navigationController?.pushViewController(r2, animated: false)
        }
    }
    /// 「彙編」: 此原文出現在哪些章節
    private func doSnList() {
        // 不可直接用 dtext.w! 因為可能會是 <G3212> 而非 G3212
        let vc = VCSearchResult(keyword: model.key, vers: model.vers, addr: model.addr)
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

/// 重構才出現的, 非必要邏輯
private class MySQLCbol2 : SQLCBOLDict, ISQLCBOLDictIsExist {
    func SQLCBOLDictisExist() -> Bool {
        return SQLCBOLDict.isExist()
    }
}

/// 原文字典的狀態：目前的字、字典種類、上下一字、內容 `[DText]`
@Observable
final class SnDictModel {
    /// 目前的字 (tp: G/H, sn: 數字，可能帶字母如 2532a)
    private(set) var dtext: DText
    /// 字典種類。.cbol / .twcb 可在畫面上切換
    private(set) var action: DText.SnAction?
    let addr: DAddress
    let vers: [String]
    var dtexts: [DText] = []
    /// `dtexts` 每換一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    var generation: Int = 0
    var isLoading = false

    @ObservationIgnored private var requestId = 0

    init(dtext: DText, addr: DAddress, vers: [String]) {
        assert(dtext.sn != nil)
        assert(dtext.snAction != nil)
        self.dtext = dtext
        self.action = dtext.snAction
        self.addr = addr
        self.vers = vers
    }

    /// 例 G3056，用於標題與查彙編
    var key: String { (dtext.tp ?? "") + (dtext.sn ?? "") }
    /// 只有 cbol 與浸宣可互相切換 (cbole、dict 不在選單中出現)
    var isSwitchable: Bool { action == .cbol || action == .twcb }
    var actionName: String {
        switch action {
        case .twcb:
            return NSLocalizedString("浸宣字典", comment: "")
        case .cbol, .cbole:
            return NSLocalizedString("cbol字典", comment: "")
        default:
            return NSLocalizedString("原文字典", comment: "")
        }
    }

    /// 編號 ±1 的字 (只取第一段數字，2532a 的 a 會被忽略)
    private func neighbor(_ delta: Int) -> DText? {
        guard let tp = dtext.tp, let sn = dtext.sn else { return nil }
        let digits = sn.drop(while: { !$0.isNumber }).prefix(while: { $0.isNumber })
        guard let n = Int(digits), n + delta >= 1 else { return nil }
        let s = (n + delta).description
        let re = DText(tp + s, sn: s, tp: tp, tp2: "")
        re.snAction = action
        return re
    }
    var hasPrev: Bool { neighbor(-1) != nil }
    func goNext() { go(neighbor(1)) }
    func goPrev() { go(neighbor(-1)) }
    private func go(_ d: DText?) {
        guard let d = d else { return }
        dtext = d
        reload()
    }
    func setAction(_ a: DText.SnAction) {
        guard a != action else { return }
        action = a
        dtext.snAction = a
        reload()
    }

    /// 重抓一次資料 (cbol、浸宣會同時查，再合併)。抓到後在主執行緒更新。
    /// 快速連續換字時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        isLoading = true

        let iFromSQL = MySQLCbol2()
        let r1 = SnDictDataQ(iFromSQL, iFromSQL)
        r1.onFinishedQ$.addCallback { [weak self] sender, pData in
            // SnDictDataQ 在 main queue 回呼
            guard let self = self, self.requestId == id else { return }
            self.dtexts = r1.resultContent ?? []
            self.generation += 1
            self.isLoading = false
        }
        r1.main(dtext)
    }
}

/// 原文字典畫面：上方選字典（cbol／浸宣），內容可捲動；右上角是彙編、上一字、下一字
struct SnDictView: View {
    let model: SnDictModel
    let onTap: (DText) -> Void
    let onList: () -> Void

    var body: some View {
        ScrollView {
            if model.isLoading {
                ProgressView(NSLocalizedString("取得資料中...", comment: ""))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else {
                // Sn Dict 總是需要顯示 Sn
                DTextContentView(dtexts: model.dtexts,
                                 generation: model.generation,
                                 isVisibleSn: true,
                                 onTapRef: onTap,
                                 onTapAny: onTap)
                    .padding(.horizontal, 8)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .navigationTitle(model.key)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: onList) {
                    Label("彙編", systemImage: "magnifyingglass")
                }
                Button { model.goPrev() } label: {
                    Label("上一字", systemImage: "arrow.left").labelStyle(.iconOnly)
                }
                .disabled(!model.hasPrev)
                Button { model.goNext() } label: {
                    Label("下一字", systemImage: "arrow.right").labelStyle(.iconOnly)
                }
            }
        }
    }

    /// 可切換時是 cbol／浸宣的分段選單，否則只標示字典名稱
    @ViewBuilder private var header: some View {
        if model.isSwitchable {
            Picker("字典", selection: Binding(get: { model.action ?? .cbol },
                                              set: { model.setAction($0) })) {
                Text("CBOL").tag(DText.SnAction.cbol)
                Text("浸宣").tag(DText.SnAction.twcb)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        } else {
            Text(model.actionName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }
}
