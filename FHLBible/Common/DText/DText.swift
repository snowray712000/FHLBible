//
//  DText.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/22.
//

import Foundation




public enum BookNameLang {
    case 太
    case 太GB
    case Mt
    case Matthew
    case Matt
    case 马太福音GB
    case 馬太福音
}


open class BibleBookNames {
    public static func getBookName(_ id:Int,_ tp: BookNameLang) -> String {
        return BookNameConstants.getNameArrayViaLanguageType(tp)[id-1];
    }
    public static func getBookNames(_ tp:BookNameLang) -> [String] {
        return BookNameConstants.getNameArrayViaLanguageType(tp)
    }
}
class BibleBookNameToId {
    /// 若沒有找到，回傳 -1
    /// 已經優化過效率，是用 dictionary，並且作為 static 了。
    func main1based(_ tp: BookNameLang,_ str: String)-> Int {
        var r1 = Self.dicts[tp]
        if r1 == nil {
            r1 = generateOneDict(tp)
            Self.dicts[tp] = r1!
        }
        
        let r2 = r1![str]
        return r2 != nil ? r2! : -1
        
        //let r1 =  BibleBookNames.getBookNames(tp)
        //let r2 = r1.ijnIndexOf(str)
        //return r2 != nil ? r2! + 1 : -1
    }
    /// na : bookId
    typealias OneDict = [String:Int]
    static var dicts: [BookNameLang : OneDict ] = [:]
    
    func generateOneDict(_ tp:BookNameLang)->OneDict{
        let r2 = BibleBookNames.getBookNames(tp)
        var re: OneDict = [:]
        for (i,a2) in r2.enumerated() {
            re[a2] = i + 1 // 1-based
        }
        return re
    }
}

public class DOneLine : Equatable {
    public init(addresses: String? = nil, children: [DText]? = nil, ver: String? = nil) {
        self.addresses = addresses
        self.children = children
        self.ver = ver
    }
    
    /// 為了 unit test 增加的 XCTAssertEqual QsbRecords2DOneLinesTests
    /// 若其中一個 ver 是 nil, ver 則忽略
    /// 若其中一個 addresses 是 nil, addresses 則忽略
    public static func == (lhs: DOneLine, rhs: DOneLine) -> Bool {
        if lhs.ver != nil && rhs.ver != nil && lhs.ver != rhs.ver {
            return false
        }
        if lhs.addresses != nil && rhs.addresses != nil && lhs.addresses != rhs.addresses {
            return false
        }
        if lhs.children == nil && rhs.children == nil {
            return true
        }
        if lhs.children == nil { // 只有一個 children 是 nil
            return false
        }
        if rhs.children == nil {
            return false
        }
        return lhs.children! == rhs.children!
    }
    /// 效率考量，set 時，不會去同時設 2 版本
    /// get 以 addresses 為主，若沒有，才會從 2 版本嘗試取得。
    public var addresses : String? {
        set {
            _addresses = newValue
        }
        get {
            if _addresses == nil && (_address2 != nil || _addresses2 != nil) {
                if _addresses2 != nil {
                    return VerseRangeToString().main(_addresses2!, .Matt)
                }
                if _address2 != nil {
                    let cht = BibleBookNames.getBookName(_address2!.book, ManagerLangSet.s.curTpBookNameLang)
                    return "\(cht)\(_address2!.chap):\(_address2!.verse)"
                }
            }
            
            return _addresses
        }
    }
    public var children : [DText]?
    public var ver : String?
    
    /// set 時，只會設 2 版本的
    /// get 時，先以 2 版本的為主，若沒有，會嘗試從 1 版本的取得
    var address2: DAddress? {
        set {
            _address2 = newValue
        }
        get {
            if _address2 != nil {
                return _address2
            }
            if _addresses2 != nil && _addresses2!.count != 0{
                return _addresses2!.first!
            }
            if _addresses != nil {
                let r1 = StringToVerseRange().main(_addresses!)
                if r1.count != 0 {
                    return r1.first!
                }
            }
            
            return _address2
        }
    }
    /// set 時，只會設 2 版本的
    /// get 時，先以 2 版本的為主，若沒有，會嘗試從 1 版本的取得
    var addresses2: [DAddress]? {
        set {
            _addresses2 = newValue
        }
        get {
            if _addresses2 != nil {
                return _addresses2!
            }
            if _address2 != nil {
                return [_address2!]
            }
            if _addresses != nil {
                let r1 = StringToVerseRange().main(_addresses!)
                if r1.count != 0 {
                    return r1
                }
            }
            
            return _addresses2
        }
    }
    
    /// 保持原本的
    private var _addresses: String?
    /// 若來源是這個, 會較有效率, 有時候
    private var _address2: DAddress?
    /// 若來源是這個, 會較有效率, 有時候
    private var _addresses2: [DAddress]?
    
}

/// 參考 NUIRWD https://github.com/snowray712000/NUIRWD/blob/bible-text-show/src/app/bible-text-convertor/AddBase.ts
public class DText : NSObject {
    public var w : String?
    /// 不含 H 或 G, 且數字若有零會去頭
    public var sn : String?
    /// H, Hebrew G, Greek //'H' | 'G';
    public var tp : String?
    /// T, time 時態  'WG' | 'WTG' | 'WAG' | 'WTH' | 'WH';
    public var tp2 : String?
    /// 是否等於目前 active sn 0|1
    public var isSnActived: Int?
    /// 花括號，大括號   1 | 0;
    public var isCurly: Int?
    /// 此節是 'a', 且無法與上節合併時, 會顯示 '併入上節' 並且加上 isMerge=1, 若已與上節合併, 會修正上節的 verses, 並將此節 remove 掉 1
    public var isMerge: Int?
    /// 和合本 小括號(全型 FullWidth), 用在注解(或譯....), 或是標題時(大衛的詩)  1
    public var isParenthesesFW: Int?
    /// 和合本 小括號(半型 HalfWidth), cbol時 1
    public var isParenthesesHW: Int?

    /// 和合本 小括號(全型), 連續2層括號, 內層 新譯本 詩3:1 1
    public var isParenthesesFW2: Int?
    /// sobj 的資料, 地圖與相片
    public var sobj: Any?
    public var isMap: Bool?
    public var isPhoto: Bool?
      
    /// 新譯本是 h3；和合本2010 h2 1
    public var isTitle1: Int?
    /// 交互參照 1
    //public var isRef: Int?
    public var isRef: Int? { refDescription != nil ? 1 : nil }
    /// 交互參照內容 */
    public var refDescription: String?
    /// 換行, 新譯本 h3 與 非h3 交接觸 1*/
    public var isBr: Int?
    /// hr/, 原文字典，不同本用這個隔開. 1*/
    public var isHr: Int?
    /// 搜尋時，找到的keyword，例如「摩西」 */
    public var key: String?
    /// 搜尋時，找到的keyword，例如「摩西 亞倫」, 摩西, 0, 這可能是上色要用到 */
    public var keyIdx0based: Int?
    public var listTp: ListTp?;
    /// 1是第一層, 0就是純文字了 */
    public var listLevel: Int?
    /// 當時分析的層數 */
    public var listIdx: [Int]?
    /// 若出現這個, html 就要加 <li>  0 | 1; */
    public var isListStart: Int?
    /// 若出現這個, html 就要加 </li>  0 | 1; */
    public var isListEnd: Int?
    /// 若出現這個, html 就要加 </ol> 或 </ul>  0 | 1; */
    public var isOrderStart: Int?
    /// 若出現這個, html 就要加 </ol> 或 </ul>  0 | 1; */
    public var isOrderEnd: Int?

    /// idxOrder, 有這個 html 繪圖可以更加漂亮, 交錯深度之類的 */
    public var idxOrder: Int?

    /// twcb orig dict 出現的, 它原本就是 html 格式, 若巢狀, 愈前面的 class 愈裡層 */
    public var cssClass: String?

    /**
     rt.php?engs=Gen&chap=4&version=cnet&id=182 真的缺一參數不可,試過只有id不行
     和合本 2010 版, 是只有 text ([4.1]「該隱」意思是「得」。)
     csb: 中文標準譯本 cnet: NET聖經中譯本
     */
    public var foot: DFoot?
      // 私名號。底線  0 | 1;
    public var isName: Int?
      // 粗體。和合本2010、<b></b>  0 | 1;
    public var isBold: Int?
      // 紅字。耶穌說的話，會被標紅色。有些版本這麼作。 0 | 1;
    public var isGODSay: Int?
      // 虛點點。和合本，原文不存在，為了句子通順加上的翻譯。 0 | 1;
    public var isOrigNotExist: Int?
      // rgb(195,39,43) 中文標準譯本 csb ， 紅字，是用 span style css color rgb(x,x,x)
    public var cssColor: String?
    
    public enum ListTp : String{
        case ol = "ol"
        case ul = "ul"
    }
    /// title, FW, order list, 都可能用, 與 tpContain 使用
    public var children : [DText]?
    /// 配合 children 的，容器當初的 tp 是什麼，是 h1 還是 h2 還是 h3，又或著是 ) 還是 全型 )，又或著是 Fi 之類的
    public var tpContain : String?
    /// 點擊 Sn 後，可能是用 彙編，可能是用 字典功能
    public var snAction: SnAction?
    public enum SnAction : String {
        case list = "list"
        case parsing = "parsing"
        case cbol = "cbol"
        case cbole = "cbole"
        case twcb = "twcb"
        case dict = "dict"
    }
    /// 顯示上可用，若是 hebrew 可用較大的字型大小，之類的
    /// try! NSRegularExpression(pattern: "[\u{0590}-\u{05fe}]+", options: [])
    public var isHebrew: Int?
    /// try! NSRegularExpression(pattern: "[\u{0370}-\u{03ff}\u1f00-\u1fff]+", options: [])
    public var isGreek: Int?
}
/// 用於 DText 中的 Foot
/// { w: '【180】', foot: { book:1, chap: 4, version: 'cnet', id: 180 } } NET聖經中譯本
/// { w: '([4.1]「該隱」意思是「得」。)', foot: { text: '「該隱」意思是「得」。' } } 和合本2010
public class DFoot : NSObject {
    public init(text: String? = nil, book: Int? = nil, chap: Int? = nil, verse: Int? = nil, version: String? = nil, id: Int? = nil) {
        self.text = text
        self.book = book
        self.chap = chap
        self.verse = verse
        self.version = version
        self.id = id
    }
    public var text : String?
    public var book : Int?
    public var chap : Int?
    public var verse : Int?
    public var version : String?
    public var id : Int?
    
    /// 【180】 這種，用藍色
    public static func isBlueColor(_ ft: DFoot?) -> Bool {
        return ft != nil && ft!.id != nil
    }
    /// foot: { text: '「該隱」意思是「得」。' } } 這種，用紫色。
    public static func isPurpleColor(_ ft: DFoot?) -> Bool{
        return ft != nil && ft!.id == nil
    }
}
extension DFoot {
    /// 用於 unit test 開發 BibleText2DTextTests
    /// 舉例來說，在 convert 過程，如果原本有 isFW2，然後被 split 之後，應該仍然保有 isFW2
    /// 也會被 DText 的 clone 呼叫
    public func clone() -> DFoot {
        let o = DFoot()
        o.book = book
        o.chap = chap
        o.verse = verse
        o.id = id
        o.text = text
        o.version = version
        return o
    }
}
extension DText {
    /// 用於 unit test 開發 BibleText2DTextTests
    /// 舉例來說，在 convert 過程，如果原本有 isFW2，然後被 split 之後，應該仍然保有 isFW2
    public func clone(_ isCloneChildren:Bool = true)->DText{
        let o = DText(w)
        o.sn = sn
        o.tp = tp
        o.tp2 = tp2
        o.isSnActived = isSnActived
        o.isCurly = isCurly
        o.isMerge = isMerge
        o.isParenthesesFW = isParenthesesFW
        o.isParenthesesHW = isParenthesesHW
        o.isParenthesesFW2 = isParenthesesFW2
        o.sobj = sobj
        o.isMap = isMap
        o.isPhoto = isPhoto
        o.isTitle1 = isTitle1
        //o.isRef = isRef
        o.refDescription = refDescription
        o.isBr = isBr
        o.isHr = isHr
        o.key = key
        o.keyIdx0based = keyIdx0based
        o.listTp = listTp
        o.listLevel = listLevel
        o.listIdx = listIdx
        o.isListStart = isListStart
        o.isListEnd = isListEnd
        o.isOrderStart = isOrderStart
        o.isOrderEnd = isOrderEnd
        o.idxOrder = idxOrder
        o.cssClass = cssClass
        o.isName = isName
        o.isBold = isBold
        o.isGODSay = isGODSay
        o.isOrigNotExist = isOrigNotExist
        o.cssColor = cssColor
        if (foot == nil){
            o.foot = nil
        } else {
            o.foot = foot!.clone()
        }
        if(children != nil){
            o.children = children!.map({a1 in a1.clone(isCloneChildren)})
        }
        o.tpContain = tpContain
        o.isGreek = isGreek
        o.isHebrew = isHebrew
        return o
    }
}
extension DText {
    public convenience init(_ w:Substring){
        self.init()
        self.w = String(w)
    }
    public convenience init(_ w: String){ self.init() ; self.w = w }
    /// 小括號 半型
    public convenience init(_ w: String, isParenthesesHW: Bool, isInTitle: Bool = false) {
        self.init()
        self.w = w
        self.isParenthesesHW = isParenthesesHW ? 1 : 0
        if isInTitle { self.isTitle1 = 1 }
    }
    /// sn: 11 tp: G tp2: WG or WAG or WTG
    public convenience init(_ w: String, sn: String,
                            tp: String, tp2: String ) {
        self.init()
        self.w = w
        self.sn = sn
        self.tp = tp
        self.tp2 = tp2
    }
    /// sn: 11 tp: G tp2: WG or WAG or WTG  花括號，大括號   1 | 0;
    public convenience init(_ w: String, sn: String, tp: String, tp2: String, isCurly: Bool ) {
        self.init()
        self.w = w
        self.sn = sn
        self.tp = tp
        self.tp2 = tp2
        if isCurly { self.isCurly =  1 }
    }
    /// sn: 11 tp: G tp2: WG or WAG or WTG ，並且 Sn 是否Active ;
    public convenience init(_ w: String, sn: String, tp: String, tp2: String, isActived: Bool ) {
        self.init()
        self.w = w
        self.sn = sn
        self.tp = tp
        self.tp2 = tp2
        if isActived { self.isSnActived = 1 }
    }
    /// 新譯本 詩3:1，同時會使 FW 也變為 1
    public convenience init(_ w: String, isParenthesesFW2: Bool ) {
        self.init()
        self.w = w
        if isParenthesesFW2 {
            self.isParenthesesFW = 1
            self.isParenthesesFW2 = 1
        }
    }
    /// 新譯本 詩3:1
    public convenience init(_ w: String, isParenthesesFW: Bool ) {
        self.init()
        self.w = w
        if isParenthesesFW {
            self.isParenthesesFW = 1
        }
    }
    /// 新譯本 詩3:1
    public convenience init(_ w: String, isTitle1: Bool ) {
        self.init()
        self.w = w
        if isTitle1 {
            self.isTitle1 = 1
        }
    }
    /// 搜尋結果
    public convenience init(
        _ w: String,
        keyword:String,key0basedIdx: Int) {
        
        self.init()
        self.w = w
        
        self.key = keyword
        self.keyIdx0based = key0basedIdx
    }
    /// 交互參照
    public convenience init(
        _ w: String,
        refDescription: String,
        isInTitle: Bool) {
        
        self.init()
        self.w = w
        
        //self.isRef = 1
        self.refDescription = refDescription
        if isInTitle { self.isTitle1 = 1}
    }
    public convenience init(
        isNewLine: Bool){
        
        self.init()
        self.w = nil
        
        if isNewLine { self.isBr = 1 }
    }
    public convenience init(
        isHr: Bool){
        
        self.init()
        self.w = nil
        
        if isHr { self.isHr = 1 }
    }
    /// 私名號，地名。
    public convenience init(
        _ str: String?,
        isName: Bool,
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init(str,isInTitle:isInTitle,isInHW:isInHW,isInFW:isInFW,isInFW2:isInFW2)
        
        self.isName = 1
//        if isInTitle { self.isTitle1 = 1 }
//        if isInHW { self.isParenthesesHW = 1 }
//        if isInFW { self.isParenthesesFW = 1 }
//        if isInFW2 { self.isParenthesesFW2 = 1 }
    }
    /// 虛點點
    public convenience init(
        _ str: String?,
        isOrigNotExist: Bool,
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init( str, isInTitle:isInTitle, isInHW:isInHW, isInFW:isInFW, isInFW2:isInFW2)
        
        self.isOrigNotExist = 1
//        if isInTitle { self.isTitle1 = 1 }
//        if isInHW { self.isParenthesesHW = 1 }
//        if isInFW { self.isParenthesesFW = 1 }
//        if isInFW2 { self.isParenthesesFW2 = 1 }
    }
    public convenience init(
        _ str: String?,
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init()
        self.w = str
        
        if isInTitle { self.isTitle1 = 1 }
        if isInHW { self.isParenthesesHW = 1 }
        if isInFW { self.isParenthesesFW = 1 }
        if isInFW2 { self.isParenthesesFW2 = 1 }
    }
    public convenience init(
        _ str: String?,
        foot: DFoot,
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init( str, isInTitle:isInTitle, isInHW:isInHW, isInFW:isInFW, isInFW2:isInFW2)
        
        self.foot = foot
    }
    public convenience init(
        _ str: String?,
        isGodSay: Bool,
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init( str, isInTitle:isInTitle, isInHW:isInHW, isInFW:isInFW, isInFW2:isInFW2)
        
        self.isGODSay = 1
    }
    public convenience init(
        tpContain: String?,
        children: [DText],
        isInTitle: Bool = false,
        isInHW: Bool = false,
        isInFW: Bool = false,
        isInFW2: Bool = false){
        
        self.init( nil, isInTitle:isInTitle, isInHW:isInHW, isInFW:isInFW, isInFW2:isInFW2)
        
        self.children = children
        self.tpContain = tpContain
    }
}


/// 用於 unit test 開發 BibleText2DTextTests
public func isTheSameDtext(_ a1:DText,_ a2:DText) -> Bool {
    if (a1.w != a2.w ) { return false }
    if (a1.sn != a2.sn ) { return false }
    if (a1.tp != a2.tp ) { return false }
    if (a1.tp2 != a2.tp2 ) { return false }
    if (a1.refDescription != a2.refDescription ) { return false }
    if (a1.isRef != a2.isRef ) { return false }
    
    if (a1.isParenthesesFW != a2.isParenthesesFW ) { return false }
    if (a1.isParenthesesHW != a2.isParenthesesHW ) { return false }
    if (a1.isParenthesesFW2 != a2.isParenthesesFW2) { return false }
    if (a1.isCurly != a2.isCurly ) { return false }

    if (a1.isBr != a2.isBr ) { return false }
    if (a1.isHr != a2.isHr ) { return false }
    if (a1.isMap != a2.isMap ) { return false }
    if (a1.isName != a2.isName ) { return false }
    if (a1.isBold != a2.isBold ) { return false }
    if (a1.isMerge != a2.isMerge ) { return false }
    if (a1.isPhoto != a2.isPhoto ) { return false }
    if (a1.isTitle1 != a2.isTitle1 ) { return false }
    if (a1.isGODSay != a2.isGODSay ) { return false }
    if (a1.isSnActived != a2.isSnActived ) { return false }

    if (a1.children != nil && a2.children != nil){
        if ( isTheSameDTexts(a1.children!, a2.children!) == false ){
            return false
        }
    } else if (a1.children == nil && a2.children == nil){
    }
    else { return false }
    
    if (a1.tpContain != a2.tpContain ) { return false }
    return true
}
/// 用於 unit test 開發 BibleText2DTextTests
public func isTheSameDTexts(_ a1:[DText],_ a2:[DText]) -> Bool {
    if a1.count != a2.count {
        return false
    }
    
    for i in 0..<a1.count {
        if (isTheSameDtext(a1[i], a2[i])==false) {
            return false
        }
    }
    return true
}

extension DText {
    /// 在 for 迴圈中, 常被用到
    /// 例如 w 是空, 或 isBr isHr, Sn 也無法再切割, #| 也不能再切割
    /// 通常 children 也不能切割啦 ... 因為它的 w 也通常是空的
    func isCantSplit()->Bool {
        if w == nil || w!.isEmpty { return true }
        
        if isBr == 1 || isHr == 1 { return true }
        
        if sn != nil { return true }
        
        if refDescription != nil { return true }
        
        if children != nil { return true }
        
        return false
    }
}

extension DText{
    func printDebug(){
        if children != nil {
            print ("\(tpContain ?? "(contain)") size=\(children!.count)")
            children!.forEach({$0.printDebug()})
        } else {
            if isBr == 1 { print ("(br)") }
            else if isHr == 1 { print ("(hr)")}
            else if sn != nil { print ("\(tp!)\(sn!)") }
            else if refDescription != nil { print ("\(refDescription!)") }
            else { print (w ?? "(empty)")}
        }
    }
}

/// TextView 點擊的原理，是判斷「第n個字元」
/// 然後從第n個字元，去找，是哪個 Dtext
/// 所以 children 的情況就比較複雜，像 ＜div＞ 的內容，不會有＜＞這字元產生
/// 但是同樣是 parent，身為 ()，他們的長度，左邊就算 1，右邊也算1個。
extension DText {
    /// 點擊，計算是哪個 DText 用的
    var cntChar: Int {
        if children != nil { return 0 }
        if w != nil { return w!.count }
        if isBr == 1 { return 2}
        return 0
    }
    /// 點擊，計算是哪個 DText 用的
    var cntCharContainFront: Int {
        if tpContain == "()" { return 1}
        if tpContain == "（）" { return 1}
        if tpContain == "qh" {return 1}// 「」
        return 0
    }
    /// 點擊，計算是哪個 DText 用的
    var cntCharContainBack: Int {
        if tpContain == "()" { return 1}
        if tpContain == "（）" { return 1}
        if tpContain == "qh" { return 1} // 「」
        return 0
    }
}
