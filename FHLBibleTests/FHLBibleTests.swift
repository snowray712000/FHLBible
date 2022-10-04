//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest
@testable import FHLBible

open class ParsingReferenceDescription {
    public func main(_ strDescription: String, defaultAddress: (book: Int,chap: Int)?) -> VerseRange {
        abort()
    }
}

class BibleGetNextOrPrevChapTests: XCTestCase {
    func testBasic() throws {
        typealias NP = BibleGetNextOrPrevChap
        
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:1))!.verses[0].book == 1)
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:1))!.verses[0].chap == 2)
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:1))!.verses.count == BibleVerseCount.getVerseCount( 1, 2))
        
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:50))!.verses[0].book == 2)
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:50))!.verses[0].chap == 1)
        XCTAssert(NP.getNextChap(DAddress(book:1,chap:50))!.verses.count == BibleVerseCount.getVerseCount( 2, 1))
        
        XCTAssert(NP.getNextChap(DAddress(book:66,chap:22)) == nil)
        
        XCTAssert(NP.getPrevChap(DAddress(book:1,chap:2))!.verses[0].book == 1)
        XCTAssert(NP.getPrevChap(DAddress(book:1,chap:2))!.verses[0].chap == 1)
        XCTAssert(NP.getPrevChap(DAddress(book:1,chap:2))!.verses.count == BibleVerseCount.getVerseCount( 1,  1))
        
        XCTAssert(NP.getPrevChap(DAddress(book:2,chap:1))!.verses[0].book == 1)
        XCTAssert(NP.getPrevChap(DAddress(book:2,chap:1))!.verses[0].chap == 50)
        XCTAssert(NP.getPrevChap(DAddress(book:2,chap:1))!.verses.count == BibleVerseCount.getVerseCount(1, 50))
        
        XCTAssert(NP.getPrevChap(DAddress(book:1,chap:1)) == nil)
    }
    func testBasicInStr() throws {
        typealias NP = BibleGetNextOrPrevChap
        
        XCTAssert(NP.getNextChapInStr("創1") == "創2")
        XCTAssert(NP.getNextChapInStr("瑪4") == "太1")
        XCTAssert(NP.getNextChapInStr("太28") == "可1")
        XCTAssert(NP.getNextChapInStr("啟22") == nil)
        
        XCTAssert(NP.getPrevChapInStr("創2") == "創1")
        XCTAssert(NP.getPrevChapInStr("太1") == "瑪4")
        XCTAssert(NP.getPrevChapInStr("可1") == "太28")
        XCTAssert(NP.getPrevChapInStr("創1") == nil)
    }
}


class FHLBibleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
