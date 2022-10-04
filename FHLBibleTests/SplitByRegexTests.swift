//
//  SplitByRegexTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/6/24.
//

import Foundation
import XCTest
@testable import FHLBible

class SplitByRegexTests : XCTestCase {
    /// 基本分割，還沒有用到 capture
    func testBasic01(){
        let reg = try! NSRegularExpression(pattern: "羅|太", options: [])
        let re = SplitByRegex().main(str: "羅2:1太3:4", reg: reg)
        XCTAssert( 4 == re!.count)
        
        XCTAssert( re![0].isMatch() )
        XCTAssert( "羅" == re![0].w )
        
        XCTAssert( !re![1].isMatch() )
        XCTAssert( "2:1" == re![1].w )
        
        XCTAssert( re![2].isMatch() )
        XCTAssert( "太" == re![2].w )
        
        XCTAssert( !re![3].isMatch() )
        XCTAssert( "3:4" == re![3].w )
    }
    /// 第1個是符合、第1個不符合、結尾符合、結尾不符合
    func testBasic02(){
        let reg = try! NSRegularExpression(pattern: "羅|太", options: [])
        
        // 頭不符
        var re = SplitByRegex().main(str: "3:4羅2:1太3:4", reg: reg)
        XCTAssert( 5 == re!.count)
        XCTAssert( false == re![0].isMatch())
        
        // 頭相符
        re = SplitByRegex().main(str: "羅2:1太3:4", reg: reg)
        XCTAssert( 4 == re!.count)
        XCTAssert( true == re![0].isMatch())
        
        // 尾不符
        XCTAssert( false == re![3].isMatch() )
        
        // 尾相符
        re = SplitByRegex().main(str: "羅2:1太", reg: reg)
        XCTAssert( 3 == re!.count)
        XCTAssert( true == re![2].isMatch() )
    }
    /// 用到 capture 資訊
    func testBasic03(){
        let reg = try! NSRegularExpression(pattern: "(G|H)\\d+", options: [])
        let re = SplitByRegex().main(str: "G1512、H521", reg: reg)
        
        XCTAssert( re != nil )
        XCTAssert( re![0].exec[1] == "G" )
        XCTAssert( re![1].w == "、" )
        XCTAssert( re![2].exec[1] == "H" )
    }
}
