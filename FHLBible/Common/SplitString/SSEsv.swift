//
//  SSDivIdt.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtEsvSubtitle (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSEsvTitle()})
}

fileprivate class SSEsvTitle : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w.count == 12
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<subheading>|</subheading>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "esvtitle"
        return re
    }
}
