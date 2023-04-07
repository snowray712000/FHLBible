//
//  VCAudioVersion.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/6.
//

import Foundation
class VCPlayrate : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        return String(i)
    }
    override var _ovTitle1: [String] {
        return title1data
    }
    override var _ovTitle2: [String] { return [] }
    override var _ovIsLastRedForCancel: Bool { false }
    lazy var title1data:[String] = ["2.0x", "1.5x", "1.25x", "1.0x", "0.75x", "0.5x"]
    static var speed:[Float] = [2.0,1.5,1.25,1.0,0.75,0.5]
}
