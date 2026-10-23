//
//  VCParsing.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/2.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon
import OSLog

/// Parsing（原文逐字分析）。畫面是 SwiftUI (`ParsingView`)，內容仍用 `ViewDisplayCell` (希伯來文、中文要用 App 的字型設定)。
/// 以 `VCParsing(addr:vers:)` 建立後 push，不再經由 storyboard。
/// vers 是因為按了某個 SN 後（彙編、字典），有時會需要，而非 Parsing 真的需要
class VCParsing: UIHostingController<ParsingView> {
    private let model: ParsingModel

    init(addr: DAddress, vers: [String]) {
        let m = ParsingModel(addr: addr, vers: vers)
        self.model = m
        super.init(rootView: ParsingView(model: m, onTapSn: { _ in }, onPickBook: {}))
        rootView = ParsingView(model: m,
                               onTapSn: { [weak self] dtext in self?.doWhenSnClicked(dtext) },
                               onPickBook: { [weak self] in self?.doPickBook() })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = ParsingModel(addr: DAddress(1, 1, 1), vers: [])
        self.model = m
        super.init(coder: aDecoder, rootView: ParsingView(model: m, onTapSn: { _ in }, onPickBook: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 這裡刻意不用 SwipeHelp：
        // 舊版為了避免「字型放大時要左右捲動卻誤切換上下節」，把左右滑改成什麼都不做，結果連系統的「右滑返回」都被停用。
        // 新版內容會自動換行，不需要左右捲動，所以不再攔截手勢，右滑可以直接返回。

        // 開始動作
        model.reload()
    }

    /// 點了某個 SN：跳出選單（彙編、Parsing、字典…）
    private func doWhenSnClicked(_ dtext: DText) {
        guard dtext.sn != nil else { return }
        SnDTextClickFlow(vc: self, addr: model.addr, vers: model.vers).mainAsync(dtext)
    }
    /// 點了標題：選其它書卷、章。選了之後以該章第 1 節重新查詢
    private func doPickBook() {
        let r1 = BookChapPickerViewController(book: model.addr.book, chap: model.addr.chap)
        r1.onClick$.addCallback { [weak self] sender, pData in
            guard let self = self, let pData = pData else { return }
            self.model.go(DAddress(book: pData.idBook, chap: pData.idChap, verse: 1))
        }
        navigationController?.pushViewController(r1, animated: false)
    }
}

/// Parsing 畫面：一個分句（原文一行、中文一行）一個區段，其下是逐字分析的卡片；
/// 標題是目前的節（點了選書卷），右上角是上一節、下一節
struct ParsingView: View {
    let model: ParsingModel
    let onTapSn: (DText) -> Void
    let onPickBook: () -> Void

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: onPickBook) {
                        HStack(spacing: 4) {
                            Text(model.title)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(model.title)
                    .accessibilityHint(NSLocalizedString("聖經目錄", comment: ""))
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { model.goPrev() } label: {
                        Label(NSLocalizedString("上一節", comment: ""), systemImage: "arrow.left")
                            .labelStyle(.iconOnly)
                    }
                    Button { model.goNext() } label: {
                        Label(NSLocalizedString("下一節", comment: ""), systemImage: "arrow.right")
                            .labelStyle(.iconOnly)
                    }
                }
            }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView(NSLocalizedString("取得資料中...", comment: ""))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            ContentUnavailableView {
                Label(NSLocalizedString("沒有 Parsing 資料", comment: ""), systemImage: "text.magnifyingglass")
            } description: {
                Text(NSLocalizedString("這一節沒有原文分析資料，或需要確認網路連線後再試一次。", comment: ""))
            } actions: {
                Button(NSLocalizedString("重試", comment: "")) { model.reload() }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            List {
                ForEach(model.clauses) { clause in
                    Section {
                        ParsingClauseRow(clause: clause,
                                         isRightToLeft: model.isRightToLeft,
                                         generation: model.generation)
                        ForEach(clause.words) { word in
                            ParsingWordRow(word: word, onTapSn: onTapSn)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

/// 一個分句：原文在上，中文翻譯在下。希伯來文由右往左，靠右對齊
private struct ParsingClauseRow: View {
    let clause: ParsingClause
    let isRightToLeft: Bool
    let generation: Int

    var body: some View {
        let align: NSTextAlignment = isRightToLeft ? .right : .left
        VStack(alignment: .leading, spacing: 8) {
            DTextContentView(dtexts: clause.w, generation: generation, isVisibleSn: true,
                             onTapRef: { _ in }, alignment: align)
            DTextContentView(dtexts: clause.cht, generation: generation, isVisibleSn: true,
                             onTapRef: { _ in }, alignment: align)
        }
        .padding(.horizontal, -5) // UITextView 左右各有 5pt 的 lineFragmentPadding，扣掉才會和下面的卡片對齊
        .padding(.vertical, 4)
    }
}

/// 一個原文字的分析：SN 按鈕、原文字，下面依序是 原型、簡義、分析、備註（空的不顯示）
private struct ParsingWordRow: View {
    let word: ParsingWord
    let onTapSn: (DText) -> Void
    /// 左邊小標題的寬度，隨 Dynamic Type 放大
    @ScaledMetric(relativeTo: .footnote) private var labelWidth: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Button { onTapSn(word.sn) } label: {
                    Text(word.sn.w ?? "").monospacedDigit()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                Text(word.word.w ?? "")
                    .font(.headline)
                Spacer(minLength: 0)
            }
            if let orig = word.orig.w, !orig.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                field(Text("原型")) { Text(orig).textSelection(.enabled) }
            }
            if !isBlank(word.exp) {
                field(Text("簡義")) { plain(word.exp) }
            }
            if !isBlank(word.wform) {
                field(Text("分析")) { plain(word.wform) }
            }
            if !isBlank(word.remark) {
                field(Text("備註")) { plain(word.remark) }
            }
        }
        .padding(.vertical, 4)
    }

    private func field<C: View>(_ title: Text, @ViewBuilder _ body: () -> C) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            title
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .leading)
            body()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    /// 簡義、分析、備註都是純文字（沒有可點的參照），用原生 Text，字型隨 Dynamic Type、也能長按選取
    private func plain(_ dtexts: [DText]) -> some View {
        Text(dtexts.compactMap { $0.w }.joined()
            .trimmingCharacters(in: .whitespacesAndNewlines))
            .textSelection(.enabled)
    }
    private func isBlank(_ dtexts: [DText]) -> Bool {
        dtexts.allSatisfy { ($0.w ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

/// Parsing 的狀態：目前的節、載入階段、分句（原文、中文、逐字分析）
@Observable
final class ParsingModel {
    enum Phase { case loading, loaded, failed }

    private static let logger = Logger(subsystem: "com.FHLBible", category: "VCParsing")

    private(set) var addr: DAddress
    let vers: [String]
    private(set) var phase: Phase = .loading
    private(set) var clauses: [ParsingClause] = []
    /// 舊約（希伯來文）由右往左
    private(set) var isRightToLeft = false
    /// 每載入一次加 1，讓 UIKit 內容只在真的換資料時才重畫
    private(set) var generation = 0

    @ObservationIgnored private var requestId = 0

    init(addr: DAddress, vers: [String]) {
        self.addr = addr
        self.vers = vers
    }

    /// 例 羅1:1
    var title: String {
        "\(BibleBookNames.getBookName(addr.book, .太))\(addr.chap):\(addr.verse)"
    }

    func goNext() { go(addr.goNextVerse()) }
    func goPrev() { go(addr.goPrevVerse()) }
    func go(_ newAddr: DAddress) {
        addr = newAddr
        reload()
    }

    /// 重抓目前節。有離線資料庫就用離線的，否則用 qp API。
    /// 快速連續換節時，舊的回應（requestId 不同）會被丟掉。
    func reload() {
        requestId += 1
        let id = requestId
        phase = .loading

        let reloader: VCParsing.IReloadData = VCParsing.ReloadDataAutoUseOfflineOrScApi()
        reloader.apiFinished$.addCallback { [weak self] sender, pData in
            var result: (clauses: [ParsingClause], isHebrew: Bool)? = nil
            if sender != nil {
                Self.logger.error("parsing failed: \(sender?.first?.w ?? "")")
            } else if let data = pData?.data, !data.record.isEmpty {
                result = ConvertorQp2VCParsingData(data).main()
            }
            DispatchQueue.main.async {
                guard let self = self, self.requestId == id else { return }
                if let result = result, !result.clauses.isEmpty {
                    self.isRightToLeft = result.isHebrew
                    self.clauses = result.clauses
                    self.generation += 1
                    self.phase = .loaded
                } else {
                    self.clauses = []
                    self.phase = .failed
                }
            }
        }
        reloader.reloadAsync(addr)
    }
}
