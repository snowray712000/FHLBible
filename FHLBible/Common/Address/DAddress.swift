//
//  DAddress.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/9.
//

import Foundation

open class DAddress {

    init (_ book:Int = 0, _ chap: Int = 0 , _ verse: Int = 0,_ ver: String? = nil){
        self.book = book
        self.chap = chap
        self.verse = verse
        self.ver = ver
    }
    internal init(book: Int = 0, chap: Int = 0, verse: Int = 0, ver: String? = nil) {
        self.book = book
        self.chap = chap
        self.verse = verse
        self.ver = ver
    }
    
    public var book = 0
    public var chap = 0
    public var verse = 0
    public var ver: String?
    
    public func toString(_ tp: BookNameLang)->String{
        if ( book < 1 || book > 66){
            return "\(book) \(chap):\(verse)"
        }
        
        let na = BibleBookNames.getBookName(book, tp)
        
        return "\(na) \(chap):\(verse)"
    }

}

/// 當要用 Set<DAddress> 時會用到
extension DAddress : Hashable {
    /// Type 'DAddress' does not conform to protocol 'Hashable'
    public func hash(into hasher: inout Hasher) {
        hasher.combine(book)
        hasher.combine(chap)
        hasher.combine(verse)
    }
}
/// 呼叫排序時 .sort （＜）　或　.sort（＞） r2.sort(by:＜)
extension DAddress : Equatable, Comparable {
    public static func < (lhs: DAddress, rhs: DAddress) -> Bool {
        if lhs.book < rhs.book { return true }
        if lhs.chap < rhs.chap { return true }
        if lhs.verse < rhs.verse { return true }
        return false
    }
    public static func == (lhs: DAddress, rhs: DAddress) -> Bool {
        return lhs.book == rhs.book && lhs.chap == rhs.chap && lhs.verse == rhs.verse
    }
}
/// 直接呼叫 .distinct() 但沒有排序
extension Sequence where Iterator.Element: Hashable {
    func distinct() -> [Iterator.Element] {
        var r1: Set<Iterator.Element> = []
        return filter { r1.insert($0).inserted }
    }
}
extension Array where Element: Hashable{
    func ijnToSet()->Set<Element>{
        var r1: Set<Element> = Set()
        self.forEach({r1.insert($0)})
        return r1
    }
}
extension Set where Element: Hashable {
    mutating func ijnAppend(contentsOf: [Element]){
        contentsOf.forEach({self.insert($0)})
    }
}

extension DAddress {
    /// 產生整章 DAddress, 用 book, chap 參教
    func generateEntireThisChap()->[DAddress] {
        let r1 = BibleVerseCount.getVerseCount(self.book, self.chap)
        return ijnRange(1, r1).map({DAddress(book: self.book, chap: self.chap, verse: $0, ver: self.ver)})
    }
}
