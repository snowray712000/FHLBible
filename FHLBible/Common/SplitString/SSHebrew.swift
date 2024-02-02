//
//  SSGreek.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtHebrew(_ src:[DText])->[DText]{
    return doSSDTextCore(src, {SSHebrew()})
}


fileprivate class SSHebrew : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneFromSrc: DText) -> DText {
        cloneFromSrc.w = String ( a1.w )
        cloneFromSrc.isHebrew = 1
        return cloneFromSrc
    }
    static var reg1 = try! NSRegularExpression(pattern: "[\u{0590}-\u{05fe}]+", options: [])
}

