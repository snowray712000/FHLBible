//
//  SearchQTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/13.
//

import Foundation
import XCTest
@testable import FHLBible

class SearchQTests : XCTestCase {
    /// 讓流程能串起來
    func testDev01() throws {
        let test = XCTestExpectation()
        let r1 = DSearchParameters()
        r1.keywords = "aa"
        let iS: ISearchQ = SearchQ()
        iS.onSearchResultFinished$.addCallback { sender, pData in
            print( iS.searchResult!.datas.count )
            test.fulfill()
        }
        iS.mainAsync(r1)
        wait(for: [test], timeout: 5.0)
    }
    /// H430 G2532 摩西 (能全部出來 unv)
    func testDev02a() throws {
        let test = XCTestExpectation()
        let r1 = DSearchParameters()
        r1.vers = ["unv"]
        r1.keywords = "H430"
        let iS: ISearchQ = SearchQ()
        iS.onSearchResultFinished$.addCallback { sender, pData in
            XCTAssertEqual(2247, iS.searchResult!.datas.count)
            test.fulfill()
        }
        iS.mainAsync(r1)
        wait(for: [test], timeout: 5.0)
    }
    func testDev02b() throws {
        let test = XCTestExpectation()
        let r1 = DSearchParameters()
        r1.vers = ["unv"]
        r1.gb = nil
        r1.addr = DAddress(40,1,1)
        r1.keywords = "G2532"
        let iS: ISearchQ = SearchQ()
        iS.onSearchResultFinished$.addCallback { sender, pData in
            XCTAssertEqual(5137, iS.searchResult!.datas.count)
            test.fulfill()
        }
        iS.mainAsync(r1)
        wait(for: [test], timeout: 5.0)
    }
    func testDev02c() throws {
        let test = XCTestExpectation()
        let r1 = DSearchParameters()
        r1.vers = ["unv"]
        r1.gb = nil
        r1.addr = DAddress(40,1,1)
        r1.keywords = "摩西"
        let iS: ISearchQ = SearchQ()
        iS.onSearchResultFinished$.addCallback { sender, pData in
            XCTAssertEqual(808, iS.searchResult!.datas.count)
            test.fulfill()
        }
        iS.mainAsync(r1)
        wait(for: [test], timeout: 5.0)
    }
    
    /// Merge 當結果 DAddress[] 各版本都出來了，現在要將其合併，也就是
    func testDev03a() throws {
        /// set 練習 distinct and order
        let r1: [DAddress] = [
            DAddress(1,1,1),
            DAddress(1,1,1),
            DAddress(1,1,2),
            DAddress(1,0,1),
        ]
        
        /// Type 'DAddress' does not conform to protocol 'Hashable'
        var r2 = r1.ijnToSet()
        r2.ijnAppend(contentsOf: r1)
        let r3 = r2.sorted(by: <)
    }
    /// 計算 suggest 時要用到的邏輯，先從這測
    func testDev04a() throws {
        let r1 = BibleBookClassor._dictNa2Cnt
        // 若 thisbook 為 40
        // 若 40 這卷結果 只有 3 (小於24) 筆，則更廣
        // 這更廣的，要包含 40，但是要先將 classor 按 count 排序
        let r2 = r1.sorted { a1, a2 in
            return a1.value.count < a2.value.count
        }
        
        XCTAssertEqual(5, r2.first!.value.count)
        XCTAssertEqual("全部", r2.last!.key)
        
        for a1 in r2 {
            if a1.value.contains(40) {
                // print ( a1.key ) // 福音書、新約、全部 (正確
            }
        }
        
    }
}
