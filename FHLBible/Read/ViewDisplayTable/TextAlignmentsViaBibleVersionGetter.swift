//
//  TextAlignmentsViaBibleVersionGetter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/25.
//

import Foundation
import UIKit


/**
 產生傳給 table 中的 cell 的對齊。不同的譯本，會傳合適的對齊，例如，希伯來文要靠右對齊。
 - 舊約原文，要靠右對齊
 - 英文字類的，要靠左對齊 (左右對齊不好看)
 - 其它，左右對齊
 - Returns: 回傳個數，譯本若3個，就是回傳3個。雖然 1 row 通常會有 4 個 cell。 
 */
func getTpTextAlignmentsViaBibleVersions(_ vers:[String])->[NSTextAlignment] {
    return GetTpTextAlignmentsViaBibleVersions().main(vers)
    
}

fileprivate class GetTpTextAlignmentsViaBibleVersions : NSObject {
    func main(_ vers:[String])->[NSTextAlignment]{
        return vers.map({ a1 in
            if Self._right.contains(a1) {
                return .right
            }
            if Self._left.contains(a1) {
                return .left
            }
            return .justified
        })
    }
    static var _right: Set<String> = {
        return ["bhs"].ijnToSet()
    }()
    static var _left: Set<String> = {
        return ["kjv","darby","bbe","erv","asv","web","esv","fhlwh","lxx","russian","vietnamese","tte","apskcl","bklcl","prebklcl","sgebklcl","thv2e","hakka","rukai","tsou","ams", "amis2","ttnt94","sed",
                "tru"].ijnToSet()
        /// fhlwh 新約原文 lxx 七十士譯本 russian 俄文 vietnamese 越南
        /// 台語羅馬字 tte apskcl bklcl prebklcl sgebklcl thv2e hakka
        /// 原住民 rukai tsou ams amis2 ttnt94 sed tru
    }()
}
