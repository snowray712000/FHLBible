//
//  SSSNG0430.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon


func ssDtSNG(_ ds:[DText])->[DText]{ doSSDTextCore(ds, {SSSNG0430()}) }

/// 出現在 cbol 字典
fileprivate class SSSNG0430 : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        let sn = String( a1.exec[1]! )
        cloneOfSrc.w = "G\(sn)"
        cloneOfSrc.sn = sn
        cloneOfSrc.tp = "G"
        return cloneOfSrc
    }
    /// | 是特殊字，就是 or
    static var reg1 = try! NSRegularExpression(pattern: #"SNG0*([\da-z]+)"#, options: [])
}
