//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest
@testable import FHLBible


/// fhlqsb function Test
class FhlQsbTests : XCTestCase {
    /// 熟悉 swift 的 api 核心
    /// 熟悉 swift unit test async 時的作法 , 注意, throws 必須要有
    /// 熟悉 fhl api qsb.php 的參數
    func testBasic01() throws {
        let url = URL(string: "https://bible.fhl.net/json/qsb.php")!
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        
        let qstr = "qstr=Ge1:3-5"
        // var qstr = ""
        let data = qstr.data(using: .utf8)!
        req.httpMethod = "POST"
        req.httpBody = data
        
        let expectation = XCTestExpectation(description: "Download apple.com home page")
            
        let r1 = URLSession.shared.dataTask(with: req, completionHandler: { data, resp, error in
            
            XCTAssertNotNil( data )
            
            // Swfit 直接從 Byte 轉到 Json 了
            let _ = String(data: data!, encoding: .utf8)
            
            do {
                let r13: DApiQsb = try JSONDecoder().decode(DApiQsb.self, from: data!)                
                XCTAssert( r13.record.count == 3)
            }catch{
                XCTAssert( false )
            }
            
            expectation.fulfill()
        })
        r1.resume()
        
        wait(for: [expectation], timeout: 3.0)
    }
    /// 測試 FhlJson 工具
    /// 過程發現 Decodable 結合 class 繼承時，並不容易
    /// 產生了一個小函式 fhlQsb
    func testBasic02() throws {
        let reTestAsync = XCTestExpectation(description: "FHL Api call async")
        
        FhlJson<DApiQsb>().postAsync({ a1 in
            XCTAssertEqual(true, a1.isSuccess())
            XCTAssert( 3 == a1.record.count )
            reTestAsync.fulfill()
        }, "https://bible.fhl.net/json/qsb.php", "qstr=Ge1:3-5")
        
        wait(for: [reTestAsync], timeout: 3.0)
    }
    /// 測 fhlqsb
    func testBasic03() throws {
        let test = XCTestExpectation()

        fhlQsb("qstr=Ge1:3-5", { a1 in
            XCTAssertEqual(true, a1.isSuccess())
            XCTAssert( 3 == a1.record.count )
            test.fulfill()
        })
        
        wait(for: [test], timeout: 5.0)
    }
    /// 測試 strong=1
    /// 注意, 若只加 strong=1 沒加 version=unv, 會得不到 sn
    func testSN01() throws {
        let reTestAsync = XCTestExpectation(description: "FHL Api call async")
        
        // test1
        fhlQsb("version=unv&strong=1&qstr=Ge1:3") { (re: DApiQsb) in
            XCTAssertEqual(true, re.isSuccess())
            
            XCTAssertEqual("　神<WH0430>說<WH0559><WTH8799>：「要有<WH01961><WTH8799>光<WH0216>」，就有了<WAH01961><WTH8799>光<WH0216>。", re.record[0].bible_text)
            
            // test2
            fhlQsb("version=unv&strong=0&qstr=Ge1:3", { re2 in
                
                XCTAssertEqual("　神說：「要有光」，就有了光。", re2.record[0].bible_text)
                
                reTestAsync.fulfill()
            })
        }
        
        wait(for: [reTestAsync], timeout: 3.0)
    }
    /// 測試 gb=1
    func testGB01() throws {
        
        let test = XCTestExpectation()
        
        fhlQsb("qstr=Ge1:3&gb=1", { re1 in
            XCTAssertEqual("神说：「要有光」，就有了光。", re1.record[0].bible_text)
            // bible_text    String    "神说：「要有光」，就有了光。"
            fhlQsb("qstr=Ge1:3&gb=0", { re2 in
                XCTAssertEqual("神說：「要有光」，就有了光。", re2.record[0].bible_text)
                test.fulfill()
            })
        })
        
        wait(for: [test], timeout: 5)
        
    }
    /// 當2個版本同時取得時
    func testWaitAllAsync01() throws {
        let testor = XCTestExpectation()
        
        let gp = DispatchGroup()
        gp.enter() // 第1個
        fhlQsb("qstr=Ge1:3", { re1 in
            gp.leave()
        })
        gp.enter() // 第2個
        fhlQsb("qstr=Ge1:4", { re1 in
            gp.leave()
        })
        
        gp.notify(queue: .main){
            XCTAssert(true)
            testor.fulfill()
        }
        
        wait(for: [testor], timeout: 5.0)
        
        /// http://www.tastones.com/zh-tw/stackoverflow/ios/dispatchgroup/introduction/
    }
}
