//
//  RegexTests.swift
//  FHLBibleTests


import Foundation
import XCTest
@testable import FHLBible
import IJNSwift

class SNParsingOfflineTests : XCTestCase {
    func testBasic01(){
        var tests: [DApiQpRecord] = []
        tests.append(g1("n","nsf")) // 馬可1:1
        tests.append(g1("ra","gsn"))
        tests.append(g1("n","gsn"))
        tests.append(g1("n","gsm"))
        tests.append(g1("c","")) // 馬可1:2
        tests.append(g1("v","dpi3s"))
        tests.append(g1("p",""))
        tests.append(g1("ra","dsm"))
        tests.append(g1("n","dsm"))
        tests.append(g1("t",""))
        tests.append(g1("v","pai1s"))
        
        let results: [String] = [
            "名詞 主格 單數 陰性",
            "冠詞 所有格 單數 中性",
            "名詞 所有格 單數 中性",
            "名詞 所有格 單數 陽性",
            "連接詞",
            "動詞 完成 被動 直說語氣 第三人稱 單數",
            "介系詞",
            "冠詞 間接受格 單數 陽性",
            "名詞 間接受格 單數 陽性",
            "質詞",
            "動詞 現在 主動 直說語氣 第一人稱 單數",
        ]
        
        for (i,a1) in tests.enumerated() {
            let re = SNParsingDealProXForm().main(a1.pro!,a1.wform!)
            let re2 = [re.0,re.1].filter({!$0.isEmpty}) .joined(separator: " ")
            XCTAssert( re2 == results[i])
        }
    }
    private func g1(_ pro:String,_ wform: String)->DApiQpRecord{
        let re = DApiQpRecord()
        re.pro = pro
        re.wform = wform
        return re
    }
}

