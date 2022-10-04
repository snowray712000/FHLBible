//
//  VCReadMore.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/16.
//

import Foundation
import UIKit

class VCSnDictMore : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        return _values[i]
    }
    override var _ovTitle1: [String] {
        return ["上一字","下一字"]
    }
    override var _ovTitle2: [String]? {
        ["小技巧: 手指向右滑","小技巧: 手指向左滑"]
    }
    private let _values = ["prev","next"]
    override var _ovImages: [UIImage?]? { [
        UIImage(systemName: "arrow.left"),
        UIImage(systemName: "arrow.right"),
    ]}
    override var _ovIsLastRedForCancel: Bool { false }
}
