//
//  VCReadMore.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/16.
//

import Foundation
import UIKit

class VCReadMore : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        return _values[i]
    }
    override var _ovTitle1: [String] {
        return [NSLocalizedString("上一章", comment: ""),
                NSLocalizedString("下一章", comment: ""),
                NSLocalizedString("上一頁", comment: ""),
                NSLocalizedString("閱讀記錄", comment: ""),
                NSLocalizedString("有聲聖經", comment: ""),
                NSLocalizedString("有聲文字", comment: ""),
                NSLocalizedString("版本比較 註釋 Parsing 串珠", comment: ""),
                NSLocalizedString("Parsing 原文字典", comment: "")
                
        ]
    }
    override var _ovTitle2: [String]? { [
        NSLocalizedString("小技巧: 手指向右滑", comment: ""),
        NSLocalizedString("小技巧: 手指向左滑", comment: ""),
        NSLocalizedString("小技巧: 2隻手指向右滑", comment: ""),
        NSLocalizedString("小技巧: 3隻手指向右滑", comment: ""),
        NSLocalizedString("", comment: ""),
        NSLocalizedString("", comment: ""),
        NSLocalizedString("說明: 點擊藍色字眼，例如 '太1:1'。因為其它功能是不是以一章為單位，而是節為單位。", comment: ""),
        NSLocalizedString("說明: 點擊 SN 字眼，例如 '<G3767>'。", comment: ""),
    ] }
    private let _values = ["prev","next","back","history","audiobible","audiobibletext","hint1","hint2"]
    override var _ovImages: [UIImage?]? { [
        UIImage(systemName: "arrow.left"),
        UIImage(systemName: "arrow.right"),
        UIImage(systemName: "arrowshape.turn.up.left"),
        UIImage(systemName: "arrowshape.turn.up.left.2"),
        UIImage(systemName: "speaker.3.fill"),
        UIImage(systemName: "speaker.3.fill"),
        UIImage(systemName: "questionmark"),
        UIImage(systemName: "questionmark"),
    ]}
    override var _ovIsLastRedForCancel: Bool { false }
}
