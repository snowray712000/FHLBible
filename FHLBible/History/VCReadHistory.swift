//
//  VCReadHistory.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import UIKit
import SwiftUI
import FHLCommon

/// 閱讀記錄。畫面是 SwiftUI (`ReadHistoryView`)，以 `VCReadHistory()` 建立後 push，不再經由 storyboard。
/// 點選一筆：先返回閱讀畫面，再用 `onClickAddr$` 通知選到的位址字串 (離開時沒選則通知 nil，與舊行為相同)。
class VCReadHistory: UIHostingController<ReadHistoryView> {
    var onClickAddr$: IjnEventOnce<Any,String> = IjnEventOnce()

    init() {
        super.init(rootView: ReadHistoryView(model: ReadHistoryModel(), onPick: { _ in }, onClear: { }))
        rootView = ReadHistoryView(model: ReadHistoryModel(), onPick: { [weak self] addr in
            self?.navigationController?.popViewController(animated: false)
            self?.onClickAddr$.triggerAndCleanCallback(nil, addr)
        }, onClear: { [weak self] in
            self?.navigationController?.popViewController(animated: false)
        })
    }
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: ReadHistoryView(model: ReadHistoryModel(), onPick: { _ in }, onClear: { }))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.onClickAddr$.triggerAndCleanCallback(nil, nil)
    }
}

@Observable
final class ReadHistoryModel {
    /// 由新到舊，每筆是位址字串 (如「創 1:1」)
    var items: [String]

    init() {
        items = ManagerHistoryOfRead.s.cur
    }
    /// 清空：只留最新的一筆 (目前正在讀的)
    func clearAllButLatest() {
        guard let first = items.first else { return }
        items = [first]
        ManagerHistoryOfRead.s.updateCur(items)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        ManagerHistoryOfRead.s.updateCur(items)
    }
}

struct ReadHistoryView: View {
    @State var model: ReadHistoryModel
    let onPick: (String) -> Void
    /// 清空之後 (與舊行為相同，會回到閱讀畫面)
    let onClear: () -> Void
    @State private var isConfirmingClear = false

    var body: some View {
        Group {
            if model.items.isEmpty {
                ContentUnavailableView(NSLocalizedString("閱讀記錄", comment: ""), systemImage: "clock")
            } else {
                List {
                    ForEach(Array(model.items.enumerated()), id: \.offset) { i, addr in
                        Button {
                            onPick(addr)
                        } label: {
                            Text(verbatim: "\(i + 1). \(addr)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { model.remove(at: $0) }
                }
            }
        }
        .navigationTitle(NSLocalizedString("閱讀記錄", comment: "閱讀記錄"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isConfirmingClear = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(model.items.count <= 1)
                .accessibilityLabel(NSLocalizedString("清空閱讀記錄", comment: ""))
            }
        }
        .confirmationDialog(NSLocalizedString("清空閱讀記錄", comment: ""), isPresented: $isConfirmingClear, titleVisibility: .hidden) {
            Button(NSLocalizedString("清空閱讀記錄", comment: ""), role: .destructive) {
                model.clearAllButLatest()
                onClear()
            }
        }
    }
}
