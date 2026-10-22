//
//  ViewSearchFilter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import SwiftUI
import FHLCommon

extension SearchData.Filter: Identifiable {
    /// 分類與書卷可能同名（例如「全部」），所以 id 含組別
    public var id: String { "\(na2)|\(na)" }
}

/// 搜尋結果上方的篩選列：左邊切換「分類 / 書卷」，右邊是該組每個項目與筆數的標籤，可橫向捲動。
/// 只讀 model 的篩選相關屬性，所以載入經文時不會跟著重畫。
struct SearchFilterBar: View {
    let model: SearchResultModel

    var body: some View {
        HStack(spacing: 8) {
            Picker(NSLocalizedString("篩選方式", comment: ""),
                   selection: Binding(get: { model.group }, set: { model.group = $0 })) {
                Text(NSLocalizedString("分類", comment: "")).tag(SearchFilterGroup.classor)
                Text(NSLocalizedString("書卷", comment: "")).tag(SearchFilterGroup.book)
            }
            .pickerStyle(.segmented)
            .frame(width: 128)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(model.visibleFilters) { f in
                            chip(f).id(f.id)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear { scrollToSelected(proxy, animated: false) }
                .onChange(of: model.group) { _, _ in scrollToSelected(proxy, animated: false) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .sensoryFeedback(.selection, trigger: model.selectedOpt)
    }

    private func chip(_ f: SearchData.Filter) -> some View {
        let isSelected = model.isSelected(f)
        return Button { model.select(f) } label: {
            HStack(spacing: 4) {
                Text(f.na)
                Text("\(f.cnt)")
                    .font(.caption2.monospacedDigit())
                    .opacity(0.7)
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .tint(isSelected ? .accentColor : .secondary)
        .fontWeight(isSelected ? .semibold : .regular)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(f.na) \(f.cnt)")
    }

    private func scrollToSelected(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let f = model.visibleFilters.first(where: { model.isSelected($0) }) else { return }
        if animated {
            withAnimation { proxy.scrollTo(f.id, anchor: .center) }
        } else {
            proxy.scrollTo(f.id, anchor: .center)
        }
    }
}
