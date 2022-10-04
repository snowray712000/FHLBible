import UIKit
import Combine

/// 從 Basic01 學到的
/// 基本: 簡化傳入 Regex 的 String
/// 後來在 SplitByRegex 也有用到
public func ijnMatches(_ reg: NSRegularExpression,_ str: String)->[NSTextCheckingResult]{
    let r1 = reg.matches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
    return r1
    
    // bug, 把 str.count 改為 str.utf16.count 有些才會正確
    //return reg.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
    
    // 之前用的方法，還不知道 withTransparentBounds 用的
    // return reg.matches(in: str, options: [.withTransparentBounds], range: NSRange(str.startIndex..<str.endIndex, in: str))
}
public func ijnMatchFirst(_ reg: NSRegularExpression,_ str:String)->NSTextCheckingResult?{
    return reg.firstMatch(in: str, options: [], range: NSRange(str.startIndex..<str.endIndex, in: str))
}
public func ijnMatchFirstAndToSubString(_ reg: NSRegularExpression,_ str:String)->[Substring?]?{
    let r1 = ijnMatchFirst(reg,str)
    if r1 == nil { return nil }
    
    func gStr(_ rg: NSRange,_ str: String)-> Substring? {
        if rg.length == 0 {
            return nil
        }
        return str[Range(rg, in: str)!]
    }
    
    let r2 = (0..<r1!.numberOfRanges).map({gStr(r1!.range(at: $0), str)})
    return r2
}
/// 用 ijnMatches 回傳 count != 0 判斷
public func ijnIsMatch(_ reg: NSRegularExpression,_ str: String)->Bool{
    return ijnMatches(reg,str).count != 0
}
/// 從  Basic03 學到的
/// 基本: 簡化呼叫 replaceMatches 的參數
public func ijnReplaceString(_ reg: NSRegularExpression,_ str:String,_ strReplaced:String ) ->String {
    let r1 : NSMutableString = NSMutableString(string: str)
    let r2 = r1 as String
    reg.replaceMatches(in: r1, options: [], range: NSRange(r2.startIndex..<r2.endIndex, in: r2), withTemplate: strReplaced)
    return r1 as String
}
/// 若 ReplaceString 要用 callback 的方式，那麼還要另外寫繼承 class
/// 寫一個工具，只要指定 callback 函式 (並且用最直覺的，傳入 capture 的 string作判斷要用什麼取代)
/// 測試成功
/// 使用方法:
/// 宣告個物件, 使用 setCallbackForReplacement
/// 使用 replacing 產生新字串
open class IjnRegex : NSRegularExpression {
    public typealias FnCallback = (_ captures:[Substring])-> String
    var fnReplacement : FnCallback?
    open func setCallbackForReplacement(_ fn: @escaping FnCallback){
        self.fnReplacement = fn
    }
    /// 產生一個取代後的字串
    open func replacing(_ str:String)->String{
        return ijnReplaceString(self, str, "")
    }
    
    open override func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        guard let fn = self.fnReplacement else { return super.replacementString(for: result, in: string, offset: offset, template: templ) }
        
        let strs = (0..<result.numberOfRanges).map({string[Range(result.range(at: $0), in: string)!]})
        return fn(strs)
    }
}

public func ijnSubString(_ str:String,len: Int)->Substring{
    // str[..<3] ... 即 (str,3)
    let idx1 = str.index(str.startIndex, offsetBy: len)
    return str[..<idx1]
}
public func ijnSubString(_ str:String,pos: Int)->Substring{
    // str[3...] ...
    let idx1 = str.index(str.startIndex, offsetBy: pos)
    return str[idx1...]
}
/// stride 內建函式，有 to 與 through，to是 <，through是 <=
public func ijnSubString(_ str:String,pos:Int,to:Int)->Substring{
    // str[pos..<to]
    let idx1 = str.index(str.startIndex, offsetBy: pos)
    let idx2 = str.index(str.startIndex, offsetBy: to)
    return str[idx1..<idx2]
}
