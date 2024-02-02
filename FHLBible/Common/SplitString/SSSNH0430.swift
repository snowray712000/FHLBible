//
//  SSSNH0430.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtSNH(_ ds:[DText])->[DText]{ doSSDTextCore(ds, {SSSNH0430()}) }

/// Cbol 字典
fileprivate class SSSNH0430 : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        let sn = String( a1.exec[1]! )
        cloneOfSrc.w = "H\(sn)"
        cloneOfSrc.sn = sn
        cloneOfSrc.tp = "H"
        return cloneOfSrc
    }
    /// | 是特殊字，就是 or
    static var reg1 = try! NSRegularExpression(pattern: #"SNH0*([\da-z]+)"#, options: [])
}
