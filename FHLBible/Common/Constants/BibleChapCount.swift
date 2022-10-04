//
//  BibleChapCount.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/6/12.
//

import Foundation

/// 取得下一章，需要這個資訊
open class BibleChapCount {
    static private let cnum = [50, 40, 27, 36, 34, 24, 21, 4, 31, 24, 22, 25, 29, 36, 10, 13, 10, 42, 150, 31, 12, 8, 66, 52, 5, 48, 12, 14, 3, 9, 1, 4, 7, 3, 3, 3, 2, 14, 4, 28, 16, 24, 21, 28, 16, 16, 13, 6, 6, 4, 4, 5, 3, 6, 4, 3, 1, 13, 5, 5, 3, 5, 1, 1, 1, 22];
    
    /// 情境需求: 現在是"創2"，要取得下一章，是什麼。
    /// - Parameter book1based: 1是創世記、66是啟示錄
    /// - Returns: 得到「章數」，例如創世記 50。
    static public func getChapCount(_ book1based: Int)-> Int {
      if (book1based >= 1 && book1based <= 66) {
        return cnum[book1based - 1];
      }
        let msg = "Error Book id, must 1~66" + "you pass " + book1based.description
        debugPrint(msg)
        abort()
    }
    
    /// 情境需求: 選經文時，若只有1章，就不用再選「章」，直接進入
    static public func getChapCountEqual1BookIds() -> [Int]{
        if bookIdsOnlyOneChap == nil {
            var r1: [(id:Int,cnt:Int)] = []
            for i in 0..<cnum.count {
                r1.append((id:i+1,cnt:cnum[i])) // 1based
            }
            bookIdsOnlyOneChap = r1.filter({$0.cnt == 1}).map({$0.id})
        }
        return bookIdsOnlyOneChap!
    }
    static private var bookIdsOnlyOneChap: [Int]?
}
