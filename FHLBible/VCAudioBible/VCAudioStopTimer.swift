//
//  VCAudioVersion.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/6.
//

import Foundation
// dialog of 語音聖經倒數計數(睡覺用)
class VCAudioStopTimer : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        if i < titleInMin.count {
            return titleInMin[i]
        }
        return "0"
    }
    override var _ovTitle1: [String] {
        return title1data
    }
    override var _ovTitle2: [String] {
        return []
    }
    override var _ovIsLastRedForCancel: Bool { false }
    lazy var title1data:[String] = ["--","30","60","1:30","2:00","3:00","4:00","6:00","8:00"]
    lazy var titleInMin:[String] = ["0","30","60","90","120","180","240","360","480"]
}

