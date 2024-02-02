import Foundation
import FHLCommon


/// 若要作新的，請參照 SSDivIdt 、 SSReference 兩大類來作
func ssDtSSBoldB (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSBoldB()})
}

/// 思高譯本，約1，底線
fileprivate class SSBoldB : SplitStringDTextBtwBase {
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.length.first! == 3
    }
    override func ovGRegexp() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: #"<b>|</b>"#, options: [])
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = "b"
        return re
    }
}
