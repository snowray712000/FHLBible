//
//  VCVersionsCompareInOneVerse.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/26.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon

/// 譯本比較：同一節經文，並列多個譯本。(畫面上一律稱「譯本」，「版本」是指 App 的版本)
/// 畫面是 SwiftUI (`VersionsCompareView`)，經文內容仍用 `ViewDisplayCell` (UITextView，點到 SN、參照、注腳要逐字判定)。
/// 以 `VCVersionsCompareInOneVerse(addr:)` 建立後 push，不再經由 storyboard。
/// (類別與檔名沿用舊名，因為改檔名要動 pbxproj)
class VCVersionsCompareInOneVerse : UIHostingController<VersionsCompareView> {
    private let model: VersionsCompareModel

    init(addr: DAddress) {
        let m = VersionsCompareModel(addr: addr)
        self.model = m
        super.init(rootView: VersionsCompareView(model: m, onTap: { _, _ in }, onPickVers: { }))
        rootView = VersionsCompareView(model: m,
                                       onTap: { [weak self] dtext, ver in self?.doWhenClicked(dtext, ver) },
                                       onPickVers: { [weak self] in self?.doPickVersions() })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = VersionsCompareModel(addr: DAddress(1,1,1))
        self.model = m
        super.init(coder: aDecoder, rootView: VersionsCompareView(model: m, onTap: { _, _ in }, onPickVers: { }))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 左右滑換上一節、下一節。(SwipeHelp 也會停用系統的右滑返回，否則會互相干擾)
        _swipe.addSwipe(dir: .left)
        _swipe.addSwipe(dir: .right)
        _swipe.onSwipe$.addCallback {[weak self] sender, pData in
            if pData?.direction == .right {
                self?.model.goPrev()
            } else if pData?.direction == .left {
                self?.model.goNext()
            }
        }

        model.reload()
    }
    lazy var _swipe = SwipeHelp(view: self.view, viewController: self)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _swipe.onViewWillAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _swipe.onViewWillDisappear()
    }

    /// 點擊內容：SN 跳選單、參照開閱讀、注腳開 Footer
    fileprivate func doWhenClicked(_ dtext: DText, _ ver: String) {
        let addr = model.addr
        let vers = model.vers
        if dtext.sn != nil {
            SnDTextClickFlow(vc: self, addr: addr, vers: vers).mainAsync(dtext)
        } else if dtext.refDescription != nil {
            RefDTextClickFlow(vc: self, addr: addr, vers: vers).mainAsync(dtext)
        } else if dtext.foot != nil {
            FooterDTextClickFlow(vc: self, vers: ManagerBibleVersions.s.cur).mainAsync(dtext, ver, addr)
        }
    }
    /// 選擇要比較的譯本。比較用的譯本自己維護 (`ManagerBibleVersionsForCompare`)，不要連動閱讀用的 cur
    fileprivate func doPickVersions() {
        let vc = self.gVCVersionsPicker()
        vc.setInitData(model.vers, isUpdateCurVersWhenOkay: false)
        vc.onClickOkay$.addCallback {[weak self] sender, pData in
            if let vers = pData {
                self?.model.setVers(vers)
            }
        }
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

/// 一個譯本的一列：譯本名稱 + 該節經文
struct VersionsCompareRow: Identifiable {
    let id: Int
    /// 譯本代碼，例如 unv
    let ver: String
    /// 譯本中文名，例如 和合本
    let name: String
    let dtexts: [DText]
    /// 台語、客語漢字需要特殊字型
    let isFontOpenHan: Bool
    /// 希伯來文靠右、英文靠左、其它左右對齊
    let alignment: NSTextAlignment
}

/// 譯本比較的狀態：目前節、要比較的譯本、每個譯本的經文
@Observable
final class VersionsCompareModel {
    var addr: DAddress
    var vers: [String]
    var rows: [VersionsCompareRow] = []
    var isLoading = false
    /// 每載入一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    var generation: Int = 0

    @ObservationIgnored private var requestId = 0

    init(addr: DAddress) {
        self.addr = addr
        self.vers = ManagerBibleVersionsForCompare.s.cur
    }
    var title: String { addr.toString(ManagerLangSet.s.curTpBookNameLang) }

    func goNext() {
        addr = addr.goNextVerse()
        reload()
    }
    func goPrev() {
        addr = addr.goPrevVerse()
        reload()
    }
    /// 換譯本後記住（下次進入譯本比較沿用）並重抓
    func setVers(_ newVers: [String]) {
        if newVers == vers { return }
        vers = newVers
        ManagerBibleVersionsForCompare.s.updateCur(newVers)
        reload()
    }
    /// 用 addr、vers 重抓。快速連續換節或換譯本時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        let vers = self.vers
        rows = []
        if vers.isEmpty {
            isLoading = false
            return
        }
        isLoading = true

        let dataQ: IVCReadDataQ = ReadDataQ()
        dataQ.qDataForRead$.addCallback {[weak self] sender, pData in
            // 比較只有一節，所以只取第一列，它的 datas 是「每個譯本一個 [DText]」
            let datas = pData?.1.first?.datas ?? []
            DispatchQueue.main.async {
                guard let self = self, self.requestId == id else { return }
                self.setRows(vers, datas)
            }
        }
        dataQ.qDataForReadAsync(addr.toString(ManagerLangSet.s.curTpBookNameLang), vers)
    }
    private func setRows(_ vers: [String], _ datas: [[DText]]) {
        let isOpenHans = BibleVersionFonts().mainIsOpenHanBibleTCs(vers)
        let alignments = getTpTextAlignmentsViaBibleVersions(vers)
        rows = vers.indices.map { i in
            VersionsCompareRow(id: i,
                               ver: vers[i],
                               name: BibleVersionConvertor().na2cna(vers[i]),
                               dtexts: datas.indices.contains(i) ? datas[i] : [DText(NSLocalizedString("(此譯本無)", comment: ""))],
                               isFontOpenHan: isOpenHans[i],
                               alignment: alignments[i])
        }
        generation += 1
        isLoading = false
    }
}

/// 譯本比較畫面：每個譯本一個區段（標題是譯本名稱），右上角可選譯本、上一節、下一節
struct VersionsCompareView: View {
    let model: VersionsCompareModel
    let onTap: (DText, String) -> Void
    let onPickVers: () -> Void

    var body: some View {
        List {
            ForEach(model.rows) { row in
                Section {
                    DTextContentView(dtexts: row.dtexts,
                                     generation: model.generation,
                                     isVisibleSn: false,
                                     onTapRef: { _ in },
                                     isFontOpenHan: row.isFontOpenHan,
                                     alignment: row.alignment,
                                     onTapAny: { dtext in onTap(dtext, row.ver) })
                } header: {
                    Text(row.name)
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if model.isLoading {
                ProgressView(NSLocalizedString("取得資料中...", comment: ""))
            } else if model.rows.isEmpty {
                ContentUnavailableView {
                    Label(NSLocalizedString("尚未選擇譯本", comment: ""), systemImage: "books.vertical")
                } actions: {
                    Button(NSLocalizedString("選擇譯本", comment: ""), action: onPickVers)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(NSLocalizedString("譯本比較", comment: ""))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.title)
                        .font(.headline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: onPickVers) {
                    Label(NSLocalizedString("選擇譯本", comment: ""), systemImage: "books.vertical")
                }
                Button { model.goPrev() } label: {
                    Label(NSLocalizedString("上一節", comment: ""), systemImage: "arrow.left")
                }
                Button { model.goNext() } label: {
                    Label(NSLocalizedString("下一節", comment: ""), systemImage: "arrow.right")
                }
            }
        }
    }
}
