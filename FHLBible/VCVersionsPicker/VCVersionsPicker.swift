//
//  VCVersionsPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/4.
//  2026/10/23 改用 SwiftUI 重寫。
//
//  譯本選擇 (畫面上一律稱「譯本」)。
//  畫面：已選取 (點一下取消) → 最近使用 (點一下加入) → 分類標籤 → 該分類的譯本清單 (點一下勾選)；
//  上方系統搜尋列可跨分類找譯本；「⋯」選單有調整順序、全部取消、放棄變更。
//

import UIKit
import SwiftUI
import FHLCommon

// MARK: - UIKit 入口

/// 譯本選擇。以 `VCVersionsPicker(vers:updatesCurWhenDone:)` 建立後 push，不再經由 storyboard。
/// 「完成」或返回 (含右滑返回) 都算確認：先返回上一個畫面，再用 `onClickOkay$` 通知選定的譯本 (順序即選取順序)；
/// 「放棄變更」則什麼都不存、也不通知。
final class VCVersionsPicker : UIHostingController<VersionsPickerView> {
    var onClickOkay$: IjnEventOnce<Any,[String]> = IjnEventOnce()

    private let model: VersionsPickerModel
    private let updatesCurWhenDone: Bool
    private var isFinished = false

    /// - Parameters:
    ///   - vers: 目前選取的譯本 (unv、cuwv …)
    ///   - updatesCurWhenDone: 確認時是否更新「閱讀」用的目前譯本。譯本比較有自己的記憶，不要連動，傳 false。
    ///     為 true 時至少要選一個譯本，全部取消則維持原本的設定。
    init(vers: [String], updatesCurWhenDone: Bool = true) {
        let m = VersionsPickerModel(selected: vers, requiresOne: updatesCurWhenDone)
        self.model = m
        self.updatesCurWhenDone = updatesCurWhenDone
        super.init(rootView: VersionsPickerView(model: m, onDone: { }, onDiscard: { }))
        rootView = VersionsPickerView(model: m,
                                      onDone: { [weak self] in self?.navigationController?.popViewController(animated: true) },
                                      onDiscard: { [weak self] in
                                          self?.isFinished = true // 放棄：viewDidDisappear 不要再確認
                                          self?.navigationController?.popViewController(animated: true)
                                      })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let m = VersionsPickerModel(selected: [], requiresOne: true)
        self.model = m
        self.updatesCurWhenDone = true
        super.init(coder: aDecoder, rootView: VersionsPickerView(model: m, onDone: { }, onDiscard: { }))
    }

    /// 返回也同時是確認，好像是按下「完成」一樣
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        commitIfNeeded()
    }
    private func commitIfNeeded() {
        if isFinished { return }
        isFinished = true

        model.saveState()
        let vers = model.selected
        if updatesCurWhenDone {
            if vers.isEmpty { return } // 閱讀至少要有一個譯本，維持原設定
            ManagerBibleVersions.s.updateCur(vers)
        }
        onClickOkay$.triggerAndCleanCallback(nil, vers)
    }
}

// MARK: - Model

@Observable
final class VersionsPickerModel {
    typealias One = BibleVersionConstants.One
    typealias Group = BibleVersionConstants.OneGroup

    /// 已選取的譯本代碼，順序就是顯示順序
    var selected: [String]
    /// 最近用過、但目前沒選的譯本代碼 (新的在前)
    var recent: [String]
    /// 目前看的分類
    var group: BibleVersionConstants.TpGroup
    /// 中文的「依分類篩選」是否開啟
    var isFilterOn: Bool
    /// 篩選勾選的條件 (教派、文體、年代)
    var filters: Set<BibleVersionConstants.TpChtSub>
    var searchText = ""

    let groups: [Group] = BibleVersionConstants.s.datas
    /// 最近使用最多留幾個
    static let maxRecent = 20
    let requiresOne: Bool
    private let initialSelected: [String]
    private let infoByCode: [String: One]
    private let groupNameByCode: [String: String]

    init(selected: [String], requiresOne: Bool) {
        let groups = BibleVersionConstants.s.datas
        var info: [String: One] = [:]
        var groupName: [String: String] = [:]
        for g in groups {
            for v in g.vers ?? [] {
                info[v.na] = v
                groupName[v.na] = g.cna
            }
        }
        self.infoByCode = info
        self.groupNameByCode = groupName
        self.requiresOne = requiresOne
        self.initialSelected = selected
        self.selected = selected
        // 最近使用：去掉已選取的、不認得的 (例如已下架的譯本)
        self.recent = ManagerBibleVersions.s.recent.filter({ info[$0] != nil && !selected.contains($0) })
        self.group = ManagerBibleVersions.s.optSub
        self.isFilterOn = ManagerBibleVersions.s.isOnSub
        self.filters = Set(ManagerBibleVersions.s.optSub2)
    }

    // MARK: 顯示用

    /// 譯本中文名，找不到就顯示代碼
    func name(_ code: String) -> String { infoByCode[code]?.cna ?? code }

    /// 第二行小字：年份 · 代碼 (搜尋時前面再加分類)
    func caption(_ code: String, includesGroup: Bool) -> String {
        var parts: [String] = []
        if includesGroup, let g = groupNameByCode[code] { parts.append(g) }
        if let yr = infoByCode[code]?.yr, yr > 0 { parts.append(String(yr)) }
        parts.append(code)
        return parts.joined(separator: " · ")
    }
    var isSearching: Bool { !trimmedSearch.isEmpty }
    private var trimmedSearch: String { searchText.trimmingCharacters(in: .whitespaces) }

    /// 目前要列出的譯本：搜尋中 → 全部分類比對名稱或代碼；否則 → 目前分類 (中文可再篩選)
    var visibleVersions: [One] {
        if isSearching {
            let key = trimmedSearch
            return groups.flatMap({ $0.vers ?? [] }).filter({
                $0.cna.localizedCaseInsensitiveContains(key) || $0.na.localizedCaseInsensitiveContains(key)
            })
        }
        let vers = groups.first(where: { $0.na == group })?.vers ?? []
        if group != .ch || !isFilterOn { return vers }
        return vers.filter({ v in
            guard let cds = v.cds else { return true } // 沒有條件的一定顯示
            return cds.allSatisfy({ filters.contains($0) }) // 條件 (教派、文體、年代) 都有勾才顯示
        })
    }
    /// 某分類已選了幾個，顯示在分類標籤上
    func selectedCount(in g: Group) -> Int {
        let codes = Set((g.vers ?? []).map({ $0.na }))
        return selected.filter({ codes.contains($0) }).count
    }
    var hasChanges: Bool { selected != initialSelected }

    // MARK: 動作

    func isSelected(_ code: String) -> Bool { selected.contains(code) }

    func toggle(_ code: String) {
        if isSelected(code) { remove(code) } else { add(code) }
    }
    func add(_ code: String) {
        if isSelected(code) { return }
        selected.append(code)
        recent.removeAll(where: { $0 == code })
    }
    func remove(_ code: String) {
        guard let i = selected.firstIndex(of: code) else { return }
        selected.remove(at: i)
        pushRecent(code)
    }
    func clearSelected() {
        // 最後取消的在最前面，與一個個取消時一致
        selected.forEach({ pushRecent($0) })
        selected.removeAll()
    }
    func move(from: IndexSet, to: Int) { selected.move(fromOffsets: from, toOffset: to) }
    func remove(atOffsets offsets: IndexSet) {
        let codes = offsets.map({ selected[$0] })
        codes.forEach({ remove($0) })
    }
    func toggleFilter(_ t: BibleVersionConstants.TpChtSub) {
        if filters.contains(t) { filters.remove(t) } else { filters.insert(t) }
    }
    private func pushRecent(_ code: String) {
        recent.removeAll(where: { $0 == code })
        recent.insert(code, at: 0)
        if recent.count > Self.maxRecent { recent.removeLast(recent.count - Self.maxRecent) }
    }

    /// 確認時才存 (放棄變更就都不存)。選取的譯本由 `VCVersionsPicker` 存，因為譯本比較不連動 cur。
    func saveState() {
        ManagerBibleVersions.s.updateRecent(recent)
        ManagerBibleVersions.s.updateOptSub(group)
        ManagerBibleVersions.s.updateOnSub(isFilterOn)
        ManagerBibleVersions.s.updateOptSub2(Self.subOrder.filter({ filters.contains($0) }))
    }

    // MARK: 中文次分類 (三列：教派、文體、年代)

    struct FilterRow: Identifiable {
        let title: String
        let items: [BibleVersionConstants.TpChtSub]
        var id: String { title }
    }
    static let subOrder: [BibleVersionConstants.TpChtSub] = filterRows.flatMap({ $0.items })
    static let filterRows: [FilterRow] = [
        FilterRow(title: NSLocalizedString("教派", comment: ""), items: [.pr, .cc, .ro]),
        FilterRow(title: NSLocalizedString("文體", comment: ""), items: [.officer, .ccht, .study]),
        FilterRow(title: NSLocalizedString("年代", comment: ""), items: [.yr1800, .yr1850, .yr1919, .yr1960, .yrnow]),
    ]
}

// MARK: - View

struct VersionsPickerView: View {
    @Bindable var model: VersionsPickerModel
    /// 按「完成」
    let onDone: () -> Void
    /// 放棄變更並返回
    let onDiscard: () -> Void

    @State private var isReordering = false
    @State private var isAskingDiscard = false

    var body: some View {
        List {
            if isReordering {
                reorderSection
            } else {
                if !model.isSearching {
                    selectedSection
                    if !model.recent.isEmpty { recentSection }
                    groupSection
                }
                versionsSection
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive)) // 調整順序時才有拖曳把手與刪除鈕
        .navigationTitle(NSLocalizedString("譯本選擇", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: Text("搜尋譯本"))
        .toolbar {
            if isReordering {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { isReordering = false }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: onDone)
                }
                ToolbarItem(placement: .topBarTrailing) { moreMenu }
            }
        }
        .confirmationDialog("放棄變更？", isPresented: $isAskingDiscard, titleVisibility: .visible) {
            Button("放棄變更", role: .destructive, action: onDiscard)
            Button("繼續編輯", role: .cancel) { }
        }
    }

    private var moreMenu: some View {
        Menu {
            Button {
                isReordering = true
            } label: {
                Label("調整順序", systemImage: "arrow.up.arrow.down")
            }
            .disabled(model.selected.count < 2)
            Button(role: .destructive) {
                withAnimation { model.clearSelected() }
            } label: {
                Label("全部取消選取", systemImage: "xmark.circle")
            }
            .disabled(model.selected.isEmpty)
            Divider()
            Button(role: .destructive) {
                if model.hasChanges { isAskingDiscard = true } else { onDiscard() }
            } label: {
                Label("放棄變更", systemImage: "arrow.uturn.backward")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(Text("更多"))
    }

    // MARK: 區段

    /// 已選取：一列一個，點一下取消
    private var selectedSection: some View {
        Section {
            if model.selected.isEmpty {
                Text("尚未選擇譯本").foregroundStyle(.secondary)
            }
            ForEach(model.selected, id: \.self) { code in
                Button {
                    withAnimation { model.remove(code) }
                } label: {
                    HStack {
                        Text(model.name(code))
                        Spacer()
                        Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("取消選取"))
            }
        } header: {
            Text(String(format: NSLocalizedString("已選取 %d 個譯本", comment: ""), model.selected.count))
        } footer: {
            if model.requiresOne {
                Text("至少要選一個譯本；全部取消時，維持原本的設定")
            }
        }
    }

    /// 調整順序：只列出已選取的，可拖曳、左滑取消
    private var reorderSection: some View {
        Section {
            ForEach(model.selected, id: \.self) { code in
                Text(model.name(code))
            }
            .onMove { model.move(from: $0, to: $1) }
            .onDelete { model.remove(atOffsets: $0) }
        } header: {
            Text("調整順序")
        } footer: {
            Text("拖曳右側的把手調整順序，閱讀時依這個順序排列")
        }
    }

    /// 最近用過的：橫向捲動，點一下加入
    private var recentSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.recent, id: \.self) { code in
                        PickerChip(title: model.name(code), isOn: false, systemImage: "plus") {
                            withAnimation { model.add(code) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets())
        } header: {
            Text("最近使用")
        }
    }

    /// 分類標籤 (+ 中文的篩選)
    private var groupSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.groups, id: \.na) { g in
                        PickerChip(title: g.cna, isOn: model.group == g.na, badge: model.selectedCount(in: g)) {
                            model.group = g.na
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets())

            if model.group == .ch {
                Toggle("依分類篩選", isOn: $model.isFilterOn)
                if model.isFilterOn {
                    ForEach(VersionsPickerModel.filterRows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.title).font(.footnote).foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(row.items, id: \.self) { t in
                                        PickerChip(title: NSLocalizedString(t.rawValue, comment: ""), isOn: model.filters.contains(t)) {
                                            model.toggleFilter(t)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("分類")
        }
    }

    /// 譯本清單：點一下勾選 / 取消
    @ViewBuilder
    private var versionsSection: some View {
        let items = model.visibleVersions
        if items.isEmpty {
            Section {
                if model.isSearching {
                    ContentUnavailableView.search(text: model.searchText)
                } else {
                    Text("此篩選沒有結果").foregroundStyle(.secondary)
                }
            }
        } else {
            Section {
                ForEach(items, id: \.na) { v in
                    Button {
                        model.toggle(v.na)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(v.cna)
                                Text(model.caption(v.na, includesGroup: model.isSearching))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if model.isSelected(v.na) {
                                Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.isSelected(v.na) ? .isSelected : [])
                }
            }
        }
    }
}

/// 膠囊型的標籤按鈕：選中時填滿主題色
private struct PickerChip: View {
    let title: String
    let isOn: Bool
    var systemImage: String? = nil
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage).font(.caption.weight(.semibold))
                }
                Text(title)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 5)
                        .background((isOn ? Color.white : Color.accentColor).opacity(0.25), in: Capsule())
                }
            }
            .font(.subheadline)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background(isOn ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
