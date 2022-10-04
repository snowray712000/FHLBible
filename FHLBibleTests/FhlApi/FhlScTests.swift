//
//  FHLScTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/10.
//

import XCTest
@testable import FHLBible

class FhlScTests: XCTestCase {
    /// 確定 fhlSc 可呼叫，並且透過 debug 看 data 大概長什麼樣子
    func test01() throws {
        let test = XCTestExpectation()
        fhlSc("book=4&engs=Gen&gb=0&chap=2&sec=1") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    func test02a() throws {
        let test = XCTestExpectation()
        fhlSc("book=4&engs=Gen&gb=0&chap=2&sec=1") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }

}
