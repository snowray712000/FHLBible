//
//  FHLBibleTests.swift
//  FHLBibleTests
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import XCTest
@testable import FHLBible

class FHLFtpTests: XCTestCase {
    var ftpUrlPrefix = "https://ftp.fhl.net/FHL/COBS/data/"
    func test01a() throws {
        let test = XCTestExpectation()
        
        let r1 = "https://ftp.fhl.net/FHL/COBS/data/version"
        let r2 = URLSession.shared.dataTask(with: URL(string: r1)! ) { data, resp, er in
            test.fulfill() // okay
        }
        r2.resume()
        
        wait(for: [test], timeout: 5.0)
    }
    
    // 將 data 顯示為文字
    func test01b() throws {
        let test = XCTestExpectation()
        
        let r1 = ftpUrlPrefix + "version"
        let r2 = URLSession.shared.dataTask(with: URL(string: r1)! ) { data, resp, er in
            if data != nil {
                print (data?.count)
                let r1 = String(bytes: data!, encoding: .utf8)!
                print (r1)
                test.fulfill() // okay
            }
        }
        r2.resume()
        
        wait(for: [test], timeout: 5.0)
    }
    func test02a() throws {
        let test = XCTestExpectation()
        
        let r1 = "https://bkbible.fhl.net/NUI/ios/ios-futures.json"
        let r2 = URLSession.shared.dataTask(with: URL(string: r1)! ) { data, resp, er in
            let r1 = String(bytes: data!, encoding: .utf8)
            print (r1)
            test.fulfill() // okay
        }
        r2.resume()
        
        wait(for: [test], timeout: 5.0)
    }
}
