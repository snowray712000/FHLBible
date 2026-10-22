//
//  VCBookChapPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/1.
//  2026/10/21 改用 SwiftUI 重寫。
//
//  書卷選擇 (選書卷，再選章)。
//  設計成「可獨立搬進 FHLCommon」：只依賴 FHLCommon 的公開 API (BibleChapCount、BibleConstants、
//  ManagerLangSet、ManagerFontScale、get_booknames_via_tp、IjnEventOnce)，不依賴 FHLBible 的任何型別。
//  (檔名沿用舊的 VCBookChapPicker.swift 以免動 pbxproj；搬進 FHLCommon 時請改名。)
//

import UIKit
import SwiftUI
import FHLCommon

// MARK: - UIKit 入口

/// 書卷選擇。以 `BookChapPickerViewController(book:chap:)` 建立後 push，不再經由 storyboard。
/// 選定後：先返回上一個畫面，再用 `onClick$` 通知 (idBook, idChap)，與舊的 FHLCommon.VCBookChapPicker 契約相同；
/// 沒選就離開則不通知。
final class BookChapPickerViewController: UIHostingController<BookChapPickerView> {
    var onClick$: IjnEventOnce<UIView,(idBook:Int,idChap:Int)> = IjnEventOnce()

    /// - Parameters:
    ///   - book: 目前的書卷 1~66 (用來標示與捲動到定位)；不在範圍內則不標示
    ///   - chap: 目前的章
    init(book: Int, chap: Int) {
        let model = BookChapPickerModel(curBook: book, curChap: chap)
        super.init(rootView: BookChapPickerView(model: model, onPick: { _, _ in }))
        rootView = BookChapPickerView(model: model, onPick: { [weak self] idBook, idChap in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: false)
            self.onClick$.triggerAndCleanCallback(self.view, (idBook: idBook, idChap: idChap))
        })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: BookChapPickerView(model: BookChapPickerModel(curBook: 1, curChap: 1), onPick: { _, _ in }))
    }
}

// MARK: - Model

/// 書卷排列方式
enum BookChapPickerOrder: Hashable {
    /// 聖經順序 (摩西五經、歷史書…)
    case canon
    /// 希伯來順序 (律法書、先知書、聖卷)；只影響舊約，新約不變
    case hebrew
}

/// 一個區段 (一個分類標題 + 其下的書卷)
struct BookChapPickerSection: Identifiable {
    let title: String
    /// 書卷編號，1 是創世記、66 是啟示錄
    let books: [Int]
    var id: String { title }
}

/// 「要選章的那本書」，給 `.sheet(item:)` 用
struct BookChapPickerChapTarget: Identifiable {
    let book: Int
    var id: Int { book }
}

@Observable
final class BookChapPickerModel {
    /// 目前的書卷 (1~66)，沒有則為 nil
    let curBook: Int?
    let curChap: Int

    var order: BookChapPickerOrder = .canon
    /// 顯示完整書名 (創世記) 或簡稱 (創)；會記住使用者的選擇
    var showsFullName: Bool {
        didSet { UserDefaults.standard.set(showsFullName, forKey: BookChapPickerModel.keyShowsFullName) }
    }
    /// 非 nil 時，顯示該書的選章 sheet
    var chapTarget: BookChapPickerChapTarget?

    static let keyShowsFullName = "BookChapPickerShowsFullName"

    init(curBook: Int, curChap: Int) {
        self.curBook = (1...66).contains(curBook) ? curBook : nil
        self.curChap = curChap
        self.showsFullName = UserDefaults.standard.bool(forKey: BookChapPickerModel.keyShowsFullName)
    }

    // MARK: 書名

    /// 完整書名用哪個語言，隨目前語系：簡體、繁體、其他 (英文)
    private var fullNameLang: BookNameLang {
        switch ManagerLangSet.s.curTpBookNameLang {
        case .太GB: return .马太福音GB
        case .太: return .馬太福音
        default: return .Matthew
        }
    }
    private var shortNames: [String] { get_booknames_via_tp(tp: ManagerLangSet.s.curTpBookNameLang) }
    private var fullNames: [String] { get_booknames_via_tp(tp: fullNameLang) }

    /// 按鈕上顯示的書名 (依 `showsFullName`)
    func displayName(_ book: Int) -> String {
        (showsFullName ? fullNames : shortNames)[book - 1]
    }
    /// 完整書名 (標題、VoiceOver 用)
    func fullName(_ book: Int) -> String { fullNames[book - 1] }

    // MARK: 區段

    var sections: [BookChapPickerSection] {
        order == .canon ? BookChapPickerModel.canonSections : BookChapPickerModel.hebrewSections
    }

    /// 聖經順序：舊約 + 新約的分類，沿用搜尋統計用的分類 (BibleBookClassor，含簡繁)，
    /// 跳過最前面三個總類 (全部、舊約、新約)。
    private static var canonSections: [BookChapPickerSection] {
        let names = ManagerLangSet.s.curBookClassorNaOrder.dropFirst(3)
        let dict = ManagerLangSet.s.curBookClassor
        return names.compactMap { name in
            dict[name].map { BookChapPickerSection(title: name, books: $0) }
        }
    }
    /// 希伯來順序：舊約改成 律法書 / 先知書 / 聖卷，後面接新約的分類。
    private static var hebrewSections: [BookChapPickerSection] {
        let order = BibleConstants.s.ORDER_OF_HEBREW // 39 本，依希伯來聖經順序
        let ot = [
            BookChapPickerSection(title: NSLocalizedString("律法書", comment: "希伯來聖經的分類"), books: Array(order[0..<5])),
            BookChapPickerSection(title: NSLocalizedString("先知書", comment: "希伯來聖經的分類"), books: Array(order[5..<26])),
            BookChapPickerSection(title: NSLocalizedString("聖卷", comment: "希伯來聖經的分類"), books: Array(order[26..<39])),
        ]
        return ot + canonSections.filter { $0.books.first! >= 40 }
    }

    // MARK: 章

    func chapCount(_ book: Int) -> Int { BibleChapCount.getChapCount(book) }
    /// 只有 1 章的書 (俄巴底亞書…)，選了書就不用再選章
    func hasSingleChap(_ book: Int) -> Bool { chapCount(book) == 1 }
}

// MARK: - View

struct BookChapPickerView: View {
    @State var model: BookChapPickerModel
    /// 選定 (書, 章)
    let onPick: (Int, Int) -> Void

    /// 選章 sheet 收起之後才通知，避免 sheet 還在動畫時就 pop 畫面
    @State private var pending: (book: Int, chap: Int)?
    /// 隨系統文字大小，並套用 App 內的字型縮放設定
    @ScaledMetric(relativeTo: .body) private var fontSize = 17 * CGFloat(ManagerFontScale.s.cur)

    private var columns: [GridItem] {
        let min = model.showsFullName ? fontSize * 6.5 : fontSize * 3.2
        return [GridItem(.adaptive(minimum: min), spacing: 8)]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if let cur = model.curBook, !model.hasSingleChap(cur) {
                        currentRow(cur)
                    }
                    ForEach(model.sections) { section in
                        Section {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(section.books, id: \.self) { book in
                                    bookButton(book)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        } header: {
                            sectionHeader(section.title)
                        }
                    }
                }
            }
            .onAppear { scrollToCurBook(proxy) }
            .onChange(of: model.order) { scrollToCurBook(proxy) }
            .onChange(of: model.showsFullName) { scrollToCurBook(proxy) }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker(NSLocalizedString("排列方式", comment: ""), selection: $model.order) {
                Text(NSLocalizedString("聖經順序", comment: "")).tag(BookChapPickerOrder.canon)
                Text(NSLocalizedString("希伯來順序", comment: "")).tag(BookChapPickerOrder.hebrew)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(NSLocalizedString("書卷選擇", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(NSLocalizedString("完整名稱", comment: ""), isOn: $model.showsFullName)
                    .toggleStyle(.button)
            }
        }
        .sheet(item: $model.chapTarget, onDismiss: {
            if let p = pending {
                pending = nil
                onPick(p.book, p.chap)
            }
        }) { target in
            BookChapPickerChapSheet(
                title: model.fullName(target.book),
                chapCount: model.chapCount(target.book),
                curChap: target.book == model.curBook ? model.curChap : nil,
                fontSize: fontSize
            ) { chap in
                pending = (target.book, chap)
                model.chapTarget = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func scrollToCurBook(_ proxy: ScrollViewProxy) {
        guard let cur = model.curBook else { return }
        // 等版面排好才捲動，LazyVStack 才找得到該列
        DispatchQueue.main.async {
            proxy.scrollTo(cur, anchor: .center)
        }
    }

    /// 選書。只有 1 章的書直接選定，其他的再選章
    private func pickBook(_ book: Int) {
        if model.hasSingleChap(book) {
            onPick(book, 1)
        } else {
            model.chapTarget = BookChapPickerChapTarget(book: book)
        }
    }

    /// 「目前閱讀」捷徑：最常見的情境是在同一本書換章
    private func currentRow(_ cur: Int) -> some View {
        Button {
            pickBook(cur)
        } label: {
            HStack {
                Text(verbatim: "\(NSLocalizedString("目前閱讀", comment: "")) \(model.fullName(cur)) \(model.curChap)")
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            }
            .font(.system(size: fontSize))
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: fontSize * 0.9, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)
    }

    private func bookButton(_ book: Int) -> some View {
        let isCur = book == model.curBook
        return Button {
            pickBook(book)
        } label: {
            Text(model.displayName(book))
                .font(.system(size: fontSize))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isCur ? Color.white : Color.primary)
                .background(isCur ? Color.accentColor : Color(.secondarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(book)
        .accessibilityLabel(model.fullName(book))
        .accessibilityAddTraits(isCur ? .isSelected : [])
    }
}

/// 選章。以 sheet 呈現，章數多 (詩篇 150) 時可拉到最大
private struct BookChapPickerChapSheet: View {
    let title: String
    let chapCount: Int
    /// 目前的章 (只有該書就是目前書卷時才有)
    let curChap: Int?
    let fontSize: CGFloat
    let onPick: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: fontSize * 3.4), spacing: 8)], spacing: 8) {
                        ForEach(1...chapCount, id: \.self) { chap in
                            chapButton(chap)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    guard let c = curChap else { return }
                    DispatchQueue.main.async { proxy.scrollTo(c, anchor: .center) }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("取消", comment: "")) { dismiss() }
                }
            }
        }
    }

    private func chapButton(_ chap: Int) -> some View {
        let isCur = chap == curChap
        return Button {
            onPick(chap)
        } label: {
            Text(verbatim: "\(chap)")
                .font(.system(size: fontSize).monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isCur ? Color.white : Color.primary)
                .background(isCur ? Color.accentColor : Color(.secondarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(chap)
        .accessibilityLabel(String(format: NSLocalizedString("第%d章", comment: ""), chap))
        .accessibilityAddTraits(isCur ? .isSelected : [])
    }
}
