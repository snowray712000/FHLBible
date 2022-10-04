//
//  FHLScTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/10.
//

import XCTest
@testable import FHLBible

class FhlSeTests: XCTestCase {
    /// H430
    func test01() throws {
        let test = XCTestExpectation()
        fhlSe("index_only=1&limit=500&offset=0&orig=2&RANGE=2&q=430") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    ///
    func test02() throws {
        let test = XCTestExpectation()
        fhlSe("orig=0&VERSION=unv&index_only=1&limit=500&offset=0&q=摩西&gb=0") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    func test03() throws {
        let test = XCTestExpectation()
        fhlSe("orig=0&VERSION=unv&index_only=1&limit=500&offset=0&q=摩西 亞倫&gb=0") { data in
            if data.isSuccess() {
                test.fulfill() // okay
            }
        }
        wait(for: [test], timeout: 5.0)
    }
}
