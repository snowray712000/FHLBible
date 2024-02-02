//
//  SSSpanExp.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtSpanExp (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSSpanExp()})
}

/// span.exp 出現在 twcb 的字典中
fileprivate class SSSpanExp : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.length.first! != 7
    }
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    static var reg = try! NSRegularExpression(pattern: #"<span class=\"exp\">|</span>"#, options: [])
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let r1 = DText ()
        r1.children = dtexts
        r1.tpContain = "span"
        r1.cssClass = "exp"
        return r1
    }
}
