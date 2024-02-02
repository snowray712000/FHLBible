//
//  SSGreek.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtGreek(_ src:[DText])->[DText]{
    return doSSDTextCore(src, {SSGreek()})
}

fileprivate class SSGreek : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneFromSrc: DText) -> DText {
        cloneFromSrc.w = String ( a1.w )
        cloneFromSrc.isGreek = 1
        return cloneFromSrc
    }
    static var reg1 = try! NSRegularExpression(pattern: "[\u{0370}-\u{03ff}\u{1f00}-\u{1fff}]+", options: [])
}
