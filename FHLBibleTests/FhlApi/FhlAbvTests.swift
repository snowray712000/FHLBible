//
//  FHLScTests.swift
//  FHLBibleTests
//
//  Created by littlesnow on 2021/11/10.
//

import XCTest
@testable import FHLBible

class FhlAbvTests: XCTestCase {

    func test01a() throws {
        let test = XCTestExpectation()
        fhlUiabv("") { data in
            if data.isSuccess() {
                test.fulfill() // okay
                
                print (data.isSuccess()) // true
                print (data.parsing) // Optional("2021/11/25 05:50:36")
                print (data.comment) // Optional("2021/11/25 05:53:08")
                print (data.getComment()) // Optional(2021-11-24 21:53:08 +0000)
                print (data.getParsing()) // Optional(2021-11-24 21:50:36 +0000)
                
                let a1 = data.record!.first!
                print (a1.book) // unv
                print (a1.cname) // Optional("和合本")
                print (a1.getVersion()) // Optional(2021-11-24 21:50:02 +0000)
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    func test01b() throws {
        let test = XCTestExpectation()
        fhlUiabv("gb=1") { data in
            if data.isSuccess() {
                test.fulfill() // okay
                
                print (data.isSuccess()) // true
                print (data.parsing) // Optional("2021/11/25 05:50:36")
                print (data.comment) // Optional("2021/11/25 05:53:08")
                print (data.getComment()) // Optional(2021-11-24 21:53:08 +0000)
                print (data.getParsing()) // Optional(2021-11-24 21:50:36 +0000)
                
                let a1 = data.record!.first!
                print (a1.book) // unv
                print (a1.cname) // Optional("和合本")
                print (a1.getVersion()) // Optional(2021-11-24 21:50:02 +0000)
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    func test01() throws {
        let test = XCTestExpectation()
        testThenDoAsync({AutoLoadDUiabv.s.record.count != 0}, {
            test.fulfill()
        }, "wait auto uiabiv, in tests")
        wait(for: [test], timeout: 5.0)
    }

    /// 成功 select 資料
    func test02a() throws {
        let test = XCTestExpectation()
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let r1 = SQUiabv.fetchRequest()
        do {
            let re = try moc.fetch(r1)
            for a1 in re {
                print (a1.id)
                print (a1.cnameGB)
            }
            print (re.count)
            test.fulfill()
        }catch{
            fatalError("\(error)")
        }
        wait(for: [test], timeout: 5.0)
    }
    
    // insert
    func test02b() throws {
        let test = XCTestExpectation()
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let r1 = SQUiabv(context: moc)
            r1.book = "test"
            r1.cname = "的"
            r1.cnameGB = "的的"
            // try moc.save() // 這個資料庫是真的要用的，不要亂插資料
            test.fulfill()
        }catch{
            fatalError("\(error)")
        }
        wait(for: [test], timeout: 5.0)
    }
    func test02c() throws {
        let test = XCTestExpectation()
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let r1 = SQUiabv.fetchRequest()
        do {
            var re = try moc.fetch(r1)
            
            for a1 in re {
                a1.cnameGB = "的的的"
            }
            try moc.save()
            test.fulfill()
        }catch{
            fatalError("\(error)")
        }
        wait(for: [test], timeout: 5.0)
    }
    func test02d() throws {
        let test = XCTestExpectation()
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let r1 = SQUiabv.fetchRequest()
        do {
            var re = try moc.fetch(r1)
            
            for a1 in re {
                if a1.book == "test" {
                    moc.delete(a1)
                }
            }
            try moc.save()
            test.fulfill()
        }catch{
            fatalError("\(error)")
        }
        wait(for: [test], timeout: 5.0)
    }
}
