//
//  SQLSelectBibleTextGeneratorTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2022/10/21.
//

import Foundation
import XCTest

@testable import FHLBible

class SQLSelectBibleTextGeneratorTests : XCTestCase {
    func testSelect01_Mt_chap10_1() throws {
        // -- 太 10:1
        // select * from nstrunv2 where book=40 and chap=10 and sec=1;
        var r1: [DAddress] = []
        r1.append(DAddress(40,10,1))
        
        let re = "select * from nstrunv2 where (book=40 and ((chap=10 and (sec=1))));"
        let re2 = SQLSelectBibleTextGenerator().main(addresses: r1, nameOfTable: "nstrunv2")
        XCTAssert( re == re2)
    }
    func testSelect02_Mt_chap1_1to5() throws {
        // -- Mt 1:1-5
        let r1 = ijnRange(1,5).map({DAddress(40,1,$0)})
        let re = "select * from nstrunv2 where (book=40 and ((chap=1 and ((sec>=1 and sec<=5)))));"
        let re2 = SQLSelectBibleTextGenerator().main(
            addresses: r1,
            nameOfTable: "nstrunv2")
        XCTAssert( re == re2)
    }
    func testSelect03_Mt_chap1_multiVerse() throws {
        //Mt 1:1,4-6,8,10
        var addrs = from([1,4,5,6,8,10]).select({DAddress(40,1,$0)}).toArray()
        let re = "select * from nstrunv2 where (book=40 and ((chap=1 and (sec=1 or (sec>=4 and sec<=6) or sec=8 or sec=10))));"
        let re2 = SQLSelectBibleTextGenerator().main(addresses: addrs, nameOfTable: "nstrunv2")
        XCTAssert(re == re2)
        
        //Mt 1:4,6,8-10 (最後是連續的，看會不會對)
        addrs = from([4,6,8,9,10]).select({DAddress(40,1,$0)}).toArray()
        let re3 = "select * from nstrunv2 where (book=40 and ((chap=1 and (sec=4 or sec=6 or (sec>=8 and sec<=10)))));"
        let re4 = SQLSelectBibleTextGenerator().main(addresses: addrs, nameOfTable: "nstrunv2")
        XCTAssert(re3 == re4)
    }
    func testSelect04_Mt_MultiChap() throws {
        // Mt 1:2-3:5
        var addrs = from( ijnRange(2, 24) )
            .select({DAddress(40,1,$0)}).toArray()
        addrs.append(contentsOf: from(ijnRange(1, 23)) .select({DAddress(40,2,$0)}).toArray())
        addrs.append(contentsOf: from(ijnRange(1, 5)) .select({DAddress(40,3,$0)}).toArray())
        
        let re = "select * from nstrunv2 where (book=40 and ((chap=1 and ((sec>=2 and sec<=25))) or (chap=2 and ((sec>=1 and sec<=23))) or (chap=3 and ((sec>=1 and sec<=5)))));"
        let re2 = SQLSelectBibleTextGenerator().main(addresses: addrs, nameOfTable: "nstrunv2")
        XCTAssert(re == re2)
    }
    func testSelect05_MultiBook() throws {
        // Ge 21:2-5; Jos 24:2,3;
        // Ge: book = 1, Jos: book = 6
        var addrs = from( ijnRange(2, 4) )
            .select({DAddress(1,21,$0)}).toArray()
        addrs.append(contentsOf: from(ijnRange(2, 2)) .select({DAddress(6,24,$0)}).toArray())
        
        let re = "select * from nstrunv2 where (book=1 and ((chap=21 and ((sec>=2 and sec<=5))))) or (book=6 and ((chap=24 and ((sec>=2 and sec<=3)))));"
        let re2 = SQLSelectBibleTextGenerator().main(addresses: addrs, nameOfTable: "nstrunv2")
        XCTAssert(re == re2)
    }
    func testSelect01a_CombineStringToVerseRange() throws {
        let r1 = StringToVerseRange().main("太 10:1", nil)
        let re = "select * from nstrunv2 where (book=40 and ((chap=10 and (sec=1))));"
        let re2 = SQLSelectBibleTextGenerator().main(addresses: r1, nameOfTable: "nstrunv2")
        XCTAssert( re == re2)
    }
}
