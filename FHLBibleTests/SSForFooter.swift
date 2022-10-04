//
//  SSForFooter.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/23.
//

import XCTest

@testable import FHLBible

/// 注腳 開發過程的測試
/// 尤其是注腳內容中的 交互參照
/// 因為它不是 # | 格式，而寫的較隨意，所以相對較難
class SSForFooterTests : XCTestCase {
    func test_dev01a() throws {
        func g1(_ idx:Int,_ isA: Bool)->DText{
            let r1 = DText("\(idx)")
            if isA { r1.refDescription = "a" }
            return r1
        }
        
        func gTestCase()->[DText]{
            let r1 = [3,4,7,8,9,12]
            let r2 = ijnRange(0, 14).map({g1($0, r1.contains($0))})
            return r2
        }
        
        let r1 = gTestCase()
        
        // step1
        let r2 = ijnRange(0, r1.count).filter({r1[$0].refDescription == "a"})
        XCTAssertEqual(r2, [3,4,7,8,9,12])
        
        // step2
        var r3 :[Int:[Int]] = {
            var r1 = [Int:[Int]]()
            
            var t1 = -2
            var t2 = -1 // key
            for a1 in r2 {
                if t1 + 1 != a1 {
                    r1[a1] = [a1]
                    t1 = a1
                    t2 = a1
                } else {
                    r1[t2]!.append(a1)
                    t1 = a1
                }
            }
            
            return r1
        }()
        XCTAssertEqual(r3[3], [3,4])
        XCTAssertEqual(r3[7], [7,8,9])
        XCTAssertEqual(r3[12], [12])
        
        // step3 last
        var re: [DText] = []
        var r2b: [Int] = [] // pass this, 例如會是 [3,4] [7,8,9] [12]
        for i in 0..<r1.count {
            if  r2b.contains(i) { continue }
            
            let r2 = r3[i]
            if r2 == nil {
                re.append(r1[i])
            } else {
                r2b = r2! // [3,4]
                let wNew = ijnRange(r2b.first!, r2b.count).map({r1[$0].w!}).joined(separator: "")
                let dNew = r1[i].clone()
                dNew.w = wNew
                re.append(dNew)
            }
        }
        
        XCTAssertEqual(re.count, 11)
        XCTAssertEqual(re[3].w!, "34")
        XCTAssertEqual(re[6].w!, "789")
        XCTAssertEqual(re[9].w!, "12")
        XCTAssertEqual(re[10].w!, "13")
    }
}
