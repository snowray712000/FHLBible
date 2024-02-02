import Foundation
import FHLCommon

/// SSDT: split string dtext
func ssDtH1H2H3H4Title (_ ds:[DText])->[DText]{
    return doSSDTextCore(ds, {SSH1H2H3H4Title()})
}
/// 若要作新的，請參照 DivIdt 、 Ref 兩大類來作
fileprivate class SSH1H2H3H4Title : SplitStringDTextBtwBase {
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.exec[1] != nil
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        let re = DText()
        re.children = dtexts
        re.tpContain = String( a1!.exec[2]! )
        re.isTitle1 = 1
        return re
    }
//    static let reg = try! NSRegularExpression(pattern: #"<(h1)>|</(h1)>"#, options: [.caseInsensitive])
    static let reg = try! NSRegularExpression(pattern: #"<(h\d+)>|</(h\d+)>"#, options: [.caseInsensitive])
}
