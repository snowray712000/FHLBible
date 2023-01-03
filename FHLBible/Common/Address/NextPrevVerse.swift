//
//  NextPrevVerse.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/11.
//

import Foundation

extension DAddress {
    /// 若到最後一節，會自動切換為下一個 book
    /// 若到啟示錄最後一節，會自動切換為 創 1 1 1
    func goNextVerse()->DAddress{
        return NextPrevVerse().goNext(self)
    }
    /// 若到第1章，第1節，會自動切換為上一個 book，而不會到 0 章 0 節
    /// 若是創世記，則會切換到啟示錄
    func goPrevVerse()->DAddress{
        return NextPrevVerse().goPrev(self)
    }
}
class NextPrevVerse {
    func goNext(_ addr:DAddress)->DAddress {
        let cnt = BibleVerseCount.getVerseCount(addr.book, addr.chap)
        if addr.verse != cnt {
            return DAddress(addr.book,addr.chap,addr.verse + 1, addr.ver)
        } else {
            let cntChap = BibleChapCount.getChapCount(addr.book)
            if addr.chap != cntChap {
                return DAddress(addr.book,addr.chap+1,1,addr.ver)
            } else {
                if addr.book != 66 {
                    return DAddress(addr.book+1,1,1,addr.ver)
                } else {
                    return DAddress(1,1,1,addr.ver)
                }
            }
        }
    }
    func goPrev(_ addr:DAddress)->DAddress {
        let bk = addr.book
        let ch = addr.chap
        let vs = addr.verse
        let ver = addr.ver
        
        if vs != 1 {
            return DAddress(bk,ch,vs-1,ver)
        } else {
            if ch != 1{
                let cnt = BibleVerseCount.getVerseCount(bk, ch - 1)
                return DAddress(bk,ch-1,cnt,ver)
            } else {
                if bk != 1 {
                    let cntCh = BibleChapCount.getChapCount(bk-1)
                    let cntV = BibleVerseCount.getVerseCount(bk-1, cntCh)
                    return DAddress(bk-1,cntCh,cntV)
                } else {
                    let cntCh = BibleChapCount.getChapCount(66)
                    let cntV = BibleVerseCount.getVerseCount(66, cntCh)
                    return  DAddress(66,cntCh,cntV)
                }
            }
        }
    }
    
}
