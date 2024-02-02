//
//  SSDivIdt.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon


func doDivIdt (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSDivIdt()})
}

/// ＜div class=\"idt\"＞ ... ＜/div＞
/// 於 Twcb 新約字典會常出現
fileprivate class SSDivIdt : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.length.first! == 17
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<div class=\"idt\">|</div>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.cssClass = "idt"
        re.tpContain = "div"
        return re
    }
}
