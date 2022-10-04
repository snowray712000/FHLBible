//
//  RegexTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/6/23.
//

import Foundation
import XCTest
@testable import FHLBible

/// Swift 的 Regex 完全不熟，用此練習
/// 練習此是為了作 SplitStringByRegex 這個 Class
class RegexTests : XCTestCase {
    
    /// 練習 Regex 的 matches 功能
    /// Range 的操作不熟練，可同時在些熟練
    func testBasic01(){
        // 了解 matches 回傳型態 與 基本用法
        let r1 = try! NSRegularExpression(pattern: "馬太福音", options: [])
        let str = "嘿唷馬太福音，馬太福音唷"
        let strRange = NSRange(str.startIndex..<str.endIndex, in: str)
        let r3:[NSTextCheckingResult] = r1.matches(in: str, options: [], range: strRange )
        
        var a1: NSTextCheckingResult = r3.first! // 同等於 r3[0]
        var a2: NSRange = a1.range(at: 0) // loc: 2, len:4 (第一個出現的地方)
        XCTAssert( a2 == NSRange(location: 2, length: 4))
        XCTAssert( "馬太福音" == String(str[Range(a2, in: str)!]))
        
        // 注意, a2 第1個範例，還沒用到 regex 的 capture，所以只會有 a1.range(0), 不會有 a1.range(1)
        // 與 typescript 一樣，[0]是指整個, [1]才是指第1個 capture的
        
        a1 = r3[1]
        a2 = a1.range(at: 0)
        XCTAssert( a2 == NSRange(location: 7, length: 4))
        XCTAssert( "馬太福音" == String(str[Range(a2, in: str)!]))
        
        // 到此，熟練後，寫個小函式方便用 (已成為主專案函式)
        func ijnMatches(_ reg: NSRegularExpression,_ str: String)->[NSTextCheckingResult]{
            return reg.matches(in: str, options: [], range: NSRange(str.startIndex..<str.endIndex, in: str))
        }
    }

//    /// 從 Basic01 學到的 (已成為主專案程式)
//    private func ijnMatches(_ reg: NSRegularExpression,_ str: String)->[NSTextCheckingResult]{
//        return reg.matches(in: str, options: [.withTransparentBounds], range: NSRange(str.startIndex..<str.endIndex, in: str))
//    }
    /// 從  Basic03 學到的 (已成為主專案程式)
//    private func ijnReplaceString(_ reg: NSRegularExpression,_ str:String,_ strReplaced:String ) ->String {
//        let r1 : NSMutableString = NSMutableString(string: str)
//        let r2 = r1 as String
//        reg.replaceMatches(in: r1, options: [], range: NSRange(r2.startIndex..<r2.endIndex, in: r2), withTemplate: strReplaced)
//        return r1 as String
//    }
    /// 練習當 Regex 中有括號  Capture 時
    func testBasic02_Capture(){
        let r1 = try! NSRegularExpression (pattern: "((馬太|路加|約翰|馬可)福音)", options: []);
        let re = ijnMatches(r1, "嘿馬太福音1:2-3")
        
        let r2 = re[0]
        XCTAssert( 3 == r2.numberOfRanges ) // 若沒有 capture, 一定是 1 (這有2層括號，所以是2個capture)
        
        XCTAssert( NSRange(location: 1, length: 4) == r2.range(at:0) )
        XCTAssert( NSRange(location: 1, length: 4) == r2.range(at:1) )
        XCTAssert( NSRange(location: 1, length: 2) == r2.range(at:2) )
    
        // 比較 TypeScript 的
//        const r1 = new RegExp('((馬太|路加|約翰|馬可)福音)');
//        const r2 = '嘿馬太福音1:2-3'.match(r1);
//        expect(r2[0]).toBe('馬太福音');
//        expect(r2[1]).toBe('馬太福音');
//        expect(r2[2]).toBe('馬太');
//        expect(r2.index).toBe(1);
    }
    /// 練習當 Regex 要取代文字時
    /// 嘿馬太福音1:2-3 變 嘿Mt1:2-3。馬太福音 用 Mt 取代
    func testBasic03_Replace(){
        let reg = try! NSRegularExpression(pattern: "馬可福音|馬太福音", options: [])
        let str = "嘿馬太福音1:2-3"
        
        let str2: NSMutableString = NSMutableString(string: str)
        var r2 = reg.replaceMatches(in: str2, options: [], range: NSRange(str.startIndex..<str.endIndex, in: str), withTemplate: "Mt")
        XCTAssert( r2 == 1 )
        XCTAssert( "嘿Mt1:2-3" == str2)
        
        // 取代，會產生新的字串。
        // 取代，不會用 matches，而是直接用 replaceMatches (文件中有寫到2個關於字串取代的)
        // NSMutableString 沒有 startIndex endIndex，也不能作為 in 參數 StringProtocol
        // 承上，直接用 as String 即可
        let str3 = str2 as String
        r2 = reg.replaceMatches(in: str2, options: [], range: NSRange(str3.startIndex..<str3.endIndex, in: str3), withTemplate: "Mt")
        
        func ijnReplaceString(_ reg: NSRegularExpression,_ str:String,_ strReplaced:String ) ->String {
            let r1 : NSMutableString = NSMutableString(string: str)
            let r2 = r1 as String
            reg.replaceMatches(in: r1, options: [], range: NSRange(r2.startIndex..<r2.endIndex, in: r2), withTemplate: strReplaced)
            return r1 as String
        }
    }
    /// 若是馬太福音，則變為Mt，若是馬可福音，則用Mk
    /// 傳入一個函式，作為取代的參數
    func testBasic04_ReplaceViaFunction(){
        // let reg = try! NSRegularExpression(pattern: "馬可福音|馬太福音", options: [])
        let reg = try! MyReg(pattern: "馬可福音|馬太福音", options: [])
        let str = "嘿馬太福音1:2-3。嘿馬可福音1:2-4。" // 預期變 嘿Mt1:2-3。嘿Mk1:2-4
        
        let re = ijnReplaceString(reg, str, "")
        XCTAssert("嘿Mt1:2-3。嘿Mk1:2-4。" == re)
        
        // 寫一個工具 IjnRegex
        let reg2 = try! IjnRegex(pattern: "馬可福音|馬太福音", options: [])
        reg2.setCallbackForReplacement({$0[0] == "馬太福音" ? "Mt" : "Mk"})
        let re2 = reg2.replacing(str)
        XCTAssert("嘿Mt1:2-3。嘿Mk1:2-4。" == re2)
    }
//    // 本來就還沒成功過
//    func testBasic05_CaptureTemplate(){
//        let reg = try! NSRegularExpression(pattern: "([a-z]{1,40})0$1", options: [])
//        //let re = ijnMatches(reg, "這是<abc>1875</abc>與<cd>977</cd>還有不合的<ab>5121</dd>")
//        let re = ijnMatches(reg, "abc0abc")
//        print(re.count)
//        XCTAssert( 1 == re.count)
//    }
    /// 不同 capture 中，有不同的數量時
    /// 1:e 第一章，最後一節 ... capture 數量 1 個 ... 即 1 (它其實是第3種 case 的後半部，很少有人會直接寫 1:e)
    /// 1:2-e 第一章第2節到最後一節 ... capture 數量 2 個 ...  即 1, 2
    /// 1:2-2:e 第1章第2節到第2章最後一節 .... 不會有這組，因為 2:e 會被第1組取代
    func testBasic_06(){
        let reg = try! NSRegularExpression(pattern: #"(\d+):(\d+)-e|(\d+):e"#, options: [.caseInsensitive])
        
        let re = ijnMatches(reg, "#太1:2-e|")
        let re2 = ijnMatches(reg, "#太1:2-2:e|")
        let re3 = ijnMatches(reg, "詳見 #太1:2-e|、#約2:2-e|")
        
        // #太1:2-e|
        XCTAssert(1 == re.count)
        XCTAssert( NSRange(location: 2, length: 5) == re[0].range(at: 0))
        XCTAssert( NSRange(location: 2, length: 1) == re[0].range(at: 1)) // 1 章
        XCTAssert( NSRange(location: 4, length: 1) == re[0].range(at: 2)) // 2 節
        XCTAssert( NSRange(location: 9223372036854775807, length: 0) == re[0].range(at: 3)) // 無效
        XCTAssert( 0 == re[0].range(at: 3).length) // 無效, length 會是0,
        // 因此, substring 有些應該是 nil, 而非一定是 SubString
        
        // "#太1:2-2:e|"
        XCTAssert(1 == re2.count)
        XCTAssert( NSRange(location: 6, length: 3) == re2[0].range(at: 0))
        XCTAssert( 0 == re2[0].range(at: 1).length)
        XCTAssert( 0 == re2[0].range(at: 2).length)
        XCTAssert( NSRange(location: 6, length: 1) == re2[0].range(at: 3))
        
        XCTAssert(2 == re3.count)
        
    }
    /// 某些情況，只要取得第1個Match，效率上會更好
    /// 在開發 StringToVerseRange 時，在 GetAddresses class 的  classifyType 會用到
    /// 而且，比起 NSTextCheckingResult, 更常被用到的是  SubString
    /// 生成 ijnMatchFirstAndToSubString 工具
    func testBasic_07(){
        let reg = try! NSRegularExpression(pattern: #"(\d+):(\d+)|([a-zA-Z]+)"#, options: [])
        
        let str = "看見 5:2 和 65:12"
        let r1 = reg.firstMatch(in: str, options: [], range: NSRange(str.startIndex..<str.endIndex, in: str))
        
        func gStr(_ rg: NSRange,_ str: String)-> Substring? {
            if rg.length == 0 {
                return nil
            }
            return str[Range(rg, in: str)!]
        }
        
        let r2 = (0..<r1!.numberOfRanges).map({gStr(r1!.range(at: $0), str)})
        XCTAssert( r2[0] == "5:2" )
        XCTAssert( r2[1] == "5" )
        XCTAssert( r2[2] == "2" )
        XCTAssert( r2[3] == nil )
    }
    
    func testCaseSmartDescriptEndParsing(){
        // 1:end or 1:e
        // 1:2-2:end or 1:2-2:e
        // 1:3-end or 1:3-e
        let reg = try! NSRegularExpression(pattern: #"(?:((\d+):)e|end)|(?:((\d+):(?:\d+)-)e|end)"#, options: [.caseInsensitive])
        let r1 = SplitByRegex().main(str: "1:3-end", reg: reg)
        let r2 = SplitByRegex().main(str: "1:3-e", reg: reg)
        //let r3 = SplitByRegex().main(str: "1:3-", reg: reg)
        //print (r3!.count)
    }
    func testSearchKeyword() throws {
        let r1 = "摩西  亞倫".split(separator: " ")
        let r2 = r1.map({"(\($0))"}).joined(separator: "|")
        let r3 = try NSRegularExpression(pattern: r2, options: [.caseInsensitive])
        let r4 = SplitByRegex().main(str: "摩西亞倫", reg: r3)
        
        XCTAssertEqual(r4![0].w, "摩西")
        XCTAssertEqual(r4![1].w, "亞倫")
        XCTAssertNotNil(r4![0].exec[1]) // not nil 可以用在判定第幾個關鍵字
        XCTAssertNil(r4![0].exec[2])
        XCTAssertNotNil(r4![1].exec[2]) // not nil 可以用在判定第幾個關鍵字
        XCTAssertNil(r4![1].exec[1])
        
    }
}

class MyReg : NSRegularExpression {
    override func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        let rng = result.range(at: 0)
        let s1 = string[Range(rng, in: string)!]
        if s1 == "馬太福音" {
            return "Mt"
        }
        return "Mk"
    }
}
