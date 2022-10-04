//
//  Reference.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation

func ssDtGreekPlusPlusPlus(_ ds:[DText],_ ver: String? = nil )->[DText]{
    return doSSDTextCore(ds, {SSGreekPlusPlusPlus(ver)})
}

/// 顯示時用
class SSGreekPlusPlusPlus : SplitStringDTextCore {
    init(_ ver: String?){
        _ver = ver
    }
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        let reW = "(韋:\(a1.exec[1]!))(聯:\(String(a1.exec[2]!)))"
        cloneOfSrc.w = reW
        return cloneOfSrc
    }
    /// + 是特殊符號， + xxxx + xxxxx +
    static var reg1 = try! NSRegularExpression(pattern: #"\+([^\+]+)+\+([^\+]+)\+"#, options: [])
    private var _ver: String?
}

