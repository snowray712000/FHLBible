//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest

@testable import FHLBible



class LinqTests : XCTestCase {
    func testRange01() throws {
        XCTAssert( [0,1,2,3,4,5] == ijnRange(0, 6) )
        XCTAssert( [1,2,3,4,5] == ijnRange(1, 5) )
        XCTAssert( [0,2,4] == ijnRange(0, 3, 2) )
        XCTAssert( [0,-2,-4] == ijnRange(0, 3, -2) )
    }
}


