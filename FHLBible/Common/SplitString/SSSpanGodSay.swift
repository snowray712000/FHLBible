//
//  SSSpanBibtext.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation

func ssDtSpanGodSayCsb (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSSpanGodSayCsb()})
}

/// span.bibtext, 出現在 twcb 的字典中
fileprivate class SSSpanGodSayCsb : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.length.first! != 7
    }
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    static var reg = try! NSRegularExpression(pattern: #"<span style=\"color:rgb\(195,39,43\);\">|</span>"#, options: [])
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        // 顏色是紅，與 span.bibtext 一樣，先設那樣
        let r1 = DText ()
        r1.children = dtexts
        r1.tpContain = "span"
        r1.cssClass = "godsay"
        return r1
    }
}
