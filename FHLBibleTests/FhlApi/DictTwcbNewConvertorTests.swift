//
//  FHLScTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/10.
//

import XCTest
@testable import FHLBible

class DictTwcbNewConvertorTests: XCTestCase {
    // 測試 reg 處理換行的能力
    func testDev01a() throws{
        let r1 = "。\r\n<div class=\"idt\">一、實名詞：\r\n<div class=\"idt\">A. 一般用法：\r\n<div class=\"idt\">1. 論及此處和現在的某事物，#太24:21|。</div>\r\nB. 帶現在假設，#來13:5|。</div></div>\r\n"
        print(r1)
        
        let r2 = SplitByRegex().main(str: r1, reg: try! NSRegularExpression(pattern: #"<div class=\"idt\">|<\/div>"#, options: []))
        for a1 in r2! {
            if a1.isMatch() {
                // 3 28 55 96 121 127
                print (a1.index.first!)
                // 17 17 17 6 6 6
                print (a1.length.first!)
                print (a1.w)
            } else {
                print (a1.w)
            }
        }
    }
    func testDev02() throws{
        // 最後一個是多的，要忽略
        let r1 = "aa<div>bb<div>cc</div>ddee<div>ff<div>gg</div></div>tt</div>55"
        let r2 = DevUname02().main(r1)
        // [aa, [bb, [cc], ddee, [ff, [gg]], tt], 55]
        XCTAssertEqual(3, r2.count)
        XCTAssertEqual(5, r2[1].children!.count)
    }
    func testDev02b() throws{
        // 最後2 /div 個是多的，要忽略
        let r1 = "aa<div>bb<div>cc</div>ddee<div>ff<div>gg</div></div>tt</div>55</div></div>66"
        let r2 = DevUname02().main(r1)
        // [aa, [bb, [cc], ddee, [ff, [gg]], tt], 55, 66]
        XCTAssertEqual(4, r2.count)
    }
    func testDev02c() throws{
        // 不足 2個 /div
        let r1 = "aa<div>bb<div>cc</div>ddee<div>ff<div>gg</div>"
        let r2 = DevUname02().main(r1)
        // [aa, [bb, [cc], ddee, [ff, [gg]]]]
        XCTAssertEqual(2, r2.count)
    }
    /// SplitStringDivIdt
    func testDev03a() throws{
        let r1 = "。\r\n<div class=\"idt\">一、實名詞：\r\n<div class=\"idt\">A. 一般用法：\r\n<div class=\"idt\">1. 論及此處和現在的某事物，#太24:21|。</div>\r\nB. 帶現在假設，#來13:5|。</div></div>\r\n"
        let r2 = doDivIdt([DText(r1)])
        //let r2 = SSDivIdt().main(DText(r1))!
        XCTAssertEqual(r2.count, 3)
        XCTAssertEqual(r2[0].w!, "。\r\n")
        let r3 = r2[1].children!
        XCTAssertEqual(r3.count, 2)
    }
    func testDev04a() throws {
        let r1 = "asdb\r\ncdef\nafjio\r\n"
        let r3 = DictTwcbNewConvertor().main(r1)
        XCTAssertEqual(r3.count, 6)
        r3.forEach({$0.printDebug()})
    }
    func testDev04ab() throws {
        let r1 = "一、實名詞：\r\n"
        let r3 = DictTwcbNewConvertor().main(r1)
        r3.forEach({$0.printDebug()})
    }
    func testDev04ac() throws {
        let r1 = "<div class=\"idt\">一、實名詞：\r\n"
        let r3 = DictTwcbNewConvertor().main(r1)
        r3.forEach({$0.printDebug()})
    }
    
    func testDev04b() throws {
        let r1 = "。\r\n<div class=\"idt\">一、實名詞：\r\n<div class=\"idt\">A. 一般用法：\r\n<div class=\"idt\">1. 論及此處和現在的某事物，#太24:21|。</div>\r\nB. 帶現在假設，#來13:5|。</div></div>\r\n"
        let r3 = DictTwcbNewConvertor().main(r1)
        r3.forEach({$0.printDebug()})
        XCTAssertEqual(r3.count, 4)
    }
    func testDev04ba() throws {
        let r1 = "事物，#太24:21|。"
        let r2 = SplitByRegex().main(str: r1, reg: try! NSRegularExpression(pattern: #"#[^\|]+\|"#, options: []))
        XCTAssertEqual(8, r2![1].length.first)
        XCTAssertEqual(3, r2![1].index.first)
        
        //let r3 = DictTwcbNewConvertor().main(r1)
        //r3.forEach({$0.printDebug()})
    }
    func testDev5a() throws {
        let r1 = "aa(bb)c(dd(ee)ff(gg)hh)"
        let r2 = DictTwcbNewConvertor().main(r1)
        XCTAssertEqual(r2.count, 4)
    }
    func testDev6a() throws {
        let r1 = "μή 否定質詞"
        let r2 = DictTwcbNewConvertor().main(r1)
        r2.forEach({$0.printDebug()})
    }
}
/// 保持開發原樣，現在要另外作泛用的了
/// 凡成對出現的, 都可以用 ( ) 或 <div> </div>
fileprivate class DevUname02{
    
    func main(_ str:String)->[DText]{
        self.reg = gRegexp()
        let r1 = SplitByRegex().main(str: str, reg: reg)
        // no match, default return
        if r1 == nil { return [DText(str)] }
        
        for a1 in r1! {
            if false == a1.isMatch() {
                pushToLastContain(gD(a1.w))
            } else {
                // print (a1.length)
                if isFront(a1) {
                    pushConAndAddDp()
                } else {
                    popLastCon(a1)
                }
            }
        }
        
        makeSureContainOnlyOne()
        return container[0]
    }
    // override
    func isFront(_ a1: SplitByRegexOneResult)->Bool{
        return a1.length.first! == 5
    }
    // override
    func gRegexp()->NSRegularExpression{
        return try! NSRegularExpression(pattern: #"<div>|</div>"#, options: [])
    }
    /// override, 當一個 </div> 來到時, 它會結算一個 array
    /// 此時，你要產生 Dtext，首先，將傳來的參數，設為  children
    /// 其次，你設定它的其它參數
    func gDTextContain(_ dtexts:[DText],_ a1:SplitByRegexOneResult?)->DText{
        let r = DText()
        r.children = dtexts
        r.tpContain = "div"
        r.cssClass = "idt"
        return r
    }
    private var dp = 0
    /// 第1個就是最底層
    private var container: [[DText]] = [[]]
    private func pushToLastContain(_ d:DText){
        container[container.endIndex-1].append(d)
    }
    private func pushConAndAddDp(){
        container.append([])
        dp = dp + 1
    }
    /// a1 通常沒用到，表示結尾的 </div>
    /// 也有可能是 nil, 例如, 沒有成對的 case </div>
    private func popLastCon(_ a1: SplitByRegexOneResult?){
        if dp > 0 {
            let r1 = container.popLast()
            let r2 = gDTextContain(r1!, a1)
            pushToLastContain(r2)
            dp = dp - 1
        }
    }
    /// 若 div /div 沒成對，也就是 /div 少了, 最終的時候, 要把它 push 乾淨
    private func makeSureContainOnlyOne(){
        while dp > 0 {
            popLastCon(nil)
        }
    }
    private func gD(_ s:Substring)->DText{ DText(String(s)) }
    private var reg: NSRegularExpression!
                            
}
