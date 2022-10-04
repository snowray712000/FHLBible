//
//  FooterConvertorDTexts.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/22.
//

import Foundation

func cvtFooter(_ txt: String, _ addr: DAddress,_ ver:String) -> [DText] {
    return FooterConvertor(addr,ver).mainConvert(txt)
}

fileprivate class FooterConvertor : NSObject {
    init (_ addr: DAddress,_ ver:String){
        self._addr = addr
        self._ver = ver
    }
    func mainConvert(_ txt:String)->[DText] {
        //SplitByRegex
        var r1 = [DText(txt)]
        
        r1 = ssDtParentheses(r1)
        r1 = doSSDTextCore(r1, {SSQuotationH()})
        
        if ["cnet","lcc"].contains(_ver) {
            r1 = doSSDTextCore(r1, {SSRef1(_addr)})
            r1 = doSSDTextCore(r1, {SSRef2(_addr)})
            r1 = MergeSSRef2(_ver).mainMerge(r1)
        } else if ["csb"].contains(_ver){
            r1 = doSSDTextCore(r1, {SSRef3(_addr)})
            r1 = MergeSSRef2(_ver).mainMerge(r1)
        }
        return r1
    }
    private var _addr: DAddress!
    private var _ver: String!
    
}

fileprivate class MergeSSRef2 : NSObject {
    init(_ ver:String){
        _ver = ver
    }
    func mainMerge(_ text:[DText]) -> [DText]{
        return doEachChild(text)
    }
    private var _ver: String!
    private func doEachChild(_ r1:[DText])->[DText]{
        for a1 in r1{
            if a1.children != nil {
                a1.children = doEachChild(a1.children!)
            }
        }
        return doOneLevelList(r1)
    }
    /// 在 SSForFooterTests dev01a 開發
    private func doOneLevelList(_ r1:[DText]) -> [DText] {
        // step1
        let r2 = ijnRange(0, r1.count).filter({r1[$0].refDescription == "a"})
        
        // step2
        let r3 :[Int:[Int]] = {
            var r1 = [Int:[Int]]()
            
            var t1 = -2
            var t2 = -1 // key
            for a1 in r2 {
                if t1 + 1 != a1 {
                    r1[a1] = [a1]
                    t1 = a1
                    t2 = a1
                } else {
                    r1[t2]!.append(a1)
                    t1 = a1
                }
            }
            
            return r1
        }()
        
        // step3 last
        var re: [DText] = []
        var r2b: [Int] = [] // pass this, 例如會是 [3,4] [7,8,9] [12]
        for i in 0..<r1.count {
            if  r2b.contains(i) { continue }
            
            let r2 = r3[i]
            if r2 == nil {
                re.append(r1[i])
            } else {
                r2b = r2! // [3,4]
                let wNew = ijnRange(r2b.first!, r2b.count).map({r1[$0].w!}).joined(separator: "")
                let dNew = r1[i].clone()
                dNew.w = wNew
                if _ver == "csb" {
                    // 《彌迦書》5:2
                    dNew.refDescription = ijnReplaceString(Self.regCsb, dNew.w!, "")
                } else { // cnet lcc (呂振中譯本)
                    dNew.refDescription = wNew
                }
                re.append(dNew)
            }
        }
        return re
    }
    static var regCsb = try! NSRegularExpression(pattern: #"《|》"#, options: [])
}

/// Quotation 引號 「」，半型開引號/半型關引號
/// https://zh.wikipedia.org/wiki/引号
fileprivate class SSQuotationH : SplitStringDTextBtwBase {
    override func ovGRegexp() -> NSRegularExpression {
        return Self.reg
    }
    override func ovIsFront(_ a1: SplitByRegexOneResult) -> Bool {
        return a1.w == "「"
    }
    override func ovGDTextContain(_ dtexts: [DText], _ a1: SplitByRegexOneResult?) -> DText {
        // 也是 重點 ，所以抄現有的 span.exp 格式
        let r1 = DText ()
        r1.children = dtexts
        r1.tpContain = "qh"
        return r1
    }
    static private var reg = try! NSRegularExpression(pattern: #"「|」"#, options: [])
}

fileprivate class SSRef1 : SplitStringDTextCore
{
    init(_ addr: DAddress){
        self._addr = addr
    }
    override var ovReg: NSRegularExpression { Self.reg }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        
        cloneOfSrc.w = String(a1.w)
        let ch = _addr.chap
        var ve = ""
        if a1.exec[1] != nil {
            ve = String( a1.exec[1]! )
        } else if a1.exec[2] != nil {
            ve = String( a1.exec[2]! )
        }
        
        cloneOfSrc.refDescription = "\(_engs)\(ch):\(ve)"
        //cloneOfSrc.refDescription = String( a1.exec[1]! )
        return cloneOfSrc
    }
    // 第2-10節, 第10節, 參2:1
    static private var reg = try! NSRegularExpression(pattern: #"第(\d+\s*-\s*\d+)節|參?第(\d+)節"#, options: [])
    fileprivate var _addr: DAddress!
    var _engs: String { BibleBookNames.getBookName(self._addr.book, .Matt)}
}

/// cnet 版本開發，lcc 也似乎適用、而 csb 不適用，因為它有 《彌迦書》5:2 這樣的格式
fileprivate class SSRef2 : SplitStringDTextCore
{
    init(_ addr: DAddress){
        self._addr = addr
    }
    override var ovReg: NSRegularExpression { Self.reg }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        cloneOfSrc.w = String(a1.w)
        cloneOfSrc.refDescription = "a"
        //cloneOfSrc.refDescription = String( a1.exec[1]! )
        return cloneOfSrc
    }
    // 2:5-7
    // 2:5
    // 5-7
    // 2:5, 23
    // 6:1, 5-7; 9:5-6 ... [,\s;]* 包進來，最後會再總整理，連續一起的合成一個
    // (太|可)?
    static private var reg: NSRegularExpression = {
        let r2 = BookNameAndId().getNamesOrderByNameLength().joined(separator: "|")
        let r3 = "(" + r2 + ")?" //  –
        let r1 = #"((\d+):(\d+) *– *(\d+)?:(\d+)|(\d+):(\d+)|(\d+)-(\d+))[,\s;；\d:-]*"#
        
        let r4 = r3 + r1
        return try! NSRegularExpression(pattern: r4, options: [.caseInsensitive])
    }()
    fileprivate var _addr: DAddress!
}
/// 先搞懂 cnet 流程，再來看這個變型
/// csb 出現  《彌迦書》5:2
fileprivate class SSRef3 : SplitStringDTextCore {
    init(_ addr: DAddress){
        self._addr = addr
    }
    override var ovReg: NSRegularExpression { Self.reg }
    override func ovGenerateDText(_ a1: SplitByRegexOneResult, _ cloneOfSrc: DText) -> DText {
        cloneOfSrc.w = String(a1.w)
        cloneOfSrc.refDescription = "a"
        //cloneOfSrc.refDescription = String( a1.exec[1]! )
        return cloneOfSrc
    }
    static private var reg: NSRegularExpression = {
        let r2 = BookNameAndId().getNamesOrderByNameLength().joined(separator: "|")
        let r3 = "《(" + r2 + ")》?" //  –
        let r1 = #"((\d+):(\d+) *– *(\d+)?:(\d+)|(\d+):(\d+)|(\d+)-(\d+))[,\s;；\d:-]*"#
        
        let r4 = r3 + r1
        return try! NSRegularExpression(pattern: r4, options: [.caseInsensitive])
    }()
    fileprivate var _addr: DAddress!
}
