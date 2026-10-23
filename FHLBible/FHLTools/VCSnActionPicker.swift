//
//  VCSnActionPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit
import SwiftUI
import FHLCommon

/// 點到某個東西 (原文編號 SN、經文位置) 後，跳出的「選一個動作」半版選單。
/// 畫面是 SwiftUI (`ActionPickerView`)，由 `presentActionPicker` 以半版 sheet 顯示，不再經由 storyboard。
/// `presentSnActionPicker` (原文編號) 與 `presentVerseActionPicker` (經文位置，見 VCVerseActionPicker.swift) 共用它。
struct ActionPickerItem<Action>: Identifiable {
    let title: String
    let detail: String
    let systemImage: String
    let action: Action
    var id: String { title }
}

struct ActionPickerView<Action>: View {
    let title: String?
    let items: [ActionPickerItem<Action>]
    let onPick: (Action) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(items) { item in
                Button {
                    onPick(item.action)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: item.systemImage)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if !item.detail.isEmpty {
                                Text(item.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("取消", comment: ""), action: onCancel)
                }
            }
        }
    }
}

/// 讓 SwiftUI 的按鈕能關閉「包著它的 UIHostingController」，又不會互相強引用
private final class ActionPickerHostBox {
    weak var vc: UIViewController?
}

extension UIViewController {
    /// 以半版 sheet 顯示動作選單。選了動作時，先關閉選單，**關閉後**才呼叫 `onPick` (之後通常是 push 新畫面)；
    /// 取消 (按取消、下拉關閉、點選單外面) 不會呼叫 `onPick`。
    func presentActionPicker<Action>(title: String?, items: [ActionPickerItem<Action>], onPick: @escaping (Action) -> Void) {
        let box = ActionPickerHostBox()
        let root = ActionPickerView(
            title: title,
            items: items,
            onPick: { action in
                box.vc?.dismiss(animated: true) { onPick(action) }
            },
            onCancel: {
                box.vc?.dismiss(animated: true)
            })
        let host = UIHostingController(rootView: root)
        box.vc = host
        host.modalPresentationStyle = .pageSheet
        if let sheet = host.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(host, animated: true)
    }

    /// 按下某個 SN (原文編號) 時，跳出的選單。`sn` 例如 "G3056"，顯示在標題；取消時不呼叫 `onPick`。
    func presentSnActionPicker(sn: String?, onPick: @escaping (DText.SnAction) -> Void) {
        let items: [ActionPickerItem<DText.SnAction>] = [
            ActionPickerItem(title: NSLocalizedString("彙編", comment: ""),
                             detail: NSLocalizedString("此原文出現在哪些章節.", comment: ""),
                             systemImage: "list.bullet", action: .list),
            ActionPickerItem(title: "Parsing",
                             detail: NSLocalizedString("此章節的原文分析", comment: ""),
                             systemImage: "text.magnifyingglass", action: .parsing),
            ActionPickerItem(title: "CBOL",
                             detail: NSLocalizedString("中文線上聖經計畫 (Chinese bible on-line project) CBOL", comment: ""),
                             systemImage: "books.vertical", action: .cbol),
            // 不顯示「字典(全)」「CBOL(En)」(.dict、.cbole)
            ActionPickerItem(title: NSLocalizedString("浸宣", comment: ""),
                             detail: NSLocalizedString("浸宣出版社原文字典(無法提供離線版)", comment: ""),
                             systemImage: "book.closed", action: .twcb),
        ]
        presentActionPicker(title: sn, items: items, onPick: onPick)
    }
}
