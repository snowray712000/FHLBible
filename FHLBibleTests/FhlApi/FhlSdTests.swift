//
//  FHLScTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/10.
//

import XCTest
@testable import FHLBible

class FhlSdTests: XCTestCase {
    /// 確定 fhlSd 可呼叫，並且透過 debug 看 data 大概長什麼樣子
    func test01() throws {
        let test = XCTestExpectation()
        fhlSd("k=3615&gb=0&N=1") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    /// 新約的部分 cbol
    func test02a() throws {
        let test = XCTestExpectation()
        fhlSd("k=21&gb=1&N=0") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    func test03a() throws {
        let test = XCTestExpectation()
        fhlStwcbhdic("k=3616&gb=0&N=1", { data in
             if data.isSuccess() {
                test.fulfill() // okay
            }
        })
        
        wait(for: [test], timeout: 5.0)
    }
}
