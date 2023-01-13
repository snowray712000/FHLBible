//
//  SQLSelectBibleTextGenerator.swift
//  FHLBible
//
//  Created by littlesnow on 2022/10/21.
//

import Foundation
class SQLSelectBibleTextGenerator {
    func main(addresses addrs:[DAddress],
              nameOfTable unv2:String,
              isOrderbyId isOrder:Bool=false)->String{
        let strSelectWhere = "select * from \(unv2) where ";
        
        let byBook = from(addrs).groupBy({$0.book}).orderBy({$0.key})
        
        // (book=40 xxxxx)
        // (book=39 xxxxx) or (book=40 xxxxx)
        let strWhere = byBook.select({self.gOneBook($0.key, $0.values.toArray())}).joined(separator: " or ")
        
        let strOrderById = isOrder ? " order by id" : ""
        return strSelectWhere + strWhere + strOrderById + ";"
    }
    // g: generate
    func gOneBook(_ book:Int,_ addrs:[DAddress])->String{
        // (book=40 and (...))
        // (chap=1 xxxxx)
        // (chap=1 xxxx) or (chap=2 xxxx)
        
        let byChap = from(addrs).groupBy({$0.chap}).orderBy({$0.key})
        let str2 = byChap.select({self.gOneChap(book,$0.key, $0.values.toArray())}).joined(separator: " or ")
        return "(book=\(book) and (\(str2)))"
    }
    func gOneChap(_ book:Int,_ chap: Int,_ addrs:[DAddress])->String{
        // (chap=1 and (...))
        // sec=1
        // sec=1 or sec=3 or (sec>=6 and sec<=9)
        
        let byContinuedSec = self.groupVerses(from(addrs).orderBy({$0.verse}).toArray())
        let r1 = from(byContinuedSec).select({self.gContinuedSec($0)}).joined(separator: " or ")
        let r2 = "(chap=\(chap) and (\(r1)))"
        return r2
    }
    func gContinuedSec(_ addrs:[DAddress])->String{
        // 以下為例子，就是呼叫了3次這個函式。
        // (sec>=1 and sec<=5) or sec=9 or sec=11
        // 分別 output 為 (sec>=1 and sec<=5)、sec=9、sec=11
        if addrs.count == 1 {
            let r1 = addrs[0].verse
            return "sec=\(r1)"
        } else {
            let r1 = addrs[0].verse
            let r2 = addrs[1].verse
            return "(sec>=\(r1) and sec<=\(r2))"
        }
    }
    func groupVerses(_ addrs: [DAddress])->[[DAddress]]{
    //func groupVerses(Addresses addrs:[DAddress])->[[DAddress]]{
        // assert book chap the same, and order by verse
        // assert addrs.count() > 0
        let one = addrs[0]
        let book = one.book
        let chap = one.chap
        
        var re: [[DAddress]] = []
        if addrs.count == 1 {
            return [addrs] // 若不提早 return  1...cnt 那邊會 error
        }
        
        var r1 = one.verse
        var r2 = r1
        
        let fn1 : ()->Void = {
            if r1 == r2 {
                re.append([DAddress(book,chap,r1)])
            } else {
                re.append([
                    DAddress(book,chap,r1),
                    DAddress(book,chap,r2)
                ])
            }
        }
        
        let cntAddresses = addrs.count
        for i in 1..<cntAddresses {
            let r3 = addrs[i].verse
            if r3 == r2 + 1 {
                r2 = r3
            } else {
                fn1()
                
                r1 = r3
                r2 = r3
            }
        }
        fn1()
        return re
    }
}
