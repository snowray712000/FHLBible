//
//  SplitStringDTextBase.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/12.
//
/// <div></div> 或 ( ) 成對出現時可用
/// 開發過程，可看 DevUname02 這個 class
import Foundation


/// 過載 isFront gRegexp gDTextContain
/// ＜div＞＜/div＞ 或 ( ) 成對出現時可用
/// 開發過程，可看 DevUname02 這個 class
/// 另外較簡單的，不是夾擊型的，有 SplitStringDTextCore 可用
/// 剛好也符合 : ISSDText，原本沒有設計沒這個的，單純只是為了這種 case 處理起來很煩
/// 但加上 ISSDText 就可以用 func ，外部在處理 [DText] 就好處理多了
class SplitStringDTextBtwBase : ISSDText{    
    func main(_ str:DText)->[DText]?{
        if str.isCantSplit() { return nil }
        
        self.reg = ovGRegexp()
        let r1 = SplitByRegex().main(str: str.w!, reg: reg)
        if r1 == nil { return nil }
        
        step2_EachPart(r1!)
        
        makeSureContainOnlyOne()
        return container[0]
    }
    // override
    func ovIsFront(_ a1: SplitByRegexOneResult)->Bool{
        return a1.length.first! == 5
    }
    // override
    func ovGRegexp()->NSRegularExpression{
        return try! NSRegularExpression(pattern: #"<div>|</div>"#, options: [])
    }
    /// override, 當一個 </div> 來到時, 它會結算一個 array
    /// 此時，你要產生 Dtext，首先，將傳來的參數，設為  children
    /// 其次，你設定它的其它參數
    func ovGDTextContain(_ dtexts:[DText],_ a1:SplitByRegexOneResult?)->DText{
        let r = DText()
        r.children = dtexts
        r.tpContain = "div"
        r.cssClass = "idt"
        return r
    }
    fileprivate func step2_EachPart(_ reReg: [SplitByRegexOneResult]) {
        for a1 in reReg {
            if false == a1.isMatch() {
                pushToLastContain(gD(a1.w))
            } else {
                if ovIsFront(a1) {
                    pushConAndAddDp()
                } else {
                    popLastCon(a1)
                }
            }
        }
    }
    private var dp = 0
    /// 第1個就是最底層
    private var container: [[DText]] = [[]]
    private func pushToLastContain(_ d:DText){
        container[container.endIndex-1].append(d)
    }
    private func pushConAndAddDp(){
        container.append([])
        dp = dp + 1
    }
    /// a1 通常沒用到，表示結尾的 </div>
    /// 也有可能是 nil, 例如, 沒有成對的 case </div>
    private func popLastCon(_ a1: SplitByRegexOneResult?){
        if dp > 0 {
            let r1 = container.popLast()
            let r2 = ovGDTextContain(r1!, a1)
            pushToLastContain(r2)
            dp = dp - 1
        }
    }
    /// 若 div /div 沒成對，也就是 /div 少了, 最終的時候, 要把它 push 乾淨
    private func makeSureContainOnlyOne(){
        while dp > 0 {
            popLastCon(nil)
        }
    }
    private func gD(_ s:Substring)->DText{ DText(String(s)) }
    private var reg: NSRegularExpression!
                            
}


