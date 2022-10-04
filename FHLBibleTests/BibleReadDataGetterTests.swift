//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest
@testable import FHLBible


/// 開發 BibleText2DText 用
class BibleText2DTextTests :XCTestCase {
    /// 很多的測試 case 在 getTestCase 中可以找到 Common/DTextTestData.swfit 中
    func test01(){
        let r1 = gBaseTest([DText("亞伯拉罕生以撒；以撒生雅各；雅各生猶大和他的弟兄；")], "太1:2","unv")
        let r2 = gBaseTest([DText("亞伯拉罕生以撒；以撒生雅各；雅各生猶大和他的弟兄；")], "太1:2","unv")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
    }
    /// replaceNewLineToBr
    func test01a(){
        let r1 = gBaseTest([DText("亞伯拉罕生以撒；以撒生雅各；"),
                            DText(isNewLine: true),
                            DText("雅各生猶大"),
                            DText(isNewLine: true),
                            DText("和他的弟兄；"),
        ], "太1:2","unv")
        let r2 = gBaseTest([DText("亞伯拉罕生以撒；以撒生雅各；\r\n雅各生猶大\n和他的弟兄；")], "太1:2","unv")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
    }
    func test02(){
        let r1 = gBaseTest ([
            DText("亞伯拉罕的後裔，大衛的子孫"),
            DText(tpContain: "）", children: [
                DText("後裔，子孫：原文是兒子；下同")
            ], isInHW: true),
            DText("，耶穌基督的家譜："),
        ], "太1:1")
        let r2 = gBaseTest([DText("亞伯拉罕的後裔，大衛的子孫（後裔，子孫：原文是兒子；下同），耶穌基督的家譜：")], "太1:1","unv")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
    }
    func test03(){
        let r1 = gBaseTest ([
            DText("亞伯拉罕"),
            DText("<G11>",sn: "11", tp: "G", tp2: "WG"),
            DText("生"),
            DText("<G1080>",sn: "1080", tp: "G", tp2: "WG"),
            DText("(G5656)",sn: "5656", tp: "G", tp2: "WTG"),
            DText("以撒"),
            DText("<G2464>",sn: "2464", tp: "G", tp2: "WG"),
            DText("；"),
            DText("{<G1161>}",sn: "1161", tp: "G", tp2: "WAG", isCurly: true),
            DText("略..."),
        ], "創1:1")

        // 下面的不是 api 真正回傳的
        let r2 = gBaseTest([DText("亞伯拉罕<WG11>生<WG1080><WTG5656>以撒<WG2464>；{<WAG1161>}略...")], "創1:1","unv")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
        
    }
    /// 要作 test03 時，先確定 regex 的用法
    func test03a_dev(){
//        let str = "亞伯拉罕<WG11>生<WG1080><WTG5656>以撒<WG2464>；{<WG1161>}略..."
        
        let str1 = "a<WG12>"
        let str2 = "a{<WG12>" // 大括號沒成對，不能被納入
        let str3 = "a<WG12>}" // 大括號沒成對，不能被納入
        
        let reg1 = try! NSRegularExpression(pattern: "\\{<(W[AT]?([G|H]))(\\d+[a-zA-Z]?)>\\}|<(W[AT]?([G|H]))(\\d+[a-zA-Z]?)>", options: [])
        let r2 = reg1.firstMatch(in: str1, options: [], range: NSRange(location: 0, length: str1.count))
        let rg = r2!.range(at: 0)
        for i in 1...6{
            let rg2 = r2!.range(at: i)
            if ( rg2.length != 0 ){
                let r4 = String(str1[Range(rg2, in:str1)!])
                print(r4)
            }
        }
        let r3 = String(str1[Range(rg, in:str1)!])
        // let reg1 = try! NSRegularExpression(pattern: "{?<WG\\d[a-z]?>}?", options: [])
    }
    func test04(){
        let r1 = gBaseTest ([
            DText("起初"),
            DText("<H9002>",sn: "9002", tp: "H", tp2: "WAH"),
            DText("<H7225>",sn: "7225", tp: "H", tp2: "WH"),
            DText("，　神"),
            DText("<H430>",sn: "430", tp: "H", tp2: "WH"),
            DText("創造"),
            DText("<H1254>",sn: "1254", tp: "H", tp2: "WH"),
            DText("(H8804)",sn: "8804", tp: "H", tp2: "WTH"),
            DText("{<H853>}",sn: "853", tp: "H", tp2: "WH", isCurly: true),
            DText("略..."),
        ], "創1:1")
    

        let r2 = gBaseTest([DText("起初<WAH09002><WH07225>，　神<WH0430>創造<WH01254><WTH8804>{<WH0853>}略...")], "創1:1", "和合本")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
    }
    func test05(){
        let r1 = gBaseTest ([
            DText(tpContain: "h3", children: [
                DText("仇敵攻擊，　神救助"),
                DText(tpContain: "）",children: [
                    DText("大衛的詩，是在逃避他兒子押沙龍時作的。"),
                    DText(tpContain:"） ）",children: [
                        DText("除特別註明外，詩篇開首細字的標題在《馬索拉抄本》都屬於第1節，原文的第2節即是譯文的第1節，依次類推。")
                    ], isInHW: true),
                    DText(" "),
                ],isInHW: true),
            ], isInTitle: true),
            DText("耶和華啊！我的仇敵竟然這麼多。起來攻擊我的竟然那麼多。"),
        ], "詩3:1", "新譯本")

        // w    String?    "<h3>仇敵攻擊，　神救助（大衛的詩，是在逃避他兒子押沙龍時作的。（除特別註明外，詩篇開首細字的標題在《馬索拉抄本》都屬於第1節，原文的第2節即是譯文的第1節，依次類推。） ）</h3>耶和華啊！我的仇敵竟然這麼多。起來攻擊我的竟然那麼多。"    some
        let r2 = gBaseTest([DText("<h3>仇敵攻擊，　神救助（大衛的詩，是在逃避他兒子押沙龍時作的。（除特別註明外，詩篇開首細字的標題在《馬索拉抄本》都屬於第1節，原文的第2節即是譯文的第1節，依次類推。） ）</h3>耶和華啊！我的仇敵竟然這麼多。起來攻擊我的竟然那麼多。")], "詩3:1","新譯本")
        let r3 = BibleText2DText().main([r2],"unv")
        XCTAssertTrue( isTheSameDTexts(r1.children!, r3[0].children!) )
    }
}


class BibleGetterViaFhlApiQsbTests : XCTestCase {
    /// 讓基本能跑，測試 protocol 樣本的正確性
    /// 最主要 protocol 有
    /// 1. 將 qsb 的結果, 轉為 DOneLine
    /// 2. 版本轉換，即 "和合本" "新譯本" to unv 等概念
    /// 3. 取得經文資料 ( a. 透過 api, b. 透過 local file)
    func testBasic01(){
        let test = XCTestExpectation()
        
        
        let dataQ = BibleGetterViaFhlApiQsb()
        dataQ.queryAsync("新譯本", "詩3:1", { a2 in
            print(a2)
            test.fulfill()
        })
        
        wait(for: [test], timeout: 15.0)
    }
}


class BibleReadDataGetterTests : XCTestCase {
    /// 讓基本能跑，測試 protocol 樣本的正確性
    /// 最主要 protocol 有
    /// 1. 將 qsb 的結果, 轉為 DOneLine
    /// 2. 版本轉換，即 "和合本" "新譯本" to unv 等概念
    /// 3. 取得經文資料 ( a. 透過 api, b. 透過 local file)
    func testBasic01(){
        let test = XCTestExpectation()
        
        BibleReadDataGetter().queryAsync(["和合本","新譯本"], "創1:3-5", { vers, datas in
            XCTAssertEqual(2, vers.count)
            XCTAssertEqual("和合本", vers[0].children![0].w)
            
            XCTAssertEqual(3, datas.count) // 3 節
            XCTAssertEqual(2, datas[0].count) // 1 節，有 "2" 個版本
            
            
            test.fulfill()
        })
        
        wait(for: [test], timeout: 15.0)
    }
    /// demo 當時設計，是怎麼決定來源的
    func testBasic02(){
        DataGetter02().getDataAndTriggerCompletedEvent("羅1:2", ["和合本","新譯本"])
    }
    class DataGetter02 : IDataGetter {
        typealias c = DataGetter02
        var ev = IjnEventOnce<c,DataGetterEventData>()
        var pfn : ((_ ev: DataGetterEventData?)->Void)?
        
        func addEventCallbackWhenCompleted(_ fn:  @escaping (_ ev: DataGetterEventData?)->Void) {
            ev.addCallback({ r1, r2 in
                fn(r2)
            })
        }
        func getDataAndTriggerCompletedEvent(_ addr: String, _ vers: [String]) {
            
            BibleReadDataGetter().queryAsync(vers, addr, { vers, datas in
                self.ev.triggerAndCleanCallback (self, DataGetterEventData(vers, datas))
            })
        }
    }
    func testBasic03(){
        DataGetterUsingBibleReader().getDataAndTriggerCompletedEvent("羅1:2", ["和合本","新譯本"])
    }
}
