//
//  SQLSelectBibleTextGeneratorTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2022/10/21.
//

import Foundation
import XCTest

@testable import FHLBible

class SQLSelectBibleCommentsGeneratorTests : XCTestCase {
    func test01_123() throws {
        // -- book=1, chap=2, sec=3 case
        // SELECT * FROM comment2 WHERE tag=3 and book=1 and
        // ( (bchap=echap and bchap=2 and bsec<=3 and esec>=3) or
        // (bchap<echap and ((bchap=2 and bsec<=3)or (echap=2 and esec>=3) or (bchap<2 and echap>2)))) LIMIT 1;

        let re = "SELECT * FROM comment2 WHERE tag=3 AND book=1 AND ((bchap=echap AND bchap=2 AND bsec<=3 AND esec>=3) OR (bchap<echap AND ((bchap=2 AND bsec<=3) OR (echap=2 AND esec>=3) OR (bchap<2 AND echap>2)))) LIMIT 1;"
        
        let re2 = SQLSelectBibleCommentsGenerator().main(address: DAddress(1,2,3), tag: 3, cntLimit: 1)
        XCTAssert( re == re2)
    }
}
