//
//  VCAudioVersion.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/6.
//

import Foundation
class VCAudioVersion : VCPickerBaseOnTableView<String> {
    override func getSelected(_ i: Int) -> String? {
        return String(i)
    }
    override var _ovTitle1: [String] {
        return title1data
    }
    override var _ovTitle2: [String] {
        return []
    }
    override var _ovIsLastRedForCancel: Bool { false }
    lazy var title1data:[String] = {
        let aData = "0.和合本 1.台語 2.客家話 3.廣東話 4.現代中文譯本 5.台語新約(台灣長老教會傳播中心授權) 6.紅皮聖經 7.希伯來文 8.福州話 9.希臘文 10.spring台語 11.spring和合本 12.NetBible中文版 13.全民台語聖經 14.鄒語 15.台語南部腔 17.現代台語譯本"
        let aArray = aData.components(separatedBy: " ")
        let bArray = aArray.compactMap { (item) -> String? in
            let components = item.components(separatedBy: ".")
            guard components.count == 2, let index = Int(components[0]), let name = components.last else {
                return nil
            }
            return NSLocalizedString(name, comment: "")
        }
        return bArray
    }()
}
