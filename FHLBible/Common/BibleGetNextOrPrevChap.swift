//
//  BibleGetNextOrPrevChap.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/6/12.
//

import Foundation

/// 將 getNextChap 與 getPrevChap 這一對包在一個 class
open class BibleGetNextOrPrevChap {
    /// 真正核心是 getNextChap
    /// 這個只是再結合 StringToVerseRange VerseRangeToString
    public static func getNextChapInStr(_ addr:String) -> String? {
        return coreInStr(addr, true)
    }
    /// 真正核心是 getPrevChap
    /// 這個只是再結合 StringToVerseRange VerseRangeToString
    public static func getPrevChapInStr(_ addr:String) -> String? {
        return coreInStr(addr, false)
    }
    private static func coreInStr(_ addr: String,_ isAfter:Bool)->String? {
        let r1 = StringToVerseRange().main(addr)
        if r1.count == 0 { return nil }
        
        let r2 = isAfter ? BibleGetNextOrPrevChap.getNextChap(r1[0]) :  BibleGetNextOrPrevChap.getPrevChap(r1[0])
        
        if r2 == nil { return nil }
        
        return VerseRangeToString().main(r2!.verses, ManagerLangSet.s.curTpBookNameLang)
    }
    /// 使用情境: 讀目前經文，然後「向左滑」，移到「下一章」時。通常目前章節是 [DAddress] 或 VerseRange 型態，傳入 addr[0] 即可
    /// 啟22時，會回傳 nill。
    public static func getNextChap(_ addr: DAddress) -> VerseRange? {
        /// 創50, 就要變出1
        func isBookChanging()->Bool {
            let cntChap = BibleChapCount.getChapCount(addr.book)
            return cntChap == addr.chap
        }
        /// 啟22, 要回傳 nil
        func isReturnNil()->Bool{
            return isBookChanging() && addr.book == 66
        }
        
        func gThisChap(_ b: Int,_ c: Int) -> [DAddress]{
            let cntVerse = BibleVerseCount.getVerseCount(b, c)
            return (1..<cntVerse+1).map({DAddress(book: b, chap: c, verse: $0, ver: nil)})
        }
        
        if isReturnNil() {
            return nil
        }
        
        let re = VerseRange()
        re.verses = isBookChanging() ? gThisChap(addr.book+1, 1) : gThisChap(addr.book, addr.chap+1)
        return re
    }

    /// 使用情境: 參考 getNextChap。創1會回傳 null。
    public static func getPrevChap(_ addr: DAddress) -> VerseRange? {
        /// 出1, 就要變創50
        func isBookChanging()->Bool {
            return 1 == addr.chap
        }
        /// 創1, 要回傳 nil
        func isReturnNil()->Bool{
            return isBookChanging() && addr.book == 1
        }
        
        func gThisChap(_ b: Int,_ c: Int) -> [DAddress]{
            let cntVerse = BibleVerseCount.getVerseCount(b, c)
            return (1..<cntVerse+1).map({DAddress(book: b, chap: c, verse: $0, ver: nil)})
        }
        
        if isReturnNil() {
            return nil
        }
        
        let re = VerseRange()
        re.verses = isBookChanging() ? gThisChap(addr.book-1, BibleChapCount.getChapCount(addr.book-1)) : gThisChap(addr.book, addr.chap-1)
        return re
    }
}
