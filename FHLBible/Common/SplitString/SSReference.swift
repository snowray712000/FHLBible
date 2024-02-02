//
//  Reference.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon

func ssDtReference(_ ds:[DText],_ ver: String? = nil )->[DText]{
    return doSSDTextCore(ds, {SSReference(ver)})
}

/// splite string reference
/// # xxxxxx |
class SSReference : SplitStringDTextCore {
    init(_ ver: String?){
        _ver = ver
    }
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        cloneOfSrc.w = String(a1.w)
        if ["tcv2019"].contains(_ver) {
            // 特例 現代中文譯本，長這樣 #路 3．23-38|
            let r1 =  String( a1.exec[1]! )
            cloneOfSrc.refDescription = ijnReplaceString(Self.regTcv, r1, ":")
        } else {
            cloneOfSrc.refDescription = String( a1.exec[1]! )
        }
        return cloneOfSrc
    }
    /// | 是特殊字，就是 or
    static var reg1 = try! NSRegularExpression(pattern: #"#([^\|]+)\|"#, options: [])
    static var regTcv = try! NSRegularExpression(pattern: #"．"#, options: [])
    
    private var _ver: String?
}

