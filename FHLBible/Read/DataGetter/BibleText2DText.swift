//
//  File.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/9/10.
//

import Foundation

/// 用在 BibleGetterViaFhlApiQsb 時
/// 那個 class, 從 qsb 取得資料, 再經過 cvtor 轉換為 [DOneLine] 但裡面的資料, 只是純文字轉為 w 去
/// 並非真正的依內容去處理
/// 開發過程，用 unit test 方式 BibleText2DTextTests
class BibleText2DText {
    typealias c = BibleText2DText
    func main(_ data:[DOneLine], _ ver: String)->[DOneLine]{
        var re: [DOneLine] = []
        for a1 in data {
            // let str = a1.children![0].w! // debug 用
            let r1a = addTitles(a1.children!) // 高思譯本，發現必須，title先作，再作換行。 h2 \n /h2 就斷開了
            var r1 = ssDtNewLine(r1a)
            
            // print (ver)
            if let firstWord = r1.first?.w, r1.count == 1, ["a", "b", "c"].contains(firstWord) {
                r1.first!.w = "(併入上節)"
            }

            
            if ["fhlwh"].contains(ver){
                // 新約原文 + + + 的現象 (韋: )(聯: )
                r1 = ssDtGreekPlusPlusPlus(r1, ver)
            }
            
            // god say <span style="color:rgb(195,39,43);"> // 必須在 parentheses 前面，因為有 (195,39,43) 那個括號
            if ["csb"].contains(ver){
                r1 = ssDtSpanGodSayCsb(r1)
            }
            
            r1 = addParentheses(r1) // 大部分都有
            if ["kjv"].contains(ver){
                r1 = ssDtKjvRf(r1)
                r1 = ssDtKjvFi(r1)
                r1 = ssDtKjvCM(r1)
                r1 = ssDtKjvFoFo(r1)
            } else if ["esv"].contains(ver) {
                r1 = ssDtEsvSubtitle(r1)
            }
            
            
            r1 = ssDtUnderlineU(r1) // 和合本2010
            
            // 思高譯本 ofm 現代台語漢字 ttvh 現代中文譯本2019 tcv2019 tte 台語全羅 tte 聖經公會現代客語漢字 thv12h 和合本2010 rcuv 文理和合本 cuwv
            if ["ofm","ttvh","ttvhl2021","ttvcl2021","tcv2019","tte","thv12h","thv2e","rcuv","cuwv"].contains(ver) {
                r1 = ssDtSSBoldB(r1)
            }
            

            
            r1 = ssDtReference(r1, ver)
            r1 = addSN(r1)
            
            // 【1】cnet lcc 呂振中譯本 csb 中文標準譯本
            if ["cnet","csb","lcc"].contains(ver) {
                r1 = ssDtFoot(r1, a1.address2!, ver)
            }
            
//            let r1 = cvt(str)
            let r2 = DOneLine(addresses: a1.addresses, children: r1, ver: a1.ver)
            re.append(r2)
        }
        return re

    }
    /// 在DOMParsor 之前, 原文 <WTH592> 會導致錯誤，因此，要先變為一對 </WTH592>
    /// 在 ios 版本似乎不會用到
    private func replaceOrigToPair(_ dtexts: [DText])-> [DText]{
        return dtexts
    }
    /// KJV 以 FI 為例，它是 FI Fi 而非 FI /FI 成對
    /// 在 ios 好像不會用到，因為沒用到 DOMParsor
    private func replaceKJVToPair(_ dtexts: [DText])->[DText]{
        return dtexts
    }
    /// test05_a_dev 抄過來
    /// <h1></h1> 或 hx 都可以 hxx 也可以
    private func addTitles(_ dtexts: [DText]) -> [DText] {
        return ssDtH1H2H3H4Title(dtexts)
    }
    /// 直接全抄 test05b_dev 來的
    /// 全型大括號(可能有兩層)，半型小括號
    /// test05 為開發過程基礎
    private func addParentheses(_ dtexts: [DText])->[DText]{
        return ssDtParentheses(dtexts)
    }
    /// 從 test03a_dev 中實驗過
    static var regSn = try! NSRegularExpression(pattern: "\\{<(W[AT]?([G|H]))0*(\\d+[a-zA-Z]?)>\\}|<(W[AT]?([G|H]))0*(\\d+[a-zA-Z]?)>", options: [])
    private func addSN(_ dtexts: [DText])->[DText]{
        func doOne(_ dtext: DText)->[DText]?{
            assert ( dtext.children == nil , " doMore 沒處理好，這裡不該有 children。 ")
            
            if ( dtext.w == nil || dtext.w!.count == 0 ){
                return nil
            }
            
            let r1 = SplitByRegex().main(str: dtext.w!, reg: c.regSn )
            if ( r1 == nil ){
                return nil
            }
            
            let re = r1!.map({ (a1:SplitByRegexOneResult) -> DText in
                let r2 = dtext.clone(false)
                r2.w = String(a1.w)
                if ( a1.isMatch()){
                    let isCurly = a1.index[1] != -1
                    if ( isCurly ){
                        r2.isCurly = 1
                    }
                    
                    let isn = isCurly ? 3 : 6 // index of sn
                    let itp = isCurly ? 2 : 5
                    let itp2 = isCurly ? 1 : 4
                    r2.tp = String(a1.exec[itp]!)
                    r2.tp2 = String(a1.exec[itp2]!)
                    r2.sn = String(a1.exec[isn]!)
                    if ( r2.tp2!.firstIndex(of: "T") == nil ){
                        r2.w = "<" + r2.tp! + r2.sn! + ">" // 不是用 <WG12> 而是 <G12>
                    } else {
                        r2.w = "(" + r2.tp! + r2.sn! + ")" // 不是用 <WG12> 而是 <G12>
                    }
                    if( r2.isCurly == 1 ){
                        r2.w = "{"+r2.w!+"}"
                    }
                }
                return r2
            })
            
            return re
        }
        
        func doMore(_ dtexts: [DText])->[DText]{
            var re: [DText] = []
            for a1 in dtexts {
                if ( a1.children != nil ){
                    let r2 = doMore(a1.children!)
                    a1.children = r2
                    re.append(a1)
                } else {
                    let r2 = doOne(a1)
                    if ( r2 == nil ){
                        re.append(a1)
                    } else {
                        re.append(contentsOf: r2!)
                    }
                }
            }
            return re
        }
        
        let re = doMore(dtexts)
        return re
    }
}

