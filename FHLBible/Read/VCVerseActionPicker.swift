//
//  VCVerseActionPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit
import FHLCommon

public enum VerseAction {
    case InfoParsing // 原文分析
    case InfoComment // 註釋
    case InfoTsk //串珠
    case VersionsCompare // 譯本比較
}

extension UIViewController {
    /// 點到經文位置時，跳出的選單 (畫面與 SN 選單共用 `ActionPickerView`)。`title` 例如 "創 1:1"；取消時不呼叫 `onPick`。
    func presentVerseActionPicker(title: String?, onPick: @escaping (VerseAction) -> Void) {
        let items: [ActionPickerItem<VerseAction>] = [
            ActionPickerItem(title: NSLocalizedString("譯本比較", comment: ""),
                             detail: NSLocalizedString("此節，比較多個譯本", comment: ""),
                             systemImage: "rectangle.split.2x1", action: .VersionsCompare),
            ActionPickerItem(title: "Parsing",
                             detail: NSLocalizedString("原文分析工具；時態、單複數、陽性、陰性等原文分析", comment: ""),
                             systemImage: "text.magnifyingglass", action: .InfoParsing),
            ActionPickerItem(title: NSLocalizedString("註釋", comment: ""),
                             detail: NSLocalizedString("查經班查經後資料整理，完整可見 https://a2z.fhl.net/bible/，或 google 'a2z fhl' 即可。", comment: ""),
                             systemImage: "text.bubble", action: .InfoComment),
            ActionPickerItem(title: NSLocalizedString("串珠", comment: ""),
                             detail: NSLocalizedString("串珠聖經工具。每一節經文旁，標注相關經文，它也是一種註釋，不是聖經本身", comment: ""),
                             systemImage: "link", action: .InfoTsk),
        ]
        presentActionPicker(title: title, items: items, onPick: onPick)
    }
}
