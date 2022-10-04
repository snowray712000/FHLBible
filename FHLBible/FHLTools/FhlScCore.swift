//
//  FhlScCore.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/11.
//

import Foundation

/// 寫完 tsk，再寫 comment 時，有共同處
class FhlScCore {
    /// 正確，錯誤，都會 trigger 這個
    /// 當第1個參數是 nil, 表示正確
    /// 當第1個參數有值, 會包含錯誤訊息的 [DText(w)]
    var apiFinished$: IjnEventOnce<[DText],DApiSc> = IjnEventOnce()
    /// bookId: 3，注釋；4，串珠
    func main(_ addr:DAddress,_ tpBook:TpBook){
        self.addr = addr
        self.tpBook = tpBook
        
        fhlSc(paramsSc) { pData in
            if false == pData.isSuccess() {
                let re = [DText("取得資料失敗,發生於 \(self.addrTitle)")]
                self.trigger(re)
            } else {
                if pData.record.count == 0 {
                    let re = [DText("無資料 \(self.addrTitle)")]
                    self.trigger(re)
                } else {
                    self.trigger(pData)
                }
            }
        }
    }
    enum TpBook: Int {
        case tsk = 4
        case comment = 3
    }
    private func trigger(_ msgEr:[DText]){
        DispatchQueue.main.async {
            self.apiFinished$.triggerAndCleanCallback(msgEr, nil)
        }
    }
    private func trigger(_ data:DApiSc){
        DispatchQueue.main.async {
            self.apiFinished$.triggerAndCleanCallback(nil, data)
        }
    }
    private var addr: DAddress!
    private var tpBook: TpBook!
    private var engs: String { BibleBookNames.getBookName(addr.book, .Matt)}
    private var paramsSc: String {
        "book=\(tpBook.rawValue)&engs=\(engs)&chap=\(addr.chap)&sec=\(addr.verse)&\(ManagerLangSet.s.curQueryParamGb)"
    }
    private var addrTitle: String {
        "\(BibleBookNames.getBookName(addr.book, ManagerLangSet.s.curTpBookNameLang)) \(addr.chap):\(addr.verse)"
    }
}
