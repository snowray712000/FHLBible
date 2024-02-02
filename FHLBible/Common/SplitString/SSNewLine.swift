import Foundation
import FHLCommon

/// \r?\n ... 思高譯本，有 br/
func ssDtNewLine(_ src:[DText])->[DText]{
    return doSSDTextCore(src, {SSNewLine()})
}

/// NewLine
/// \r?\n ... 高思譯本，有 br/
/// 若要作新的，請參照 DivIdt 、 Ref 兩大類來作
fileprivate class SSNewLine : SplitStringDTextCore {
    override var ovReg: NSRegularExpression { Self.reg1 }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneFromSrc: DText) -> DText {
        cloneFromSrc.w = nil
        cloneFromSrc.isBr = 1
        return cloneFromSrc
    }
    static var reg1 = try! NSRegularExpression(pattern: #"\r?\n|<br/>"#, options: [])
}
