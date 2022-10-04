//
//  RegexTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/6/23.
//

import Foundation
import XCTest
@testable import FHLBible

/// 測試完成 2021 06 19
class VerseRangeToStringTests : XCTestCase {
    func testBasic() throws {
        // a1 可能是 1:23 (a1.length===1) (a1[0].length==1)
        // a1 可能是 1:23-25 (a1.length===1) (a1[0].length>1 && a1[0].first().chap == a1[0].last().chap)
        // a1 可能是 1:23,25-27,30,32-42 (a1.length===4)
        // a1 可能是 1:23-2:2 (a1.length===1) (a1[0].length>1 && a1[0].first().chap != a1[0].last().chap)
        // 第2種情況，可能縮成整章可能...約二 case (但qsb.php實際上, 約二, 會錯誤, 還是要傳入 約二1)
        var r1: [DAddress] = []
        func av(_ v:Int = 0,_ c:Int = 1 ,_ b:Int = 1){
            r1.append(DAddress(book: b, chap: c, verse: v, ver: nil))
        }
        
        [23].forEach(({av($0)}))
        XCTAssert("創1:23" == VerseRangeToString().main(r1, .太))

        r1.removeAll()
        (23..<26).forEach(({av($0)}))
        XCTAssert("創1:23-25" == VerseRangeToString().main(r1, .太))
        
        r1.removeAll()
        [23,25,26,27,30].forEach(({av($0)}))
        (32..<43).forEach({av($0)})
        XCTAssert("創1:23,25-27,30,32-42" == VerseRangeToString().main(r1, .太))
        
        r1.removeAll()
        (23..<32).forEach({av($0)})
        (1..<3).forEach({av($0,2)})
        XCTAssert("創1:23-2:2" == VerseRangeToString().main(r1, .太))
        
    }
}
