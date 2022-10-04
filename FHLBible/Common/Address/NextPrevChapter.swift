//
//  NextPrevChapter.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/9.
//

import Foundation

extension VerseRange {
    func goNext()->VerseRange {
        return VerseRangeGoNextChap().goNext(self)
    }
    func goPrev()->VerseRange {
        return VerseRangeGoNextChap().goPrev(self)
    }
}
extension DAddress {
    func goNextChap()->[DAddress]{
        return VerseRangeGoNextChap().goNext(VerseRange([self])).verses
    }
    func goPrevChap()->[DAddress]{
        return VerseRangeGoNextChap().goPrev(VerseRange([self])).verses
    }
}

/// 按 goNext 按鈕時，要用到的
/// 可以直接用 VerseRange.goNext 與 .goPrev
class VerseRangeGoNextChap: NSObject {
    func goPrev(_ a:VerseRange)->VerseRange {
        if a.verses.count == 0 { return vDefault }
        
        let re = VerseRange()
        let r1 = a.verses.first!
        
        let bk = r1.book
        let ch = r1.chap
        if ch == 1 {
            // 換書卷
            if bk == 1 {
                re.verses = gChap(66, BibleChapCount.getChapCount(66))
            } else {
                re.verses = gChap(bk-1, BibleChapCount.getChapCount(bk-1))
            }
        } else {
            re.verses = gChap(bk, ch-1)
        }
        return re
    }
    func goNext(_ a:VerseRange)->VerseRange {
        if a.verses.count == 0 { return vDefault }
        
        let re = VerseRange()
        let r1 = a.verses.first!
        
        let bk = r1.book
        let ch = r1.chap
        let cntThisBk = BibleChapCount.getChapCount(bk)
        if ch != cntThisBk {
            re.verses = gChap(bk, ch+1)
        } else {
            // 換書卷
            if bk == 66 {
                re.verses = gChap(1, 1)
            } else {
                re.verses = gChap(bk+1, 1)
            }
        }
        return re
    }
    fileprivate func gChap(_ bk:Int, _ ch: Int) -> [DAddress] {
        return DAddress(book: bk, chap: ch, verse: 1, ver: nil).generateEntireThisChap()
    }
    fileprivate var vDefault: VerseRange {
        get {
            let re = VerseRange()
            re.verses = [DAddress(book: 1, chap: 1, verse: 1, ver: nil)]
            return re
        }
    }
}
