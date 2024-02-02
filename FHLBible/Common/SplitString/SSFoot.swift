//
//  Reference.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/19.
//

import Foundation
import FHLCommon


/// csb: 中文標準譯本 cnet: NET聖經中譯本
/// 內容需要目前經文位置，在查詢內容時需要
func ssDtFoot(_ ds:[DText],_ addr: DAddress,_ ver: String? = nil)->[DText]{
    return doSSDTextCore(ds, {SSFoot(addr,ver!)})
}

/// csb: 中文標準譯本 cnet: NET聖經中譯本
/// # xxxxxx |
fileprivate class SSFoot: SplitStringDTextCore {
    init(_ addr:DAddress,_ ver:String){
        self._addr = addr
        self._ver = ver
    }
    override var ovReg: NSRegularExpression { Self.reg }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        cloneOfSrc.w = String(a1.w)
        
        let id = Int( a1.exec[1]! )
        let r1 = DFoot(text: cloneOfSrc.w, book: _addr.book, chap: _addr.chap, verse: _addr.verse, version: _ver, id: id)
        cloneOfSrc.foot = r1
        return cloneOfSrc
    }
    /// | 是特殊字，就是 or
    static var reg = try! NSRegularExpression(pattern: #"【(\d+)】"#, options: [])
    
    var _addr: DAddress!
    var _ver: String!
}

