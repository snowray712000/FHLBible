//
//  SplitStringDTextCore.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/12.
//

import Foundation

/// 若沒有任何改變，就回傳 nil
/// 不能處理 (w是空的)，所以使用此，不用再加 w? 判斷
/// 參考 SSRef class
protocol ISSDText {
    func main(_ src: DText) -> [DText]?
}

/// 為了 繼承 SplitStringDTextCore 這些的而存在
func doSSDTextCore(_ ds:[DText],_  ss: ()->ISSDText)->[DText]{
    var re: [DText] = []
    for a1 in ds {
        if a1.children != nil {
            let tmp2 = doSSDTextCore (a1.children!, ss) // DText[]
            
            let tmp = a1.clone()
            tmp.children = tmp2
            re.append(tmp)
        } else {
            let r2 = ss().main(a1)
            if r2 == nil {
                re.append(a1.clone())
            } else {
                re.append(contentsOf: r2!)
            }
        }
    }
    return re
}

/// 因為3個長很像，所以抽出來.
/// SS: Split String .
/// 過載 reg 時，可結合 static 變數來回傳.
/// 過載 generateDText.
/// 夾擊型的，可使用 SplitStringDTextBtwBase
class SplitStringDTextCore : ISSDText {
    /// 傳參數 str ，但這樣不好，若這個原本有 dtext 其它屬性，就沒　copy　到，被遺失了
    /// 回傳參數　nil 表示沒有　match 到
    func main(_ src: DText) -> [DText]? {
        self.src = src
        if src.isCantSplit() { return nil }
        
        let reg = self.ovReg
        let r1 = SplitByRegex().main(str: src.w!, reg: reg)
        
        if r1 == nil { return nil }
        
        var re: [DText] = []
        for a1 in r1! {
            if a1.isMatch() == false {
                let r2 = src.clone()
                r2.w = String( a1.w )
                re.append(r2)
            } else {
                let r2 = ovGenerateDText(a1, src.clone())
                re.append(r2)
            }
        }
        
        
        return re
    }
    /// override this, can return static variable
    internal var ovReg: NSRegularExpression { try! NSRegularExpression(pattern: #"\r?\n"#, options: []) }
    /// override this
    /// set cloneFromSrc and return it.
    internal func ovGenerateDText(_ a1: SplitByRegexOneResult,_ cloneFromSrc:DText)->DText{
        cloneFromSrc.w = nil
        cloneFromSrc.isBr = 1
        return cloneFromSrc
    }
    internal var src: DText!
}
