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
        return [NSLocalizedString("上一章", comment: ""),NSLocalizedString("下一章", comment: ""),NSLocalizedString("上一頁", comment: ""),NSLocalizedString("閱讀記錄", comment: "")]
    }
    override var _ovTitle2: [String]? { [
        NSLocalizedString("小技巧: 手指向右滑", comment: ""),
        NSLocalizedString("小技巧: 手指向左滑", comment: ""),
        NSLocalizedString("小技巧: 2隻手指向右滑", comment: ""),
        NSLocalizedString("小技巧: 3隻手指向右滑", comment: ""),
    ] }
    private let _values = ["prev","next","back","history"]
    override var _ovImages: [UIImage?]? { [
        UIImage(systemName: "arrow.left"),
        UIImage(systemName: "arrow.right"),
        UIImage(systemName: "arrowshape.turn.up.left"),
        UIImage(systemName: "arrowshape.turn.up.left.2")
    ]}
    override var _ovIsLastRedForCancel: Bool { false }
}
