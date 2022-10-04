//
//  SplitByRegex.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/6/24.
//

import Foundation


open class SplitByRegexOneResult {
    internal init(_ w: Substring,_ exec: [Substring?] = [],_ index: [Int] = [],_ length: [Int] = []) {
        self.w = w
        self.exec = exec
        self.index = index
        self.length = length
    }
    public func isMatch()->Bool {return exec.count != 0}
    public var w: Substring
    /// 每個 capture 的
    public var exec: [Substring?]
    /// 對應每個 exec 的每個 range 的 pos
    /// 若length=0, index=-1(無效)
    public var index: [Int]
    /// 對應每個 exec 的每個 range 的 length
    public var length: [Int]
}
open class SplitByRegex {
    /// range 對我來說, 還是較不熟悉, 所以先轉為 substring 再接著處理
    private func doMatchAndConvertToSubstring(str: String,reg: NSRegularExpression)->[SplitByRegexOneResult]{
        let r1 = ijnMatches(reg, str)
        var tmp1: [SplitByRegexOneResult] = []
        for i1 in 0..<r1.count{
            let it1 = r1[i1]
            var re1: SplitByRegexOneResult? // 在 i2 = 0 時會 new 一個
        
            // range(at: 0) 上面處理過了
            for i2 in 0..<it1.numberOfRanges {
                let rg = it1.range(at: i2)
                
                if i2 == 0 {
                    let w = str[Range(rg, in: str)!]
                    re1 = SplitByRegexOneResult(w)
                }
                
                let s2:Substring? = rg.length == 0 ? nil : str[Range(rg,in:str)!]

                re1!.exec.append(s2)
                re1!.index.append(rg.length == 0 ? -1 : rg.location)
                re1!.length.append(rg.length)
                
            }
            tmp1.append(re1!)
        }
        return tmp1
    }
    /// 如果完全沒有 match 是回傳 nil，與 ts 的不一樣唷。
    public func main(str: String, reg: NSRegularExpression)-> [SplitByRegexOneResult]? {
        let r1 = self.doMatchAndConvertToSubstring(str: str, reg: reg)
        var data: [SplitByRegexOneResult] = []
      
        if r1.count == 0 {
            return nil
        }
        
        func addNonMatch(_ loc:Int,_ len:Int){
            let r2 = SplitByRegexOneResult(str[Range(NSRange(location: loc, length: len), in: str)!])
            data.append(r2)
        }
        
        if ( r1[0].index[0] > 0){
            let loc = 0
            let len = r1[0].index[0]
            addNonMatch(loc, len)
        }
   
        let cntMatch = r1.count
        for i in 0..<cntMatch {
            let it = r1[i];
            let len = it.length[0];
            data.append(it)
            
            // str.utf16.count 才會是用肉眼算出來的結果
            let loc = it.index[0] + len
            let len2 = i != r1.count - 1 ? r1[i+1].index[0] - loc : str.utf16.count - loc
            if (len2 != 0){
                addNonMatch(loc, len2)
            }
        }
        
      return data;
    }
}
