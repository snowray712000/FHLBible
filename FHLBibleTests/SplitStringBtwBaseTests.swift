//
//  SplitStringBtwBaseTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/9/8.
//

import XCTest
@testable import FHLBible


class SplitStringBtwBaseTests: XCTestCase {
    /// 開發 BibleText2DText 過程，處理到 title的時候，也就是 <h1> </h1> 這種的時候作的
    /// 此測試，沒有包成 BibleText2DText, 而是開發過程, 保留著, 它的思路
    func test05a_dev(){
    /// 這小個，也卡了我12小時。(不可思議)
        let rr1 = "abc<h1>bdkjsdf<h2>akjgioihag</h2>aohbioasd</h1>asdf"
        let dtexts = [DText(rr1)]
        
        let reg1 = try! NSRegularExpression(pattern: "</(h\\d+)>", options: [.caseInsensitive])
  
        func lastFit(_ rr1:String,_ minStep:Int = -5) -> [Any]?{
            // minStep 是後來加的，原本是 -1，其實沒必要1格1格往前，像 </h3> 最短也需要5字元，
            for i in stride(from: rr1.count+minStep, through: 0, by: minStep){
                let len = rr1.count - i
                let rr2 = reg1.firstMatch(in: rr1, options: [], range: NSRange(location: i, length: len))
                if ( nil != rr2){
                    let rr3a = rr2!.range(at: 0)
                    let rr3 = rr1 [ Range(rr2!.range(at: 1), in:rr1)! ]
                    return [rr3a.location,rr3]
                }
            }
            return nil
        }
        
        func corresponseFit(_ rr1:String, _ rrr2: [Any])->Int?{
            let reg2 = try! NSRegularExpression(pattern: "<" + (rrr2[1] as! Substring) + ">", options: [.caseInsensitive])
            let rr7 = reg2.firstMatch(in: rr1, options: [], range: NSRange(location: 0, length: rr1.count))
            if ( rr7 != nil ){
                return rr7!.range(at: 0).location
            } else {
                return nil
            }
        }
        
        func tryFit(_ rr1:String)->[Any]?{
            let rrr2 = lastFit(rr1)
            if (rrr2 != nil ){
                let rrr3 = corresponseFit(rr1, rrr2!)
                if ( rrr3 != nil ){
                    return [rrr2![0],rrr2![1],rrr3!]
                }
            }
            return nil
        }
        
        func splitByHeadTagOne(_ dtext: DText)->[DText]?{
            if (dtext.w == nil || dtext.w!.count == 0){
                return nil
            }
            let r1 = tryFit(dtext.w!)
            if ( r1 == nil ){
                return nil
            }
            
            let idx1 = r1![2] as! Int
            let idx2 = r1![0] as! Int
            let tp = r1![1] as! Substring
            
            var re: [DText] = []
            let str1 = String(ijnSubString(dtext.w!, len: idx1))
            let str2 = String(ijnSubString(dtext.w!, pos: idx1 + tp.count + 2, to: idx2))
            let str3 = String(ijnSubString(dtext.w!, pos: idx2 + tp.count + 3))
            
            let r1a = dtext.clone()
            r1a.w = str1
            let r1b = dtext.clone()
            r1b.w = str2
            r1b.isTitle1 = 1
            let r1c = dtext.clone()
            r1c.w = str3
            re.append(r1a)
            let r2 = splitByHeadTagOne(r1b)
            if ( r2 == nil ){
                re.append(r1b)
            } else {
                re.append(contentsOf: r2!)
            }
            re.append(r1c)
            return re
        }
        func splitByHeadTags(_ dtexts:[DText])->[DText]{
            var re : [DText] = []
            for a1 in dtexts {
                let re2 = splitByHeadTagOne(a1)
                if ( re2 == nil ){
                    re.append(a1)
                } else {
                    re.append(contentsOf: re2!)
                }
            }
            return re
        }
        let re3 = splitByHeadTags(dtexts)
        
        // let rr1 = "abc<h1>bdkjsdf<h21>akjgioihag</h21>aohbioasd</h1>asdf"
        XCTAssertEqual(5, re3.count)
        XCTAssertEqual("abc", re3[0].w!)
        XCTAssertEqual("bdkjsdf", re3[1].w!)
        XCTAssertEqual("akjgioihag", re3[2].w!)
        XCTAssertEqual("aohbioasd", re3[3].w!)
        XCTAssertEqual("asdf", re3[4].w!)
        for i in stride(from: 1, through: 3, by: 1) {
            XCTAssertEqual(1, re3[i].isTitle1)
        }
        XCTAssertEqual(nil, re3[0].isTitle1)
        XCTAssertEqual(nil, re3[4].isTitle1)
        
    }
    /// 開發 BibleText2DText 過程，抄 test5a_dev，之前是 <h1> </h1> 現在只是換為 ( )
    /// 可以，只要是這一類的 </Fi> RF Fo 都可以抄 05a CM 不是成對的
    func test05b_dev(){
        let rr1 = "abc(bdk（jsdf（akjgioihag）aohbio）asd)asdf"
        let dtexts = [DText(rr1)]
        
        // ) 是跳脫字元
        let reg1 = try! NSRegularExpression(pattern: "\\)|）", options: [])
        func lastFit(_ rr1:String,_ minStep:Int = -1) -> [Any]?{
            // minStep 是後來加的，原本是 -1，其實沒必要1格1格往前，像 </h3> 最短也需要5字元，
            for i in stride(from: rr1.count+minStep, through: 0, by: minStep){
                let len = rr1.count - i
                let rr2 = reg1.firstMatch(in: rr1, options: [], range: NSRange(location: i, length: len))
                if ( nil != rr2){
                    let rr3a = rr2!.range(at: 0)
                    let rr3 = rr1 [ Range(rr2!.range(at: 0), in:rr1)! ]
                    return [rr3a.location,rr3]
                }
            }
            return nil
        }
        func corresponseFit(_ rr1:String, _ rrr2: [Any])->Int?{
            let tp = rrr2[1] as! Substring
            let pattern = tp == ")" ? "\\(" : "（"
            
            let reg2 = try! NSRegularExpression(pattern: pattern, options: [])
            let rr7 = reg2.firstMatch(in: rr1, options: [], range: NSRange(location: 0, length: rr1.count))
            if ( rr7 != nil ){
                return rr7!.range(at: 0).location
            } else {
                return nil
            }
        }
        func tryFit(_ rr1:String)->[Any]?{
            let rrr2 = lastFit(rr1)
            if (rrr2 != nil ){
                let rrr3 = corresponseFit(rr1, rrr2!)
                if ( rrr3 != nil ){
                    return [rrr2![0],rrr2![1],rrr3!]
                }
            }
            return nil
        }

        func splitByHeadTagOne(_ dtext: DText,_ level: Int = 0)->[DText]?{
            if (dtext.w == nil || dtext.w!.count == 0){
                return nil
            }
            let r1 = tryFit(dtext.w!)
            if ( r1 == nil ){
                return nil
            }
            
            let idx1 = r1![2] as! Int
            let idx2 = r1![0] as! Int
            let tp = r1![1] as! Substring
            
            var re: [DText] = []
            let str1 = String(ijnSubString(dtext.w!, len: idx1))
            let str2 = String(ijnSubString(dtext.w!, pos: idx1 + 1, to: idx2))
            let str3 = String(ijnSubString(dtext.w!, pos: idx2 + 1)) // ) 長度是1，所以 +1
            
            let r1a = dtext.clone()
            r1a.w = str1
            let r1b = dtext.clone()
            r1b.w = str2
            if (tp == ")"){
                r1b.isParenthesesHW = 1
            } else { // 全型
                if ( level == 0){
                    r1b.isParenthesesFW = 1
                } else {
                    r1b.isParenthesesFW2 = 1
                }
            }
            let r1c = dtext.clone()
            r1c.w = str3
            re.append(r1a)
            let r2 = splitByHeadTagOne(r1b, level + 1)
            if ( r2 == nil ){
                re.append(r1b)
            } else {
                re.append(contentsOf: r2!)
            }
            re.append(r1c)
            return re
        }
        
        func splitByHeadTags(_ dtexts:[DText])->[DText]{
            var re : [DText] = []
            for a1 in dtexts {
                let re2 = splitByHeadTagOne(a1)
                if ( re2 == nil ){
                    re.append(a1)
                } else {
                    re.append(contentsOf: re2!)
                }
            }
            return re
        }
        let re3 = splitByHeadTags(dtexts)
        
        // let rr1 = "abc(bdk（jsdf（akjgioihag）aohbio）asd)asdf"
        XCTAssertEqual(7, re3.count)
        XCTAssertEqual("abc", re3[0].w!)
        XCTAssertEqual("bdk", re3[1].w!)
        XCTAssertEqual("jsdf", re3[2].w!)
        XCTAssertEqual("akjgioihag", re3[3].w!)
        XCTAssertEqual("aohbio", re3[4].w!)
        XCTAssertEqual("asd", re3[5].w!)
        XCTAssertEqual("asdf", re3[6].w!)
        
        XCTAssertEqual(nil, re3[0].isParenthesesFW)
        XCTAssertEqual(nil, re3[6].isParenthesesFW)
        XCTAssertEqual(1, re3[1].isParenthesesHW)
        XCTAssertEqual(1, re3[5].isParenthesesHW)
        XCTAssertEqual(1, re3[2].isParenthesesHW)
        XCTAssertEqual(1, re3[4].isParenthesesHW)
        XCTAssertEqual(1, re3[2].isParenthesesFW2)
        XCTAssertEqual(1, re3[4].isParenthesesFW2)
        XCTAssertEqual(1, re3[3].isParenthesesHW)
        XCTAssertEqual(nil, re3[3].isParenthesesFW)
        XCTAssertEqual(1, re3[3].isParenthesesFW2)
    }
    /// 重構 test05a 與 05b
    func test05aa_dev(){
        let rr1 = "abc<h1>bdkjsdf<h2>akjgioihag</h2>aohbioasd</h1>asdf"
        let r1 = ssDtH1H2H3H4Title([DText(rr1)])
        XCTAssertEqual(3, r1.count)
        XCTAssertEqual("abc", r1[0].w)
        XCTAssertEqual("h1", r1[1].tpContain)
        XCTAssertEqual("asdf", r1[2].w)
        
        let r2 = r1[1].children!
        
        XCTAssertEqual("bdkjsdf", r2[0].w)
        XCTAssertEqual("h2", r2[1].tpContain)
        XCTAssertEqual("aohbioasd", r2[2].w)
        
        let r3 = r2[1].children!
        XCTAssertEqual("akjgioihag", r3[0].w)
        
    }
    func test05ba_dev(){
        let rr1 = "abc(bdk（jsdf（akjgioihag）aohbio）asd)asdf"
        let r1 = ssDtParentheses([DText(rr1)])
        XCTAssertEqual(3, r1.count)
        XCTAssertEqual("abc", r1[0].w)
        XCTAssertEqual("asdf", r1[2].w)
        XCTAssertEqual("bdk", r1[1].children![0].w)
        
    }
    func test05Bug1(){
        let rr1 = "於是領<WG71><WTG5656>他<WG846>去見<WG4314>耶穌<WG2424>。耶穌<WG2424>看見<WG1689><WTG5660>他<WG846>，說<WG3004><WTG5656>：「你<WG4771>是<WG1510><WTG5719>約翰<WG2491>的兒子<WG5207>西門<WG4613>（約翰在馬太十六章十七節稱約拿），你<WG4771>要稱為<WG2564><WTG5701>磯法<WG2786>。」(磯法{<WG3739>}翻出來<WG2059><WTG5743>就是彼得<WG4074>。)"
        let r2 = ssDtParentheses([DText(rr1)])
        
        XCTAssertEqual(4, r2.count)
        XCTAssertEqual("（）", r2[1].tpContain)
        XCTAssertEqual("()", r2[3].tpContain)
    }
}
