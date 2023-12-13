import Foundation
import UIKit

public protocol IDTextToAttributeString{
    func mainConvert(_ texts: [DText]) -> [NSMutableAttributedString]
}
public class DTextDrawToAttributeString : IDTextToAttributeString{
    init(_ isSnVisible: Bool,_ isFontNameOpenHanBibleTC:Bool?){
        _isSnVisible = isSnVisible
        _isFontNameOpenHanBibleTC = isFontNameOpenHanBibleTC
    }
    public func mainConvert(_ texts: [DText]) -> [NSMutableAttributedString] {
        var re: [NSMutableAttributedString] = []
        for a1 in texts {
            if a1.children == nil {
                re.append(cvt(a1))
            } else {
                re.append(contentsOf: cvt2(a1))
            }
        }
        return re
    }
    private var _isSnVisible: Bool! = false
    /// 為了台語字型新增
    private var _isFontNameOpenHanBibleTC: Bool?
    /// 2021 新增，若 text 是 contain 的作法
    /// 用原本的來作的，但新增 styleParent 來擴充
    private func cvt2(_ text:DText) -> [NSMutableAttributedString] {
        let r1 = DTextDrawToAttributeString(_isSnVisible,_isFontNameOpenHanBibleTC)
        r1.stParent = gParentStyle(text)
        
        // 例如 tpContain 是 ( ) 時，前後，在 add Child 時，前後要加 ( )
        let r2 = tryAddFirstLastForParent(text, text.children!)
        
        if r2 == nil {
            return r1.mainConvert(text.children!)
        } else {
            return r1.mainConvert(r2!)
        }
    }
    /// 沒變更，就回傳 nil
    fileprivate func tryAddFirstLastForParent(_ p:DText,_ ds:[DText])->[DText]?{
        if p.tpContain == "()" {
            var re: [DText] = []
            re.append(DText("("))
            re.append(contentsOf: ds)
            re.append(DText(")"))
            return re
        } else if p.tpContain == "（）" {
            var re: [DText] = []
            re.append(DText("（"))
            re.append(contentsOf: ds)
            re.append(DText("）"))
            return re
        } else if p.tpContain == "qh" {
            var re: [DText] = []
            re.append(DText("「"))
            re.append(contentsOf: ds)
            re.append(DText("」"))
            return re
        }
        return nil
    }
    fileprivate func gParentStyle(_ d:DText)->Style{
        let o = Style()
        // from super parent (先從更早的，然後下面再蓋掉)
        if stParent != nil {
            o.fontStyle = stParent?.fontStyle
            o.textColor = stParent?.textColor
            o.isUnderline = stParent?.isUnderline
            o.isUnderlineDot = stParent?.isUnderlineDot
            o.isItaly = stParent?.isItaly
        }
        
        if d.tpContain == "()" ||  d.tpContain == "（）"{
            o.textColor = .systemPurple // Twcb
        } else if (d.tpContain == "span" && d.cssClass == "exp" ){
            o.textColor = .systemRed // Twcb
        } else if (d.tpContain == "span" && d.cssClass == "bibtext" ){
            o.textColor = .systemOrange // Twcb old
        } else if (d.tpContain == "span" && d.cssClass == "godsay" ){
            o.textColor = .systemRed // csb 中文標準譯本, 耶穌說的話
        } else if (d.tpContain == "div" && d.cssClass == "idt") {
            // o.textColor = .darkgoldenrod // twcb
        } else if (d.tpContain == "u" ) {
            o.isUnderline = true
        } else if (d.isTitle1 == 1){
            o.fontStyle = .title1
        } else if (d.tpContain == "b" ){
            o.fontStyle = .headline
        } else if (d.tpContain == "qh") {
            o.textColor = .systemRed
        } else if (d.tpContain == "kjvrf") {
            o.textColor = .systemPurple
        } else if (d.tpContain == "kjvfi"){
            o.isItaly = true 
        } else if (d.tpContain == "kjvfo"){
            o.fontStyle = .title1
        } else if (d.tpContain == "esvtitle"){
            o.fontStyle = .title1
        }
        
        
        
        return o
    }
    /// children 實作時，新增的變數
    fileprivate var stParent: Style?
    // 原本的，但沒考慮到 DText 後來多了 children 格式
    /// children 在 cvt2
    private func cvt(_ text: DText) -> NSMutableAttributedString {
        
        let st = Style()
        
        // 台語特殊字型
        if _isFontNameOpenHanBibleTC == true {
            st.isFontNameOpenHanBibleTC = true
        }
        
        // font size
        if text.isTitle1 == 1 {
            st.fontStyle = .title1
        } else if text.isGreek == 1 {
            st.fontStyle = .title1 
        } else if text.isHebrew == 1 {
            st.fontStyle = .title1
        } else if stParent != nil && stParent!.fontStyle != nil {
            // parent 要放最後
            st.fontStyle = stParent!.fontStyle
        }
        
        // under line
        if stParent != nil && stParent!.isUnderline != nil {
            st.isUnderline = stParent!.isUnderline
        }
        if text.isName == 1 {
            st.isUnderline = true
        }
        if text.isOrigNotExist == 1 {
            st.isUnderlineDot = true
        }
        
        // italy
        if stParent != nil && stParent!.isItaly == true {
            st.isItaly = stParent!.isItaly
        }
        

        
        // color
        if text.keyIdx0based != nil {
            st.textColor = UIColor.ijnKeywords[ text.keyIdx0based! % 7 ]
        } else if text.isRef == 1 || text.isSnActived == 1 || DFoot.isBlueColor(text.foot) {
            // st.textColor = .blue
            st.textColor = .systemBlue
        } else if (text.isTitle1 == 1 && text.isRef != 1) {
            st.textColor = .systemPurple
            //st.textColor = .darkmagenta
        } else if text.sn != nil {
            st.textColor = .systemTeal
            //st.textColor = .darkturquoise
        } else if text.isParenthesesHW == 1 || text.isParenthesesFW == 1 || DFoot.isPurpleColor(text.foot) {
            st.textColor = .systemPurple
            //st.textColor = .purple
        } else if text.isParenthesesFW2 == 1 {
            st.textColor = .systemPurple
            //st.textColor = .magenta
        } else if text.isGODSay == 1 {
            st.textColor = .systemRed
            //st.textColor = .red
        } else if stParent != nil && stParent!.textColor != nil {
            // parent 一定要放在最後
            st.textColor = stParent!.textColor!
        }
        
        let w = text.isBr == 1 ? "\r\n" : text.w
        
        if text.isHebrew == 1{
            let r = gHebrewAttributeSmall()
            r.append(gStyle(w, st))
            return r
        }
        if _isSnVisible == false && text.sn != nil { // sn 開關
            return NSMutableAttributedString(string: "")
        }
        
        return gStyle(w, st)
    }
    /// 希伯來文夾雜，會使整個文件亂掉，所以加個非希伯來文來斷開（試過其他符號，無法有效果）
    /// 因此，它字要小，然後顏色能看不見，就看不見　（但被複製時會被發現就是了）
    private func gHebrewAttributeSmall() -> NSMutableAttributedString {
        let st = Style()
        st.fontStyle = .caption2 // 最小的了
        st.textColor = UIColor.init(white: 0.5, alpha: 0.0)
        
        return NSMutableAttributedString(string: "H:", attributes:  [NSAttributedString.Key.foregroundColor : st.getColor() , NSAttributedString.Key.font :  st.getFont() , NSAttributedString.Key.underlineStyle : st.getUnderline()
        ] )
    }
    private func gStyle(_ str: String?,_ st: Style) -> NSMutableAttributedString {
        
        let attrs = EasyStringAttributes() // 使用此重構

        attrs.fontColor = st.getColor()
        
        // 不能不設 .font 會爆掉，所以預設給 .body
        let easyfont = EasyUIFont(fontRefernce: st.getFont())
        attrs.fontEasy = easyfont
        
        // 底線 or 虛點點 嗎?
        if st.isUnderline == true {
            attrs.underLineOrDot = .single
        } else if st.isUnderlineDot == true {
            attrs.underLineOrDot = .patternDot
        }
        
        // 斜體嗎?
        attrs.isItaly = st.isItaly
        
        return NSMutableAttributedString(string: str ?? "", attributes:  attrs.resultAttributes)
    }
    
    class Style {
        public init(){}
        public var textColor : UIColor?
        public var fontStyle : UIFont.TextStyle?
        public var isUnderline : Bool?
        public var isUnderlineDot : Bool?
        var isItaly: Bool?
        /// 台語 OpenHanBibleTC
        var isFontNameOpenHanBibleTC: Bool?
        
        public func getFont() -> UIFont {
            
            if isFontNameOpenHanBibleTC == true {
                let re = EasyUIFont() // 使用此重構
                re.setNameForSupportHanText(fontStyle: fontStyle ?? .body)
                return re.font
            } else {
                let re = EasyUIFont(fontStyle: fontStyle ?? .body)
                return re.font
            }
        }
        public func getUnderline() -> Int {
            if isUnderlineDot == true { return (NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue) }
            if isUnderline == true { return NSUnderlineStyle.single.rawValue }
            return 0
        }
        public func getColor () -> UIColor {
            return textColor ?? .label
        }
        
    }
}
