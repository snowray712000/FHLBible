import Foundation

/// 處理括號 全型 半型都會處理
/// SSDT: split string dtext
func ssDtParentheses (_ ds:[DText])->[DText]{
    let r1 = doSSDTextCore(ds, {SSParentHW()})
    return doSSDTextCore(r1, {SSParentFW()})
}

/// ( ) 處理 括號
/// 若要作新的，請參照 DivIdt 、 Ref 兩大類來作
fileprivate class SSParentHW : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "("
    }
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let r1 = DText()
        r1.children = dtexts
        r1.tpContain = "()"
        return r1
    }
    static var reg = try! NSRegularExpression(pattern: #"\(|\)"#, options: [])
}
class SSParentFW : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "（"
    }
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let r1 = DText()
        r1.children = dtexts
        r1.tpContain = "（）"
        return r1
    }
    static var reg = try! NSRegularExpression(pattern: #"（|）"#, options: [])
}
