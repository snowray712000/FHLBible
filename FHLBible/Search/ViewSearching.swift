//
//  ViewSearching.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import SwiftUI
import FHLCommon

/// 「搜尋」輸入畫面的狀態：輸入中的文字、搜尋記錄。
/// 記錄存在 `ManagerSearchHistory`（UserDefaults 字串陣列），新的在最前面。
@Observable
final class SearchingModel {
    var text = ""
    /// 由新到舊
    var history: [String]

    init() {
        history = ManagerSearchHistory.s.cur
    }
    var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// 邊輸入邊過濾記錄；沒輸入時是全部
    var filteredHistory: [String] {
        let t = trimmedText
        if t.isEmpty { return history }
        return history.filter { $0.localizedCaseInsensitiveContains(t) }
    }
    /// 要搜尋這個字：去掉頭尾空白，移到記錄最前面（重複的不會再多一筆）。空字串回 nil，表示不搜尋。
    func commit(_ raw: String) -> String? {
        let w = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if w.isEmpty { return nil }
        var r = history
        r.removeAll { $0 == w }
        r.insert(w, at: 0)
        history = r
        ManagerSearchHistory.s.updateCur(r)
        return w
    }
    func remove(_ item: String) {
        history.removeAll { $0 == item }
        ManagerSearchHistory.s.updateCur(history)
    }
    func clearAll() {
        history = []
        ManagerSearchHistory.s.updateCur([])
    }
}

/// 搜尋輸入畫面：系統搜尋列 + 搜尋記錄。
/// 按下鍵盤的「搜尋」、點「搜尋「…」」或點某筆記錄，都是呼叫 `onSearch`（由 `VCSearching` 負責返回並通知）。
struct SearchingView: View {
    @State var model: SearchingModel
    let onSearch: (String) -> Void

    @State private var isSearchPresented = false
    @State private var isConfirmingClear = false

    var body: some View {
        List {
            if !model.trimmedText.isEmpty {
                Section {
                    Button { search(model.text) } label: {
                        Label(String(format: NSLocalizedString("搜尋「%@」", comment: ""), model.trimmedText),
                              systemImage: "magnifyingglass")
                    }
                }
            }
            if !model.filteredHistory.isEmpty {
                Section {
                    ForEach(model.filteredHistory, id: \.self) { item in
                        Button { search(item) } label: {
                            Label {
                                Text(item)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } icon: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { model.remove(item) } label: {
                                Label(NSLocalizedString("刪除", comment: ""), systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("搜尋記錄", comment: ""))
                }
                // 搜尋列在輸入狀態時，導覽列的垃圾桶會被系統收起來，所以清單裡也放一個
                if model.trimmedText.isEmpty {
                    Section {
                        Button(role: .destructive) { isConfirmingClear = true } label: {
                            Text(NSLocalizedString("清除搜尋記錄", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .overlay {
            // 還沒有記錄、也還沒輸入時，說明可以搜尋什麼
            if model.history.isEmpty && model.trimmedText.isEmpty {
                ContentUnavailableView {
                    Label(NSLocalizedString("搜尋聖經", comment: ""), systemImage: "magnifyingglass")
                } description: {
                    Text(NSLocalizedString("輸入關鍵字，多個關鍵字用空格分開；也可以輸入原文編號，例如 H430、G3056。", comment: ""))
                }
            }
        }
        .searchable(text: $model.text,
                    isPresented: $isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(NSLocalizedString("關鍵字", comment: "")))
        .onSubmit(of: .search) { search(model.text) }
        .navigationTitle(NSLocalizedString("搜尋", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isConfirmingClear = true } label: {
                    Label(NSLocalizedString("清除搜尋記錄", comment: ""), systemImage: "trash")
                }
                .disabled(model.history.isEmpty)
            }
        }
        .confirmationDialog(NSLocalizedString("清除搜尋記錄", comment: ""), isPresented: $isConfirmingClear, titleVisibility: .hidden) {
            Button(NSLocalizedString("清除搜尋記錄", comment: ""), role: .destructive) { model.clearAll() }
        }
        .task {
            // 一進來就可以打字
            isSearchPresented = true
        }
    }

    private func search(_ raw: String) {
        guard let w = model.commit(raw) else { return }
        isSearchPresented = false
        onSearch(w)
    }
}
