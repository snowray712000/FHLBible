import Foundation

public protocol IDTextTestGetter {
    func main() -> DOneLine
}

func gBaseTest(_ texts: [DText], _ addr: String, _ ver: String = "和合本") -> DOneLine {
    let re = DOneLine()
    re.ver = ver
    re.addresses = addr
    re.children = texts
    return re
}
public class DTextTest01_W : IDTextTestGetter {
public init(){}
public func main() -> DOneLine {
return gBaseTest ([
    DText("亞伯拉罕生以撒；以撒生雅各；雅各生猶大和他的弟兄；")
], "太1:2")
}}

public class DTextTest02_isParenthesesHW : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
return gBaseTest ([
    DText("亞伯拉罕的後裔，大衛的子孫"),
    DText("（後裔，子孫：原文是兒子；下同）", isParenthesesHW: true),
    DText("，耶穌基督的家譜："),
], "太1:1")
}}

public class DTextTest03_SN : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
return gBaseTest ([
    DText("亞伯拉罕"),
    DText("<G11>",sn: "11", tp: "G", tp2: "WG"),
    DText("生"),
    DText("<G1080>",sn: "1080", tp: "G", tp2: "WAG"),
    DText("(G5656)",sn: "5656", tp: "G", tp2: "WTG"),
    DText("以撒"),
    DText("<G2464>",sn: "2464", tp: "G", tp2: "WAG"),
    DText("；"),
    DText("{<G1161>}",sn: "1161", tp: "G", tp2: "WAG", isCurly: true),
    DText("略..."),
], "太1:2")
}}

public class DTextTest04_SN : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
    let r1 = DText("{<H853>}",sn: "853", tp: "H", tp2: "WH")
return gBaseTest ([
    DText("起初"),
    DText("<H9002>",sn: "9002", tp: "H", tp2: "WH"),
    DText("<H7225>",sn: "7225", tp: "H", tp2: "WH"),
    DText("，　神"),
    DText("<H430>",sn: "430", tp: "H", tp2: "WH"),
    DText("創造"),
    DText("<H1254>",sn: "1254", tp: "H", tp2: "WH"),
    DText("(H8804)",sn: "8804", tp: "H", tp2: "WTH"),
    r1,
    DText("略..."),
], "創1:1")
}}

public class DTextTest05_FW2 : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
return gBaseTest ([
    DText("仇敵攻擊，　神救助",isTitle1: true),
    DText("（大衛的詩，是在逃避他兒子押沙龍時作的。", isParenthesesFW: true),
    DText("（除特別註明外，詩篇開首細字的標題在《馬索拉抄本》都屬於第1節，原文的第2節即是譯文的第1節，依次類推。）", isParenthesesFW2: true),
    DText("）", isParenthesesFW: true),
    DText("耶和華啊！我的仇敵竟然這麼多。起來攻擊我的竟然那麼多。"),
], "詩3:1", "新譯本")
//return gBaseTest ([
//    DText("仇敵攻擊，　神救助",isTitle1: true),
//    DText("（大衛的詩，是在逃避他兒子押沙龍時作的。", isInTitle: true, isInFW: true),
//    DText("（除特別註明外，詩篇開首細字的標題在《馬索拉抄本》都屬於第1節，原文的第2節即是譯文的第1節，依次類推。）",  isInTitle: true, isInFW2: true),
//    DText("）", isInTitle: true, isInFW: true),
//    DText("耶和華啊！我的仇敵竟然這麼多。起來攻擊我的竟然那麼多。"),
//], "詩3:1", "新譯本")
}}

public class DTextTest06_Active : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
    let r1 = DText("{<H853>}",sn: "853", tp: "H", tp2: "WH")
return gBaseTest ([
    DText("起初"),
    DText("<H9002>",sn: "9002", tp: "H", tp2: "WH", isActived: true),
    DText("<H7225>",sn: "7225", tp: "H", tp2: "WH"),
    DText("，　神"),
    DText("<H430>",sn: "430", tp: "H", tp2: "WH"),
    DText("創造"),
    DText("<H1254>",sn: "1254", tp: "H", tp2: "WH"),
    DText("(H8804)",sn: "8804", tp: "H", tp2: "WTH"),
    r1,
    DText("略..."),
], "創1:1")
}}

/// 搜尋關鍵字時，第1關鍵字，第2關鍵字。 「生 以撒 雅各」
public class DTextTest07_Keywords : IDTextTestGetter {
    public init(){}
public func main() -> DOneLine {
return gBaseTest ([
    DText("亞伯拉罕生"),
    DText("生", keyword: "生", key0basedIdx: 0),
    DText("以撒", keyword: "以撒", key0basedIdx: 1),
    DText("；"),
    DText("以撒", keyword: "以撒", key0basedIdx: 8),
    DText("生", keyword: "生", key0basedIdx: 0),
    DText("雅各", keyword: "雅各", key0basedIdx: 2),
    DText("；"),
    DText("雅各", keyword: "雅各", key0basedIdx: 2),
    DText("生", keyword: "生", key0basedIdx: 0),
    DText("猶大和他的弟兄；"),
], "太1:2")
}}

/// 交互參照，此測試忽略底線，換行。最後一個是為了測試亂加的
public class DTextTest08_Reference : IDTextTestGetter {
    public init(){}
    public func main() -> DOneLine {
    return gBaseTest ([
        
        DText("耶穌基督的家譜", isTitle1: true),
        DText("（", isParenthesesHW: true, isInTitle: true),
        DText("#路 3:23-38|", refDescription: "路3:23-38", isInTitle: true),
        DText("）", isParenthesesHW: true, isInTitle: true),
        DText(isNewLine: true),
        DText("亞伯拉罕的後裔、大衛的子孫"),
        DText("( [ 1.1] 「後裔，子孫」：原文直譯「兒子」。)", isParenthesesHW: true),
        DText("耶穌基督的家譜："),
        DText("#路 3:23-38|", refDescription: "路3:23-38", isInTitle: false),

    ], "太1:1", "和合本2010" )
}}


/// 私名號、虛點點，不論是 人名、地名，都是
public class DTextTest09_NamePlace : IDTextTestGetter {
    public init(){}
    public func main() -> DOneLine {
    return gBaseTest ([
        
        DText("亞伯拉罕", isName: true),
        DText("的後裔"),
        DText("亞伯拉罕", isName: true, isInTitle: true),
        DText("的後裔"),
        DText("亞伯拉罕", isName: true, isInHW: true),
        DText("的後裔"),
        DText("亞伯拉罕", isName: true, isInFW: true),
        DText("的後裔"),
        DText("亞伯拉罕", isName: true, isInFW2: true),
        DText("的後裔"),
        DText("亞伯拉罕", isOrigNotExist: true, isInFW2: true),
        DText("的後裔"),
    ], "太1:1", "和合本2010" )
}}

/// 注腳  { w: '到了指定的時候' }, { w: '【180】', foot: { book:1, chap: 4, version: 'cnet', id: 180 } },
public class DTextTest10_Foot : IDTextTestGetter {
    public init(){}
    public func main() -> DOneLine {
    
        return gBaseTest ([
            DText("到了指定的時候"),
            DText("【180】", foot: DFoot(book:1, chap:4, version: "cnet", id: 180)),
            
            DText("那人和他妻子夏娃同房，夏娃就懷孕，生了該隱"),
            DText("([4.1]「該隱」意思是「得」。)", foot: DFoot(text: "「該隱」意思是「得」。"))
        
    ], "太1:1", "和合本2010" )
}}

/**
 { w: '耶穌聽了，十分感慨，對跟隨他的人說：' },
 { w: '「我確實地告訴你們：在以色列我沒有見過有這麼大信心', isGODSay: 1 },
 { w: '【1】', isGODSay: 1, foot: { version: 'csb', id: 1, book: 40, chap: 8 } },
 { w: '的人。', isGODSay: 1 }
 */
public class DTextTest11_Godsay : IDTextTestGetter {
    public init(){}
    public func main() -> DOneLine {
    
        return gBaseTest ([
            DText("耶穌聽了，十分感慨，對跟隨他的人說："),
            DText( "「我確實地告訴你們：在以色列我沒有見過有這麼大信心" , isGodSay: true ),
            DText("【1】", foot: DFoot(book:40, chap:8, version: "csb", id: 1)),
            DText("的人。", isGodSay: true),
        
    ], "太1:1", "和合本2010" )
}}

var testCases : [IDTextTestGetter] = [
    DTextTest01_W(),
    DTextTest02_isParenthesesHW(),
    DTextTest03_SN(),
    DTextTest04_SN(),
    DTextTest05_FW2(),
    DTextTest06_Active(),
    DTextTest07_Keywords(),
    DTextTest08_Reference(),
    DTextTest09_NamePlace(),
    DTextTest10_Foot(),
    DTextTest11_Godsay(),
]

public func getTestCase(_ idx:Int) -> IDTextTestGetter {
    if idx < 0 || idx >= testCases.count {
        return testCases[0]
    }
    return testCases[idx]
}
