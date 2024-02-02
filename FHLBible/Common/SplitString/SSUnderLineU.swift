import Foundation
import FHLCommon

/// 若要作新的，請參照 SplitStringDivIdt 、 SSReference 兩大類來作
func ssDtUnderlineU (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSUnderLineU()})
}

/// 思高譯本，約1，底線
fileprivate class SSUnderLineU : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.length.first! == 3
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<u>|</u>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "u"
        return re
    }
}
