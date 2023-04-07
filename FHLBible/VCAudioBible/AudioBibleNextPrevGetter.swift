//
//  AudioBibleNextPrevGetter.swift
//  FHLBible
//
//  Created by littlesnow on 2023/4/7.
//

import Foundation

// 前提假設: 傳入的 book chap version 是存在的
class AudioBibleNextPrevGetter {
    init(){}
    var evNext = IjnEventOnceAny()
    var evPrev = IjnEventOnceAny()
    var versionIdx = 5
    var book = 40
    var chap = 1
    var mp3:String?
    var bookNext = 40
    var chapNext = 1
    var bookPrev = 40
    var chapPrev = 1
    var mp3Next:String? // 算上面的時候，順便算出來的
    var mp3Prev:String?
    var loopMode:VCAudioBible.LoopMode = .All
    
    // isFindNext, 按下 next 時，只需重找 next prev 不需要
    // mp3 是要供 copy 用的
    func mainAsync(book:Int,chap:Int,versionIndex:Int,loopMode:VCAudioBible.LoopMode,mp3:String,isFindNext:Bool,isFindPrev:Bool){
        self.book = book
        self.chap = chap
        self.versionIdx = versionIndex
        self.loopMode = loopMode
        self.mp3 = mp3
        
        if isFindNext {
            getValidNext()
        } else {
            self.evNext.triggerAndCleanCallback(nil, nil) // 沒用，把它 clean 乾淨
        }
        if isFindPrev {
            getValidPrev()
        } else {
            self.evPrev.triggerAndCleanCallback(nil, nil)
        }
    }
    // callback, 因為已經取得 mp3 uri 了，雖然本意是要判斷 Bool，但還是同時把 DAddress 與 mp3 回傳
    // DAddress(book,chap,1) mp3=""
    private func fhlAu2(_ versionIdx:Int,_ book: Int,_ chap:Int, completion: @escaping (Bool,DAddress,String) -> Void){
        fhlAu("version=\(versionIdx)&bid=\(book)&chap=\(chap)", { re1 in
            if let mp3uri = re1.mp3 {
                checkIfUrlExists(at: URL(string: mp3uri)!, completion: { re2 in
                    completion(re2,DAddress(book,chap,1),mp3uri)
                })
            } else {
                completion(false,DAddress(book,chap,1),"")
            }
        })
    }
    // fnNextTry 定出來，就可以是用在 find next 或 find prev 了
    // 遞迴的處理，會不會太多層？先試再說
    // 使用 fhlAu3Next 或 fhlAu3Prev ， 不要用這個
    private func fhlAu3(_ versionIdx:Int,_ book:Int,_ chap:Int,_ fnNextTry: @escaping (DAddress) -> DAddress, completion: @escaping (DAddress,String) -> Void){
        func fn1(isValid:Bool,addr1:DAddress,mp3uri:String)->Void{
            if isValid {
                completion(addr1,mp3uri)
            } else {
                let addr2 = fnNextTry(addr1)
                fhlAu2(versionIdx, addr2.book, addr2.chap, completion: fn1)
            }
        }
        fhlAu2(versionIdx, book, chap, completion: fn1)
    }
    private func fhlAu3Next(_ versionIdx:Int,_ book:Int,_ chap:Int,completion: @escaping (DAddress,String) -> Void){
        // 會呼叫 goNext 已經確定 book chap 目前是失敗的
        // 不需要每個 chap 都測，直接測卷
        func goNext(addr:DAddress)->DAddress {
            if addr.book == 66{
                return DAddress(1,1,1)
            }
            if addr.book == 40{
                return DAddress(1,1,1) // 假設，只能讀舊約
            }
            return DAddress(addr.book+1,1,1)
        }
        fhlAu3(versionIdx, book, chap, goNext, completion: completion)
    }
    private func fhlAu3Prev(_ versionIdx:Int,_ book:Int,_ chap:Int,completion: @escaping (DAddress,String) -> Void){
        // 會呼叫 goPrev 已經確定 book chap 目前是失敗的
        // 不需要每個 chap 都測，直接測卷
        func goPrev(addr:DAddress)->DAddress {
            print("prev \(addr.book)")
            if addr.book == 1{
                return DAddress(66,1,1)
            }
            if addr.book == 39{ // 假設只能讀新約，假設沒有只讀其中幾卷的
                return DAddress(66,1,1)
            }
            return DAddress(addr.book-1,1,1)
        }
        fhlAu3(versionIdx, book, chap, goPrev, completion: completion)
    }
    // update bookNext chapNext mp3Next
    private func getValidNext(){
        func getmp3AndTriggerNextAsync(_ idx:Int,_ book:Int,_ chap:Int){
            fhlAu2(idx, book, chap) { isValid, addrValid, mp3Valid in
                assert( isValid )
                self.mp3Next = mp3Valid
                triggerNext()
            }
        }
        func triggerNext(){
            self.evNext.triggerAndCleanCallback(self, nil)
        }
        
        if self.loopMode == .Chap {
            bookNext = book
            chapNext = chap
            self.mp3Next = self.mp3
            
            triggerNext()
            return
        }
        if self.loopMode == .Book {
            let re = BibleGetNextOrPrevChap.getNextChap(DAddress(book,chap,1))
            bookNext = book
            if re == nil || re!.verses[0].book != book {
                chapNext = 1
            } else {
                chapNext = chap + 1
            }
            
            getmp3AndTriggerNextAsync(versionIdx,bookNext,chapNext)
            
            return
        }
        assert ( self.loopMode == .All)
        
        let re = BibleGetNextOrPrevChap.getNextChap(DAddress(book,chap,1))
        let bookNextTry = re == nil ? 1 : re!.verses[0].book
        if bookNextTry == book {
            // 單純，還是同卷書
            bookNext = book
            chapNext = chap + 1
            getmp3AndTriggerNextAsync(versionIdx,bookNext,chapNext)
            return
        }
        
        // 不同卷書，下卷書 bookNextTry 是否仍然在 versionIdx 是有效的？
        fhlAu3Next(versionIdx, bookNextTry, 1) { addrValid, mp3Valid in
            self.bookNext = addrValid.book
            self.chapNext = addrValid.chap
            self.mp3Next = mp3Valid
            triggerNext()
            return
        }
    }
    // 參考 getValidNext
    private func getValidPrev(){
        func getmp3AndTriggerPrevAsync(_ idx:Int,_ book:Int,_ chap:Int){
            fhlAu2(idx, book, chap) { isValid, addrValid, mp3Valid in
                assert( isValid )
                self.mp3Prev = mp3Valid
                triggerPrev()
            }
        }
        func triggerPrev(){
            self.evPrev.triggerAndCleanCallback(self, nil)
        }
        
        if self.loopMode == .Chap {
            bookPrev = book
            chapPrev = chap
            self.mp3Prev = self.mp3
            triggerPrev()
            return
        }
        if self.loopMode == .Book {
            let re = BibleGetNextOrPrevChap.getPrevChap(DAddress(book,chap,1))
            bookPrev = book
            if re == nil || re!.verses[0].book != book {
                chapPrev = BibleChapCount.getChapCount(book)
            } else {
                chapPrev = chap - 1
            }
            getmp3AndTriggerPrevAsync(versionIdx,bookPrev,chapPrev)
            return
        }
        assert (self.loopMode == .All)
        
        let re = BibleGetNextOrPrevChap.getPrevChap(DAddress(book,chap,1))
        let bookNextTry = re == nil ? 66 : re!.verses[0].book
        if bookNextTry == book {
            // 單純，還是同卷書
            bookPrev = book
            chapPrev = chap - 1
            getmp3AndTriggerPrevAsync(versionIdx,bookPrev,chapPrev)
            return
        }
        
        // 不同卷書，下卷書 bookNextTry 是否仍然在 versionIdx 是有效的？
        fhlAu3Prev(versionIdx, bookNextTry, 1) { addrValid, mp3Valid in
            // 這卷書，有效，但要從這卷書的最後一章，開始，因為這是 prev
            self.bookPrev = addrValid.book
            let chap = BibleChapCount.getChapCount(addrValid.book)
            self.chapPrev = chap
            getmp3AndTriggerPrevAsync(self.versionIdx, self.bookPrev, self.chapPrev)
            return
        }
    
    }
}
